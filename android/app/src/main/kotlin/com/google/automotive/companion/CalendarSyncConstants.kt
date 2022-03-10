/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.automotive.companion
/**
 * Constants for mapping calendar sync methods across the flutter `MethodChannel`.
 *
 * This file is auto-generated.
 */
object CalendarSyncConstants {
  const val CHANNEL = "google.gas.connecteddevice.feature/calendarsync"
  const val METHOD_HAS_PERMISSIONS = "hasPermissions"
  const val METHOD_REQUEST_PERMISSIONS = "requestPermissions"
  const val METHOD_RETRIEVE_CALENDARS = "retrieveCalendars"
  const val METHOD_IS_ENABLED = "isEnabled"
  const val METHOD_SET_ENABLED = "setEnabled"
  const val METHOD_GET_SELECTED_IDS = "getSelectedIds"
  const val METHOD_SET_SELECTED_IDS = "setSelectedIds"
  const val METHOD_IS_CAR_ENABLED = "isCarEnabled"
  const val METHOD_ENABLE_CAR = "enableCar"
  const val METHOD_DISABLE_CAR = "disableCar"
  const val METHOD_FETCH_CALENDAR_IDS_TO_SYNC = "fetchCalendarIdsToSync"
  const val METHOD_STORE_CALENDAR_IDS_TO_SYNC = "storeCalendarIdsToSync"
  const val ARGUMENT_CAR_ID = "carId"
  const val ARGUMENT_CALENDARS = "calendars"
  const val PREF_CALENDAR_IDS = "kCompanionCalSyncCalendarIds"
  const val PREF_ENABLED_STATE = "kCompanionCalSyncEnabled"
}
