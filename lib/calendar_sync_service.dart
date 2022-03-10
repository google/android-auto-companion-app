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

import 'dart:async';
import 'dart:convert';

import 'package:automotive_companion/calendar_view_data.dart';
import 'package:automotive_companion/values/calendar_sync_constants.dart'
    as constants;
import 'package:flutter/services.dart';

/// Service for the Calendar Sync companion feature that abstracts platform
/// specific calendar data access and sync functionality.
class CalendarSyncService {
  final MethodChannel _channel = MethodChannel(constants.CHANNEL);

  /// Returns true if the user has granted permissions to access calendar data.
  Future<bool> hasPermissions() {
    return _channel
        .invokeMethod<bool>(constants.METHOD_HAS_PERMISSIONS)
        .then((hasPermissions) => hasPermissions ?? false);
  }

  /// Requests permissions to access calendar data and returns true if the user
  /// has granted access.
  Future<bool> requestPermissions() {
    return _channel
        .invokeMethod(constants.METHOD_REQUEST_PERMISSIONS)
        .then((isGranted) => isGranted ?? false);
  }

  /// Returns a list of calendars that are locally available on the device.
  Future<List<CalendarViewData>> fetchCalendars() async {
    var calendarsJson =
        await _channel.invokeMethod(constants.METHOD_RETRIEVE_CALENDARS);
    return List.unmodifiable(json.decode(calendarsJson).map<CalendarViewData>(
        (decodedCalendar) => CalendarViewData.fromJson(decodedCalendar)));
  }

  /// Returns true if this feature is enabled for the given car identifier.
  ///
  /// The [carId] is corresponding to [Car.id].
  Future<bool> isCarEnabled({required String carId}) {
    return _channel
        .invokeMethod(constants.METHOD_IS_CAR_ENABLED, carId)
        .then((enabled) => enabled ?? false);
  }

  /// Enables this feature for the given car identifier.
  ///
  /// The [carId] is corresponding to [Car.id].
  Future<void> enableCar({required String carId}) =>
      _channel.invokeMethod(constants.METHOD_ENABLE_CAR, carId);

  /// Disables this feature for the given car identifier.
  ///
  /// The [carId] is corresponding to [Car.id].
  Future<void> disableCar({required String carId}) =>
      _channel.invokeMethod(constants.METHOD_DISABLE_CAR, carId);

  /// Returns the calendar ids selected to sync to the given car identifier.
  ///
  /// The [carId] is corresponding to [Car.id].
  Future<List<String>> fetchCalendarIdsToSync({required String carId}) {
    return _channel
        .invokeListMethod<String>(
            constants.METHOD_FETCH_CALENDAR_IDS_TO_SYNC, carId)
        .then((ids) => ids ?? []);
  }

  /// Stores the calendar ids selected to sync for the given [carId].
  ///
  /// The [carId] is corresponding to [Car.id].
  Future<void> storeCalendarIdsToSync(List<String> calendarIds,
      {required carId}) {
    return _channel.invokeMethod(constants.METHOD_STORE_CALENDAR_IDS_TO_SYNC, {
      constants.ARGUMENT_CAR_ID: carId,
      constants.ARGUMENT_CALENDARS: calendarIds
    });
  }
}
