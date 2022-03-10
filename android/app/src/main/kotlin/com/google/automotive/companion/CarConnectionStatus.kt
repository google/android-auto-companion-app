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

import java.util.UUID

/** The possible connection status that an associated car can be in. */
internal enum class CarConnectionStatus {
  // The car is attempting a connection and establishing a secure channel
  DETECTED,

  // A secure communication channel has been set up with an associated car.
  CONNECTED,

  // An associated car has disconnected.
  DISCONNECTED;

  /**
   * Converts the given [CarConnectionStatus] to a mapping that is suitable for sending across the
   * Flutter [MethodChannel].
   *
   * The given [deviceId] will be included in the resulting map as a String value as the car id.
   */
  internal fun toMapWithCarId(deviceId: UUID): Map<String, String> =
    mapOf(
      ConnectedDeviceConstants.CAR_ID_KEY to deviceId.toString(),
      ConnectedDeviceConstants.CAR_CONNECTION_STATUS_KEY to ordinal.toString(),
    )
}
