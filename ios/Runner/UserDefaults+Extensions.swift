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

import Foundation

@available(iOS 10.0, *)
extension UserDefaults {
  enum UserDefaultsError: Error {
    /// Stored user settings couldn't be decoded into `CalendarConfig`.
    case failedToDecode
    /// User settings couldn't be encoded into `CalendarConfig`.
    case failedToEncode
  }

  /// Returns `true` if CalendarSync is enabled for the `carId`.
  public func isCalendarSyncEnabled(forCarId carId: String) throws -> Bool {
    return try calendarConfig(forCarId: carId).enabled
  }

  /// Enable CalendarSync for the `carId`.
  public func enableCalendarSync(forCarId carId: String) throws {
    var config = try calendarConfig(forCarId: carId)
    config.enabled = true
    try set(config, forCarId: carId)
  }

  /// Disable CalendarSync for the `carId`.
  public func disableCalendarSync(forCarId carId: String) throws {
    var config = try calendarConfig(forCarId: carId)
    config.enabled = false
    try set(config, forCarId: carId)
  }

  /// Retrieves a list of calendar identifiers to sync for the `carId`.
  public func calendarIdentifiersToSync(forCarId carId: String) throws -> [String] {
    return try calendarConfig(forCarId: carId).calendarIds
  }

  /// Stores the identifiers of the calendars to sync for the `carId`.
  public func store(calendarIdentifiersToSync calendarIdentifiers: [String], forCarId carId: String)
    throws
  {
    var config = try calendarConfig(forCarId: carId)
    config.calendarIds = calendarIdentifiers
    try set(config, forCarId: carId)
  }

  func set(_ calendarConfig: CalendarConfig, forCarId carId: String) throws {
    guard let encoded = try? JSONEncoder().encode(calendarConfig) else {
      throw UserDefaultsError.failedToEncode
    }
    set(encoded, forKey: carId)
  }

  private func calendarConfig(forCarId carId: String) throws -> CalendarConfig {
    guard let data = data(forKey: carId) else {
      return CalendarConfig()
    }

    guard let calendarConfig = try? JSONDecoder().decode(CalendarConfig.self, from: data) else {
      throw UserDefaultsError.failedToDecode
    }
    return calendarConfig
  }

  struct CalendarConfig: Codable {
    var enabled: Bool
    var calendarIds: [String]

    init() {
      enabled = false
      calendarIds = []
    }
  }

}
