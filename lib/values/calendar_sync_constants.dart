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

const CHANNEL = "google.gas.connecteddevice.feature/calendarsync";
const METHOD_HAS_PERMISSIONS = "hasPermissions";
const METHOD_REQUEST_PERMISSIONS = "requestPermissions";
const METHOD_RETRIEVE_CALENDARS = "retrieveCalendars";
const METHOD_IS_ENABLED = "isEnabled";
const METHOD_SET_ENABLED = "setEnabled";
const METHOD_GET_SELECTED_IDS = "getSelectedIds";
const METHOD_SET_SELECTED_IDS = "setSelectedIds";
const METHOD_IS_CAR_ENABLED = "isCarEnabled";
const METHOD_ENABLE_CAR = "enableCar";
const METHOD_DISABLE_CAR = "disableCar";
const METHOD_FETCH_CALENDAR_IDS_TO_SYNC = "fetchCalendarIdsToSync";
const METHOD_STORE_CALENDAR_IDS_TO_SYNC = "storeCalendarIdsToSync";
const ARGUMENT_CAR_ID = "carId";
const ARGUMENT_CALENDARS = "calendars";
