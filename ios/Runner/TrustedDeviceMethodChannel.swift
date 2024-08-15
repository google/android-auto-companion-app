// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AndroidAutoConnectedDeviceManager
import AndroidAutoLogger
import CoreBluetooth
import Flutter
import LocalAuthentication

/// The possible errors that can result from a phone-initiated enrollment in trusted device.
private enum TrustedDeviceEnrollmentError: Int {
  case unknown = 0
  case carNotConnected = 1
  case passcodeNotSet = 2
}

/// This is the class used to setup Flutter method channel, handle and invoke any methods from and
/// to Flutter app.
@available(iOS 10.0, *)
public class TrustedDeviceMethodChannel: TrustedDeviceModel {

  private static let unlockNotificationIdentifier = "trusted-device-unlock-succeed"
  private static let enrollmentNotificationIdentifier = "trusted-device-enrollment-succeed"
  private static let unenrollmentNotificationIdentifier = "trusted-device-unenrollment"

  /// The prefix that can be combined with a car id to form a key within `UserDefaults` that
  /// stores whether a notification should be shown for a particular car when it is unlocked.
  private static let showUnlockNotificationPrefixKey = "showUnlockNotificationKey"

  private let connectedDeviceMethodChannel: FlutterMethodChannel
  private let trustedDeviceMethodChannel: FlutterMethodChannel
  private let flutterViewController: FlutterViewController

  private let storage = UserDefaults.standard

