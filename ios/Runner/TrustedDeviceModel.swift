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
import Combine
import CoreBluetooth
import os.log

/// Common model for the trusted device state. Subclass this for each platform.
@available(iOS 10.0, watchOS 6.0, *)
@MainActor
open class TrustedDeviceModel:
  NSObject,
  ConnectionManagerAssociationDelegate,
  TrustAgentManagerDelegate,
  ObservableObject
{
  public typealias ConnectionManager = CoreBluetoothConnectionManager

  public let connectionManager: CoreBluetoothConnectionManager
  public let trustAgentManager: TrustAgentManager

  #if os(watchOS)
    @Published public var discoveredCars: [String: CBPeripheral] = [:]
  #else
    public var discoveredCars: [String: CBPeripheral] = [:]
  #endif

  private var stateObservationHandle: ObservationHandle?
  private var connectObservationHandle: ObservationHandle?
  private var disconnectObservationHandle: ObservationHandle?
  private var secureChannelObservationHandle: ObservationHandle?

  override public init() {
    connectionManager = CoreBluetoothConnectionManager()
    trustAgentManager = TrustAgentManager(connectedCarManager: connectionManager)

    super.init()

    connectionManager.associationDelegate = self
    trustAgentManager.delegate = self

    stateObservationHandle = connectionManager.observeStateChange { [weak self] _, state in
      // No need to convey any other states back to the flutter app.
      if state.isOther { return }

      self?.onStateChange(state: state)
    }

    connectObservationHandle = connectionManager.observeConnection { [weak self] _, car in
      self?.onConnection(car: car)
    }

    disconnectObservationHandle = connectionManager.observeDisconnection { [weak self] _, car in
      self?.onDisconnection(car: car)
    }

    secureChannelObservationHandle = connectionManager.observeSecureChannelSetUp {
      [weak self] _, securedCarChannel in
      self?.onSecureChannelSetup(car: securedCarChannel.car)
    }
  }

  deinit {
    stateObservationHandle?.cancel()
    connectObservationHandle?.cancel()
    disconnectObservationHandle?.cancel()
    secureChannelObservationHandle?.cancel()
  }

  /// Determine whether there is a secure connection with the car having the specified id.
  ///
  /// - Parameter car: The car for which to check for the secure connection.
  /// - Returns: `true` if the car is connected securely.
  public func isCarConnectedSecurely(_ car: Car) -> Bool {
    return connectionManager.isCarConnectedSecurely(car)
  }

  /// Begins the association process with the given car.
  ///
  /// - Parameter car: the car to associate.
  public func associate(_ car: Car) {
    guard connectionManager.state.isPoweredOn else {
      os_log(
        "Associate car method invoked when BLE adapter is not on. Ignoring.",
        type: .error)
      return
    }

    guard let carToAssociate = discoveredCars[car.id] else {
      os_log(
        "Call to associate a car with UUID %@, but no cars with that UUID found. Ignoring",
        type: .error,
        car.id)
      return
    }

    os_log("Call to associate car with UUID %@", type: .debug, car.id)

    do {
      try connectionManager.associate(carToAssociate)
    } catch {
      os_log("Association was unsuccessful: %@", type: .error, error.localizedDescription)
    }
  }

  // MARK: - observation handling

  open func onStateChange(state: RadioState) {
    // subclasses should override
  }

  open func onConnection(car: Car) {
    // subclasses should override
  }

  open func onDisconnection(car: Car) {
    // subclasses should override
  }

  open func onSecureChannelSetup(car: Car) {
    // subclasses should override
  }

  // MARK: - ConnectionManagerAssociationDelegate

  open func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didDiscover anyCar: AnyPeripheral,
    advertisedName: String?
  ) {
    guard let car = anyCar as? CBPeripheral else {
      fatalError("car expected as CBPeripheral but instead found \(type(of: anyCar))")
    }
    discoveredCars[car.identifier.uuidString] = car
  }

  open func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didConnect peripheral: AnyPeripheral
  ) {
    // Nothing is using this callback right now, so this is a no-op.
  }

  open func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didDisconnect peripheral: AnyPeripheral
  ) {
    discoveredCars[peripheral.identifier.uuidString] = nil
  }

  open func connectionManager(
    _ connectionManager: AnyConnectionManager,
    requiresDisplayOf pairingCode: String
  ) {
  }

  open func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didCompleteAssociationWithCar car: Car
  ) {
  }

  open func connectionManager(
    _ connectionManager: AnyConnectionManager,
    didEncounterError error: Error
  ) {
  }

  // MARK: - TrustAgentManagerDelegate

  open func trustAgentManager(
    _ trustAgentManager: TrustAgentManager, didCompleteEnrolling car: Car, initiatedFromCar: Bool
  ) {
  }

  open func trustAgentManager(
    _ trustAgentManager: TrustAgentManager,
    didEncounterEnrollingErrorFor car: Car,
    error: TrustAgentManagerError
  ) {
    // TODO(b/128844460): Handle error states.
  }

  open func trustAgentManager(
    _ trustAgentManager: TrustAgentManager, didUnenroll car: Car, initiatedFromCar: Bool) {
  }

  open func trustAgentManager(_ trustAgentManager: TrustAgentManager, didStartUnlocking car: Car) {
  }

  open func trustAgentManager(
    _ trustAgentManager: TrustAgentManager, didSuccessfullyUnlock car: Car
  ) {
  }

  open func trustAgentManager(
    _ trustAgentManager: TrustAgentManager,
    didEncounterUnlockErrorFor car: Car,
    error: TrustAgentManagerError
  ) {
  }
}

// MARK: - Extension helpers


/// Bluetooth value states that the flutter application understands.
private enum BluetoothState: String {
  case error = "0"
  case on = "1"
  case off = "2"
}

@available(iOS 10.0, watchOS 6.0, *)
extension RadioState {
  /// Converts this `CBManagerState` to a bluetooth state that the flutter app understands.
  public func toBluetoothState() -> String {
    if isPoweredOn {
      return BluetoothState.on.rawValue
    } else if isPoweredOff {
      return BluetoothState.off.rawValue
    } else if isUnknown {
      return BluetoothState.error.rawValue
    } else {
      // All other states should not map to anything because they do not need to be conveyed back
      // to the flutter app.
      return ""
    }
  }
}
