// Copyright 2023 Google LLC
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

import AndroidAutoCalendarSync
import AndroidAutoConnectedDeviceManager
import AndroidAutoLogger
import EventKit
import Flutter
import Foundation
import UIKit

/// Platform implementation of the Calendar Sync companion feature to be used in Flutter app.
@MainActor public class CalendarSyncMethodChannel {
  private static let log = Logger(for: CalendarSyncMethodChannel.self)

  var settings = CarCalendarSettings(UserDefaults.standard)

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

  /// For now, we'll sync events within three days from now.
  private let daysToSync = 3

  private let methodChannel: FlutterMethodChannel

  let calendarSyncClient: any CalendarSyncClient
  let eventStore: EKEventStore

  public init<T: SomeCentralManager>(
    _ controller: FlutterViewController,
    connectionManager: ConnectionManager<T>
  ) {
    methodChannel = FlutterMethodChannel(
      name: CalendarSyncConstants.channel,
      binaryMessenger: controller.binaryMessenger)

    self.eventStore = EKEventStore()

    self.calendarSyncClient = CalendarSyncClientFactory.v2.makeClient(
      settings: settings,
      eventStore: eventStore,
      connectedCarManager: connectionManager,
      syncDuration: .days(daysToSync)
    )

    methodChannel.setMethodCallHandler(handle)

    do {
      for channel in connectionManager.securedChannels {
        if settings[channel.car].isEnabled {
          try synchronize(withCar: channel.car.id)
        }
      }
    } catch {
      Self.log.error("Failed to synchronize connected cars (\(error.localizedDescription))")
    }
  }

  nonisolated private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task { @MainActor [weak self] in
      guard let self else { return }

      switch call.method {
      case CalendarSyncConstants.hasPermissions:
        result(self.eventStore.hasPermissions)
      case CalendarSyncConstants.requestPermissions:
        await self.requestPermissions(result: result)
      case CalendarSyncConstants.retrieveCalendars:
        self.retrieveCalendars(result: result)
      case CalendarSyncConstants.disableCar:
        self.disableCar(call: call, result: result)
      case CalendarSyncConstants.enableCar:
        self.enableCar(call: call, result: result)
      case CalendarSyncConstants.isCarEnabled:
        self.isCarEnabled(call: call, result: result)
      case CalendarSyncConstants.fetchCalendarIdsToSync:
        self.fetchCalendarIdsToSync(call: call, result: result)
      case CalendarSyncConstants.storeCalendarIdsToSync:
        self.storeCalendarIdsToSync(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestPermissions(result: @escaping FlutterResult) async {
    if eventStore.isAuthorized {
      result(true)
      return
    }

    do {
      let isGranted: Bool
      if #available(iOS 17.0, *) {
        isGranted = try await eventStore.requestFullAccessToEvents()
      } else {
        isGranted = try await eventStore.requestAccess(to: .event)
      }
      result(isGranted)
    } catch {
      Self.log.error(
        """
        Error requesting full access to calendar events: \(error.localizedDescription)
        """
      )
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
    guard let carID = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    do {
      settings[carID].isEnabled = false
      try unsynchronize(withCar: carID)
      result(nil)
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }
  }

  private func enableCar(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let carID = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    do {
      settings[carID].isEnabled = true
      try synchronize(withCar: carID)
      result(nil)
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }
  }

  private func isCarEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let carID = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    result(settings[carID].isEnabled)
  }

  private func fetchCalendarIdsToSync(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let carID = call.arguments as? String else {
      result(flutterError(code: .missingArguments, message: "Missing car identifier argument"))
      return
    }
    result(Array(settings[carID].calendarIDs))
  }

  private func storeCalendarIdsToSync(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(flutterError(code: .missingArguments, message: "Missing arguments"))
      return
    }
    guard let carID = arguments[CalendarSyncConstants.carId] as? String else {
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
      guard settings[carID].isEnabled else {
        result(flutterError(code: .notEnabled, message: "Feature not enabled"))
        return
      }

      // Obtain all calendars for the given identifiers, to make sure they still exist.
      let ekCalendars = try eventStore.calendars(for: calendarIdentifiers)

      let newCalendarIdentifiersToSync = Set(ekCalendars.map { $0.calendarIdentifier })
      let currentCalendarIdentifiersToSync = settings[carID].calendarIDs

      let calendarIdentifiersToRemove = currentCalendarIdentifiersToSync.filter {
        !newCalendarIdentifiersToSync.contains($0)
      }
      let calendarIdentifiersToAdd = newCalendarIdentifiersToSync.filter {
        !currentCalendarIdentifiersToSync.contains($0)
      }

      try unsynchronize(calendars: calendarIdentifiersToRemove, withCar: carID)
      settings[carID].calendarIDs = newCalendarIdentifiersToSync
      try synchronize(calendars: calendarIdentifiersToAdd, withCar: carID)
      result(nil)
    } catch {
      result(flutterError(code: .error, message: error.localizedDescription))
    }

  }

  // MARK: - Helper methods

  /// Un-synchronizes the calendars with the given identifiers from the specified car.
  ///
  /// - Parameter calendars: A list of calendar identifiers to synchronize. If `nil` all
  ///   stored calendars will be synchronized.
  private func unsynchronize(
    calendars calendarIdentifiers: Set<String>? = nil,
    withCar carID: String
  ) throws {
    try calendarSyncClient.unsync(
      calendars: calendarIdentifiers ?? Set(settings[carID].calendarIDs),
      withCar: carID
    )
  }

  /// Synchronizes the calendars with the given identifiers to the specified car.
  ///
  /// - Parameter calendars: Calendar identifiers to synchronize. If `nil` all
  ///   stored calendars will be synchronized.
  /// - Throws: `EKEventStoreError` if permission to access calendar data is not given, or
  ///   `UserDefaultsError` if user settings encoding or decoding failed.
  private func synchronize(
    calendars calendarIdentifiers: Set<String>? = nil,
    withCar carID: String
  ) throws {
    // Use the provided calendar identifiers or obtain all calendars for the stored identifiers,
    // to make sure they still exist.
    Self.log.info("Start calendar synchronizing.")

    let calendarIDs = calendarIdentifiers ?? Set(settings[carID].calendarIDs)

    guard !calendarIDs.isEmpty else {
      Self.log.debug("No calendars found to synchronize.")
      return
    }

    try calendarSyncClient.sync(calendars: calendarIDs, withCar: carID)
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
