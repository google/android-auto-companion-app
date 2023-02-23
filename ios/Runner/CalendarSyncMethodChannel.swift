import AndroidAutoCalendarSync
import AndroidAutoConnectedDeviceManager
import EventKit
import Flutter
import Foundation
import UIKit
import os.log

/// Platform implementation of the Calendar Sync companion feature to be used in Flutter app.
@available(iOS 10.0, *)
@MainActor
public class CalendarSyncMethodChannel {
  private static let log = OSLog(
    subsystem: "com.google.ios.aae.calendarsync.flutter",
    category: "CalendarSyncPlugin"
  )

  /// `FlutterError` error code kinds. Communicated back to the Flutter app.
  enum FlutterErrorCode: String {
    case error
    case missingArguments
    /// Interaction with the feature in disabled state.
    case notEnabled
  }

  /// Container for all calendar information that is sent to the calling Flutter app.
  struct CalendarViewData: Codable {
    let id: String
    let title: String
    let color: UInt32
    let account: String
  }

  // For now, we'll sync events within three days from now.
  private let daysToSync = 3

  private let methodChannel: FlutterMethodChannel

  let calendarSyncClient: CalendarSyncClientProtocol
  let eventStore: EKEventStore
  let userDefaults: UserDefaults

  public init<T: SomeCentralManager>(
    _ controller: FlutterViewController,
    connectionManager: ConnectionManager<T>
  ) {
    methodChannel = FlutterMethodChannel(
      name: CalendarSyncConstants.channel,
      binaryMessenger: controller.binaryMessenger)

    self.eventStore = EKEventStore()

    self.calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore,
      connectedCarManager: connectionManager
    )
    self.userDefaults = .standard

    methodChannel.setMethodCallHandler(handle)

