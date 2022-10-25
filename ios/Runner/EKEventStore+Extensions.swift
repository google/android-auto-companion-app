import EventKit
import Foundation

@available(iOS 10.0, *)
extension EKEventStore {
  enum EKEventStoreError: Error {
    /// User did not grant permission to use calendar.
    case notAuthorized
  }

  /// True if calendar access permission are granted, otherwise false.
  public var hasPermissions: Bool {
    let authorizationStatus = Self.authorizationStatus(for: .event)
    return authorizationStatus == .authorized
  }

  /// Retrieves all calendars.
  ///
  /// Checks the `EKAuthorizationStatus` before calendars are retriieved and throws an error if
  /// calendar access is not granted.
  ///
  /// - Throws: `EKEventStoreError` if permission to access calendar data is not given.
  public func calendars() throws -> [EKCalendar] {
    guard hasPermissions else {
      throw EKEventStoreError.notAuthorized
    }
    return calendars(for: .event)
  }

  /// Retrieves all calandars for the given identifiers.
  ///
  /// Checks the `EKAuthorizationStatus` before calendars are retriieved and throws an error if
  /// calendar access is not granted.
  ///
  /// - Throws: `EKEventStoreError` if permission to access calendar data is not given.
  public func calendars(for calendarIdentifiers: [String]) throws -> [EKCalendar] {
    return try calendars().filter { calendarIdentifiers.contains($0.calendarIdentifier) }
  }
}