  /// Whether log file sharing is supported.
  ///
  /// The implementation depends on the share sheet which is supported in iOS 13+.
  private var isLogSharingSupported: Bool {
    if #available(iOS 13, *) {
      return true
    } else {
      return false
    }
  }

  /// The most recently received unlock status for a car
  private enum UnlockStatus: Int {
    /// The status is not known
    case unknown = 0

    /// The unlock is in progress
    case inProgress = 1

    /// The unlock was successful
    case success = 2

    /// An error was encountered during the unlock process
    case error = 3
  }

  /// The possible states that a car can be in.
  private enum CarConnectionStatus: Int {
    /// A car that is associated has been detected and connection is being established.
    case detected = 0

    /// A secure communication channel has been established with an associated car.
    case connected = 1

    /// An associated car has been disconnected.
    case disconnected = 2
  }

  public init(_ controller: FlutterViewController) {
    flutterViewController = controller
    connectedDeviceMethodChannel = FlutterMethodChannel(
      name: ConnectedDeviceConstants.channel,
      binaryMessenger: controller.binaryMessenger)
    trustedDeviceMethodChannel = FlutterMethodChannel(
      name: TrustedDeviceConstants.channel,
      binaryMessenger: controller.binaryMessenger)

    super.init()

    setUpTrustedDeviceCallHandler()
    setUpConnectedDeviceCallHandler()
  }

  private func setUpTrustedDeviceCallHandler() {
    trustedDeviceMethodChannel.setMethodCallHandler(handle)
  }

  nonisolated private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task { @MainActor [weak self] in
      switch call.method {
      case TrustedDeviceConstants.openSecuritySettings:
        self?.openSettings()

      case TrustedDeviceConstants.enrollTrustAgent:
        self?.invokeEnrollForTrustAgent(methodCall: call)

      case TrustedDeviceConstants.stopTrustAgentEnrollment:
        self?.invokeStopEnrollment(methodCall: call)

      case TrustedDeviceConstants.getUnlockHistory:
        self?.invokeRetrieveUnlockHistory(methodCall: call, result: result)

      case TrustedDeviceConstants.isTrustedDeviceEnrolled:
        self?.invokeIsTrustedDeviceEnrolled(methodCall: call, result: result)

      case TrustedDeviceConstants.isDeviceUnlockRequired:
        self?.invokeIsDeviceUnlockRequired(methodCall: call, result: result)

      case TrustedDeviceConstants.setDeviceUnlockRequired:
        self?.invokeSetDeviceUnlockRequired(methodCall: call)

      case TrustedDeviceConstants.shouldShowUnlockNotification:
        self?.invokeShouldShowUnlockNotification(methodCall: call, result: result)

      case TrustedDeviceConstants.setShowUnlockNotification:
        self?.invokeSetShowUnlockNotification(methodCall: call)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setUpConnectedDeviceCallHandler() {
    connectedDeviceMethodChannel.setMethodCallHandler { [weak self] (call, result) in
      Task { @MainActor [weak self] in
        guard let self else { return }
        
        switch call.method {
        case ConnectedDeviceConstants.isBluetoothEnabled:
          result(self.connectionManager.state.isPoweredOn)
          
        case ConnectedDeviceConstants.isBluetoothPermissionGranted:
          self.invokeIsBluetoothPermissionGranted(result: result)
          
        case ConnectedDeviceConstants.scanForCarsToAssociate:
          self.scanForCarsToAssociate(methodCall: call)
          
        case ConnectedDeviceConstants.openApplicationDetailsSettings:
          self.openSettings()
          
        case ConnectedDeviceConstants.openBluetoothSettings:
          self.openSettings()
          
        case ConnectedDeviceConstants.associateCar:
          self.invokeAssociateCar(methodCall: call)
          
        case ConnectedDeviceConstants.getAssociatedCars:
          self.invokeRetrieveAssociatedCars(methodCall: call, result: result)
          
        case ConnectedDeviceConstants.getConnectedCars:
          self.invokeRetrieveConnectedCars(methodCall: call, result: result)
          
        case ConnectedDeviceConstants.connectToAssociatedCars:
          self.connectionManager.connectToAssociatedCars()
          
        case ConnectedDeviceConstants.clearCurrentAssociation:
          self.connectionManager.clearCurrentAssociation()
          
        case ConnectedDeviceConstants.clearAssociation:
          self.invokeClearAssociation(methodCall: call, result: result)
          
        case ConnectedDeviceConstants.renameCar:
          self.invokeRenameCar(methodCall: call, result: result)
          
        case ConnectedDeviceConstants.isCarConnected:
          self.invokeIsConnected(methodCall: call, result: result)
          
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  override public func onStateChange(state: any RadioState) {
    invokeFlutterMethod(
      ConnectedDeviceConstants.onStateChanged,
      arguments: [
        ConnectedDeviceConstants.connectionManagerStateKey: state.toBluetoothState()
      ],
      methodChannel: connectedDeviceMethodChannel
    )
  }

  override public func onConnection(car: Car) {
    var arguments = car.toDictionary()
    arguments[ConnectedDeviceConstants.carConnectionStatusKey] =
      String(CarConnectionStatus.detected.rawValue)

    invokeFlutterMethod(
      ConnectedDeviceConstants.onCarConnectionStatusChange,
      arguments: arguments,
      methodChannel: connectedDeviceMethodChannel
    )
  }

  override public func onSecureChannelSetup(car: Car) {
    var arguments = car.toDictionary()
    arguments[ConnectedDeviceConstants.carConnectionStatusKey] =
      String(CarConnectionStatus.connected.rawValue)

    invokeFlutterMethod(
      ConnectedDeviceConstants.onCarConnectionStatusChange,
      arguments: arguments,
      methodChannel: connectedDeviceMethodChannel
    )
  }

  override public func onDisconnection(car: Car) {
    var arguments = car.toDictionary()
    arguments[ConnectedDeviceConstants.carConnectionStatusKey] =
      String(CarConnectionStatus.disconnected.rawValue)

    invokeFlutterMethod(
      ConnectedDeviceConstants.onCarConnectionStatusChange,
      arguments: arguments,
      methodChannel: connectedDeviceMethodChannel
    )
  }

  func invokeFlutterMethod(
    _ methodName: String,
    arguments: [String: String]? = nil,
    methodChannel: FlutterMethodChannel
  ) {
    methodChannel.invokeMethod(methodName, arguments: arguments) { result in
      if let error = result as? FlutterError {
        self.log.error(
          """
          invokeMethod failed for method `\(methodName)`
          with error: \(error.message ?? "no error message")
          """
        )
      } else if FlutterMethodNotImplemented.isEqual(result) {
        self.log.error("method `\(methodName)` not implemented")
      } else {
        self.log.debug("Invocation of method `\(methodName)` is successful.")
      }
    }
  }

  private func scanForCarsToAssociate(methodCall: FlutterMethodCall) {
    discoveredCars = [:]

    let namePrefix = methodCall.arguments as? String ?? ""
    connectionManager.scanForCarsToAssociate(namePrefix: namePrefix)
  }

  /// Attempts to open the settings page.
  private func openSettings() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(settingsUrl)
    }
  }

  private func invokeAssociateCar(methodCall: FlutterMethodCall) {
    guard connectionManager.state.isPoweredOn else {
      log.error("Associate car method invoked when BLE adapter is not on. Ignoring.")
      return
    }

    guard let uuid = methodCall.arguments as? String else {
      log.error("Associate car method invoked with nil uuid. Ignoring.")
      return
    }

    guard let carToAssociate = discoveredCars[uuid] else {
      log.error(
        "Call to associate a car with UUID \(uuid), but no cars with that UUID found. Ignoring.")
      return
    }

    log.debug("Call to associate car with UUID \(uuid)")

    do {
      try connectionManager.associate(carToAssociate)
    } catch {
      log.error("Association was unsuccessful: \(error.localizedDescription)")
    }
  }

  private func invokeRetrieveConnectedCars(methodCall: FlutterMethodCall, result: FlutterResult) {
    result(connectionManager.securedChannels.map { $0.car.toDictionary() })
  }

  private func invokeRetrieveAssociatedCars(methodCall: FlutterMethodCall, result: FlutterResult) {
    result(connectionManager.associatedCars.map { $0.toDictionary() })
  }

  private func invokeClearAssociation(methodCall: FlutterMethodCall, result: FlutterResult)  {
    guard let carId = methodCall.arguments as? String else {
      log.error("clearAssociation method invoked with invalid carId. Ignoring.")
      return
    }
    clearConfig(forCarId: carId)
    connectionManager.clearAssociation(for: Car(id: carId, name: nil))
    result(nil)
  }

  private func invokeEnrollForTrustAgent(methodCall: FlutterMethodCall) {
    guard let car = methodCall.argumentsToCar() else {
      log.error("Trust agent enrollment called with invalid car. Ignoring.")
      return
    }

    do {
      try trustAgentManager.enroll(car)
    } catch {
      log.error("Encountered error during enrollment: \(error.localizedDescription)")

      // Should never be something other than a `TrustAgentManagerError`.
      if let enrollmentError = error as? TrustAgentManagerError {
        handleEnrollingError(enrollmentError, for: car)
      }
    }
  }

  private func invokeRetrieveUnlockHistory(methodCall: FlutterMethodCall, result: FlutterResult) {
    guard let car = methodCall.argumentsToCar() else {
      log.error("getUnlockHistory method invoked with invalid car. Ignoring.")
      return
    }

    let unlockHistory = trustAgentManager.unlockHistory(for: car)
    let dateFormatter = ISO8601DateFormatter()

    result(unlockHistory.map { dateFormatter.string(from: $0) })
  }

  private func invokeRenameCar(methodCall: FlutterMethodCall, result: FlutterResult) {
    guard let carMap = methodCall.arguments as? [String: String],
      let carId = carMap[ConnectedDeviceConstants.carIdKey],
      let name = carMap[ConnectedDeviceConstants.carNameKey]
    else {
      log.error("renameCar method invoked with invalid id or name. Ignoring.")
      return
    }

    result(connectionManager.renameCar(withId: carId, to: name))
  }

  private func invokeIsTrustedDeviceEnrolled(methodCall: FlutterMethodCall, result: FlutterResult) {
    guard let car = methodCall.argumentsToCar()
    else {
      log.error("isTrustedDeviceEnrolled method invoked with invalid id or name. Ignoring.")
      return
    }

    result(trustAgentManager.isEnrolled(with: car))
  }

  private func invokeIsBluetoothPermissionGranted(result: FlutterResult) {
    if #available(iOS 13.0, *) {
      result(CBCentralManager().authorization == .allowedAlways)
    } else {
      // Bluetooth permissions are not required before iOS 13.
      result(true)
    }
  }

  private func invokeIsConnected(methodCall: FlutterMethodCall, result: FlutterResult) {
    guard let car = methodCall.argumentsToCar() else {
      log.error("isConnected method invoked with invalid car. Ignoring.")
      return
    }
    result(isCarConnectedSecurely(car))
  }

  private func invokeStopEnrollment(methodCall: FlutterMethodCall) {
    guard let car = methodCall.argumentsToCar() else {
      log.error("Trust agent stop enrollment called with invalid car. Ignoring.")
      return
    }
    trustAgentManager.stopEnrollment(for: car)
  }

  private func invokeIsDeviceUnlockRequired(methodCall: FlutterMethodCall, result: FlutterResult) {
    guard let car = methodCall.argumentsToCar() else {
      log.error("IsDeviceUnlockRequired called with invalid car. Ignoring.")
      return
    }
    result(trustAgentManager.isDeviceUnlockRequired(for: car))
  }

  private func invokeSetDeviceUnlockRequired(methodCall: FlutterMethodCall) {
    guard let car = methodCall.argumentsToCar(),
      let arguments = methodCall.arguments as? [String: String],
      let isRequired = arguments[TrustedDeviceConstants.isDeviceUnlockRequiredKey]
    else {
      log.error("setDeviceUnlockRequired method invoked with invalid arguments. Ignoring.")
      return
    }
    trustAgentManager.setDeviceUnlockRequired((isRequired as NSString).boolValue, for: car)
  }

  private func invokeShouldShowUnlockNotification(
    methodCall: FlutterMethodCall, result: FlutterResult
  ) {
    guard let car = methodCall.argumentsToCar() else {
      log.error("showUnlockNotification called with invalid car. Ignoring.")
      return
    }
    result(shouldShowUnlockNotification(for: car))
  }

  private func invokeSetShowUnlockNotification(methodCall: FlutterMethodCall) {
    guard let car = methodCall.argumentsToCar(),
      let arguments = methodCall.arguments as? [String: String],
      let shouldShow = arguments[TrustedDeviceConstants.shouldShowUnlockNotificationKey]
    else {
      log.error("setShowUnlockNotification method invoked with invalid arguments. Ignoring.")
      return
    }
    let shouldShowBoolValue = (shouldShow as NSString).boolValue

    if shouldShowBoolValue {
      showNotificationPermissionDialogIfNeeded()
    }
    setShowUnlockNotification(shouldShowBoolValue, for: car)
  }

  /// Return whether the given car should show a notification when its unlocked.
  private func shouldShowUnlockNotification(for car: Car) -> Bool {
    let key = Self.notificationKey(forCarId: car.id)

    // By default, the notification should be shown unless the user has explicitly overridden it.
    return storage.containsKey(key)
      ? storage.bool(forKey: key)
      : true
  }

  /// Stores in lcoal storage whether the given car should show a notification when it's unlocked.
  private func setShowUnlockNotification(_ shouldShow: Bool, for car: Car) {
    storage.set(shouldShow, forKey: Self.notificationKey(forCarId: car.id))
  }

  /// Clears any stored configuration data for the given car.
  private func clearConfig(forCarId carId: String) {
    storage.removeObject(forKey: Self.notificationKey(forCarId: carId))
  }

  private static func notificationKey(forCarId carId: String) -> String {
    return "\(showUnlockNotificationPrefixKey).\(carId)"
  }

  /// Pop up the system notification permission dialog.
  /// The dialog will not be shown if the permission has been denied before.
  private func requestNotificationPermission() {
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge]) {
        granted, error in
        self.log.debug("Notification permission granted: \(granted)")
        if let error = error {
          self.log.error("Error asking for notification permission: \(error.localizedDescription)")
        }
      }
  }

  private func showNotificationPermissionDialogIfNeeded() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      switch settings.authorizationStatus {
      case .denied:
        self.showNotificationExplanationDialog(isDenied: true)
      case .notDetermined:
        self.showNotificationExplanationDialog(isDenied: false)
      default:
        self.log.debug(
          "The notification permission status is \(settings.authorizationStatus.rawValue)")
      }
    }
  }

  private func showNotificationExplanationDialog(isDenied: Bool) {
    let alert = UIAlertController(
      title: NSString.localizedUserNotificationString(
        forKey: "notificationPermissionDialogTitle", arguments: nil),
      message: NSString.localizedUserNotificationString(
        forKey: "notificationPermissionDialogText", arguments: nil),
      preferredStyle: .alert)
    alert.addAction(makeAlertAction(forLocalizedKey: "notNowButtonLabel"))

    if isDenied {
      alert.addAction(
        makeAlertAction(
          forLocalizedKey: "settingsButtonLabel",
          handler: { _ in
            self.openSettings()
          }))
    } else {
      alert.addAction(
        makeAlertAction(
          forLocalizedKey: "okButtonLabel",
          handler: { _ in
            self.requestNotificationPermission()
          }))
    }

    DispatchQueue.main.async {
      self.flutterViewController.present(alert, animated: true)
    }
  }

  private func makeAlertAction(
    forLocalizedKey key: String, handler: ((UIAlertAction) -> Void)? = nil
  ) -> UIAlertAction {
    return UIAlertAction(
      title: NSString.localizedUserNotificationString(forKey: key, arguments: nil),
      style: .default,
      handler: handler)

  }

  private func pushUnlockNotification(for car: Car) {
    let defaultCarName = NSString.localizedUserNotificationString(
      forKey: "defaultCarName", arguments: nil)
    let notificationBody = NSString.localizedUserNotificationString(
      forKey: "unlockNotificationContent", arguments: [car.name ?? defaultCarName])
    showNotification(
      body: notificationBody, identifier: TrustedDeviceMethodChannel.unlockNotificationIdentifier)
  }

  private func pushEnrollmentCompletedNotification(for car: Car) {
    let defaultCarName = NSString.localizedUserNotificationString(
      forKey: "defaultCarName", arguments: nil)
    let notificationTitle = NSString.localizedUserNotificationString(
      forKey: "enrollmentNotificationTitle", arguments: nil)
    let notificationBody = NSString.localizedUserNotificationString(
      forKey: "enrollmentNotificationBody", arguments: [car.name ?? defaultCarName])
    showNotification(
      title: notificationTitle, body: notificationBody,
      identifier: TrustedDeviceMethodChannel.enrollmentNotificationIdentifier)
  }

  private func pushUnenrollmentNotification(for car: Car) {
     let defaultCarName = NSString.localizedUserNotificationString(
       forKey: "defaultCarName", arguments: nil)
     let notificationTitle = NSString.localizedUserNotificationString(
       forKey: "unenrollmentNotificationTitle", arguments: nil)
     let notificationBody = NSString.localizedUserNotificationString(
       forKey: "unenrollmentNotificationBody", arguments: [car.name ?? defaultCarName])
     showNotification(
       title: notificationTitle, body: notificationBody,
       identifier: TrustedDeviceMethodChannel.unenrollmentNotificationIdentifier)
   }

  private func showNotification(title: String = "", body: String, identifier: String) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus != .authorized {
        self.log.debug("Notification permission not granted.")
        return
      }
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body

      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      let request = UNNotificationRequest(
        identifier: identifier, content: content, trigger: trigger)

      let center = UNUserNotificationCenter.current()
      center.add(request)
    }
  }

  // MARK: - ConnectionManagerAssociationDelegate Overrides

  public override func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didDiscover car: any AutoPeripheral,
    advertisedName: String?
  ) {
    super.connectionManager(connectionManager, didDiscover: car, advertisedName: advertisedName)

    let name = advertisedName ?? car.name ?? ""

    invokeFlutterMethod(
      ConnectedDeviceConstants.onCarDiscovered,
      arguments: [
        ConnectedDeviceConstants.carNameKey: name,
        ConnectedDeviceConstants.carIdKey: car.identifier.uuidString,
      ],
      methodChannel: connectedDeviceMethodChannel
    )
  }

  public override func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didDisconnect peripheral: any AutoPeripheral
  ) {
    super.connectionManager(connectionManager, didDisconnect: peripheral)

    let name = peripheral.name ?? ""
    invokeFlutterMethod(
      ConnectedDeviceConstants.onCarConnectionStatusChange,
      arguments: [
        ConnectedDeviceConstants.carNameKey: name,
        ConnectedDeviceConstants.carIdKey: peripheral.identifier.uuidString,
        ConnectedDeviceConstants.carConnectionStatusKey:
          String(CarConnectionStatus.connected.rawValue),
      ],
      methodChannel: connectedDeviceMethodChannel
    )
  }

  public override func connectionManager(
    _ connectionManager: AnyConnectionManager,
    requiresDisplayOf pairingCode: String
  ) {
    invokeFlutterMethod(
      ConnectedDeviceConstants.onPairingCodeAvailable,
      arguments: [
        ConnectedDeviceConstants.pairingCodeKey: pairingCode
      ],
      methodChannel: connectedDeviceMethodChannel
    )
  }

  public override func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didCompleteAssociationWithCar car: Car
  ) {
    invokeFlutterMethod(
      ConnectedDeviceConstants.onAssociationCompleted,
      arguments: [
        ConnectedDeviceConstants.carNameKey: car.name ?? "",
        ConnectedDeviceConstants.carIdKey: car.id,
      ],
      methodChannel: connectedDeviceMethodChannel
    )
  }

  public override func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didEncounterError error: Error
  ) {
    invokeFlutterMethod(
      ConnectedDeviceConstants.onAssociationError, methodChannel: connectedDeviceMethodChannel)
  }

  // MARK: - TrustAgentManagerDelegate

  public override func trustAgentManager(
    _ trustAgentManager: TrustAgentManager, didCompleteEnrolling car: Car, initiatedFromCar: Bool
  ) {
    invokeFlutterMethod(
      TrustedDeviceConstants.onTrustAgentEnrollmentCompleted,
      arguments: car.toDictionary(),
      methodChannel: trustedDeviceMethodChannel
    )
    if initiatedFromCar {
      showNotificationPermissionDialogIfNeeded()
      pushEnrollmentCompletedNotification(for: car)
    }
  }

  public override func trustAgentManager(
    _ trustAgentManager: TrustAgentManager, didUnenroll car: Car, initiatedFromCar: Bool
  ) {
    invokeFlutterMethod(
      TrustedDeviceConstants.onTrustAgentUnenrolled,
      arguments: car.toDictionary(),
      methodChannel: trustedDeviceMethodChannel
    )

    if initiatedFromCar {
      showNotificationPermissionDialogIfNeeded()
      pushUnenrollmentNotification(for: car)
    }
  }

  public override func trustAgentManager(
    _ trustAgentManager: TrustAgentManager,
    didEncounterEnrollingErrorFor car: Car,
    error: TrustAgentManagerError
  ) {
    handleEnrollingError(error, for: car)
  }

  private func handleEnrollingError(_ error: TrustAgentManagerError, for car: Car) {
    let convertedError = String(error.toEnrollmentError().rawValue)
    var arguments = car.toDictionary()
    arguments[TrustedDeviceConstants.trustAgentEnrollmentErrorKey] = convertedError

    invokeFlutterMethod(
      TrustedDeviceConstants.onTrustAgentEnrollmentError,
      arguments: arguments,
      methodChannel: trustedDeviceMethodChannel
    )
  }

  public override func trustAgentManager(
    _ trustAgentManager: TrustAgentManager, didStartUnlocking car: Car
  ) {
    invokeFlutterMethod(
      TrustedDeviceConstants.onUnlockStatusChanged,
      arguments: [
        ConnectedDeviceConstants.carIdKey: car.id,
        TrustedDeviceConstants.unlockStatusKey: String(UnlockStatus.inProgress.rawValue),
      ],
      methodChannel: trustedDeviceMethodChannel
    )
  }

  public override func trustAgentManager(
    _ trustAgentManager: TrustAgentManager, didSuccessfullyUnlock car: Car
  ) {
    invokeFlutterMethod(
      TrustedDeviceConstants.onUnlockStatusChanged,
      arguments: [
        ConnectedDeviceConstants.carIdKey: car.id,
        TrustedDeviceConstants.unlockStatusKey: String(UnlockStatus.success.rawValue),
      ],
      methodChannel: trustedDeviceMethodChannel
    )
    if shouldShowUnlockNotification(for: car) {
      pushUnlockNotification(for: car)
    }
  }

  public override func trustAgentManager(
    _ trustAgentManager: TrustAgentManager,
    didEncounterUnlockErrorFor car: Car,
    error: TrustAgentManagerError
  ) {
    invokeFlutterMethod(
      TrustedDeviceConstants.onUnlockStatusChanged,
      arguments: [
        ConnectedDeviceConstants.carIdKey: car.id,
        TrustedDeviceConstants.unlockStatusKey: String(UnlockStatus.error.rawValue),
      ],
      methodChannel: trustedDeviceMethodChannel
    )
  }
}