    do {
      for channel in connectionManager.securedChannels {
        if try userDefaults.isCalendarSyncEnabled(forCarId: channel.car.id) {
          try synchronize(forCarId: channel.car.id)
        }
      }
    } catch {
      os_log(
        "Failed to synchronize connected cars (%@)",
        log: Self.log,
        type: .error,
        error.localizedDescription)
    }
  }

  nonisolated public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      switch call.method {
      case CalendarSyncConstants.hasPermissions:
        result(eventStore.hasPermissions)
      case CalendarSyncConstants.requestPermissions:
        await requestPermissions(result: result)
      case CalendarSyncConstants.retrieveCalendars:
        await retrieveCalendars(result: result)
      case CalendarSyncConstants.disableCar:
        await disableCar(call: call, result: result)
      case CalendarSyncConstants.enableCar:
        await enableCar(call: call, result: result)
      case CalendarSyncConstants.isCarEnabled:
        await isCarEnabled(call: call, result: result)
      case CalendarSyncConstants.fetchCalendarIdsToSync:
        await fetchCalendarIdsToSync(call: call, result: result)
      case CalendarSyncConstants.storeCalendarIdsToSync:
        await storeCalendarIdsToSync(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    if eventStore.hasPermissions {
      result(true)
      return
    }
    eventStore.requestAccess(to: .event) { granted, _ in
      result(granted)
    }
  }

  private func retrieveCalendars(result: @escaping FlutterResult) {
    do {
      let calendars = try eventStore.calendars().map {
        CalendarViewData(
          id: $0.calendarIdentifier, title: $0.title, color: $0.cgColor.argb(),
          account: $0.source.title)
      }
      let jsonString = try encodeJson(codable: calendars)
      result(jsonString)
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }
  }

  // MARK: - Car-specific methods

  private func disableCar(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let carId = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    do {
      try userDefaults.disableCalendarSync(forCarId: carId)
      try unsynchronize(forCarId: carId)
      result(nil)
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }
  }

  private func enableCar(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let carId = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    do {
      try userDefaults.enableCalendarSync(forCarId: carId)
      try synchronize(forCarId: carId)
      result(nil)
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }
  }

  private func isCarEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let carId = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    do {
      result(try userDefaults.isCalendarSyncEnabled(forCarId: carId))
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }
  }

  private func fetchCalendarIdsToSync(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let carId = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    do {
      result(try userDefaults.calendarIdentifiersToSync(forCarId: carId))
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }
  }

  private func storeCalendarIdsToSync(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(flutterError(code: .missingArguments, message: "Missing arguments"))
      return
    }
    guard let carId = arguments[CalendarSyncConstants.carId] as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    guard
      let calendarIdentifiers = arguments[CalendarSyncConstants.calendars] as? [String]
    else {
      result(
        flutterError(code: .missingArguments, message: "Missing calendar identifiers argument"))
      return
    }

    do {
      guard try userDefaults.isCalendarSyncEnabled(forCarId: carId) else {
        result(flutterError(code: .notEnabled, message: "Feature not enabled"))
        return
      }

      // Obtain all calendars for the given identifiers, to make sure they still exist.
      let ekCalendars = try eventStore.calendars(for: calendarIdentifiers)

      let newCalendarIdentifiersToSync = ekCalendars.map { $0.calendarIdentifier }
      let currentCalendarIdentifiersToSync = try userDefaults.calendarIdentifiersToSync(
        forCarId: carId)

      let calendarIdentifiersToRemove = currentCalendarIdentifiersToSync.filter {
        !newCalendarIdentifiersToSync.contains($0)
      }
      let calendarIdentifiersToAdd = newCalendarIdentifiersToSync.filter {
        !currentCalendarIdentifiersToSync.contains($0)
      }

      try unsynchronize(calendarIdentifiers: calendarIdentifiersToRemove, forCarId: carId)
      try userDefaults.store(
        calendarIdentifiersToSync: newCalendarIdentifiersToSync, forCarId: carId)
      try synchronize(calendarIdentifiers: calendarIdentifiersToAdd, forCarId: carId)
      result(nil)
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }

  }

  // MARK: - Helper methods

  /// Un-synchronizes the calendars with the given identifiers from the specified car.
  ///
  /// - Parameter calendarIdentifiers: A list of calendar identifiers to synchronize. If `nil` all
  ///   stored calendars will be synchronized.
  private func unsynchronize(calendarIdentifiers: [String]? = nil, forCarId carId: String)
    throws
  {
    calendarSyncClient.unsync(
      calendarIdentifiers: try calendarIdentifiers ?? storedCalendarIdentifiers(forCarId: carId),
      forCarId: carId)
  }

  /// Synchronizes the calendars with the given identifiers to the specified car.
  ///
  /// - Parameter calendarIdentifiers: A list of calendar identifiers to synchronize. If `nil` all
  ///   stored calendars will be synchronized.
  /// - Throws: `EKEventStoreError` if permission to access calendar data is not given, or
  ///   `UserDefaultsError` if user settings encoding or decoding failed.
  private func synchronize(calendarIdentifiers: [String]? = nil, forCarId carId: String)
    throws
  {
    // Use the provided calendar identifiers or obtain all calendars for the stored identifiers,
    // to make sure they still exist.
    let ekCalendars = try eventStore.calendars(
      for: try calendarIdentifiers ?? storedCalendarIdentifiers(forCarId: carId))
    if ekCalendars.isEmpty {
      os_log("No calendars found to synchronize.", log: Self.log, type: .debug)
      return
    }

    let startDate = Date()
    let endDate = Calendar.current.date(byAdding: DateComponents(day: daysToSync), to: startDate)!

    calendarSyncClient.sync(
      calendars: ekCalendars, forCarId: carId, withStart: startDate, end: endDate)
  }

  private func storedCalendarIdentifiers(forCarId carId: String) throws -> [String] {
    return try userDefaults.calendarIdentifiersToSync(forCarId: carId)
  }

  private func encodeJson<T: Codable>(codable: T) throws -> String {
    let jsonEncoder = JSONEncoder()
    let jsonData = try jsonEncoder.encode(codable)
    return String(data: jsonData, encoding: .utf8)!
  }

  private func flutterError(code: FlutterErrorCode, message: String) -> FlutterError {
    return FlutterError(code: code.rawValue, message: message, details: nil)
  }
}