// MARK: - Extension helpers

extension UserDefaults {
  /// Returns `true` if the given key has a value mapped to it in `UserDefaults`.
  func containsKey(_ key: String) -> Bool {
    return object(forKey: key) != nil
  }
}

extension Car {
  /// Converts the current `Car` object to a dictionary.
  ///
  /// - Returns: A dictionary representation of the `Car`.
  fileprivate func toDictionary() -> [String: String] {
    return [
      ConnectedDeviceConstants.carIdKey: id,
      ConnectedDeviceConstants.carNameKey: name ?? "",
    ]
  }
}

extension FlutterMethodCall {
  /// Attempts to cast thet arguments of this current method call as a `Car` object.
  ///
  /// - Returns: A `Car` object from the arguments of `nil` if a conversion is not possible.
  fileprivate func argumentsToCar() -> Car? {
    guard let carMap = arguments as? [String: String],
      let carId = carMap[ConnectedDeviceConstants.carIdKey],
      let name = carMap[ConnectedDeviceConstants.carNameKey]
    else {
      return nil
    }

    return Car(id: carId, name: name)
  }
}

extension TrustAgentManagerError {
  fileprivate func toEnrollmentError() -> TrustedDeviceEnrollmentError {
    switch self {
    case .carNotConnected:
      return .carNotConnected
    case .passcodeNotSet:
      return .passcodeNotSet
    default:
      // There's currently no need for the app to know the exact details of any other errors.
      return .unknown
    }
  }
}
