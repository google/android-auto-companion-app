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

import com.google.android.libraries.car.trustagent.AssociatedCar
import com.google.android.libraries.car.trustagent.Car
import io.flutter.plugin.common.MethodCall
import java.util.UUID

// This file contains functions/extensions that convert between common types used by the Android SDK
// and flutter method channel.

/** Default value used when an [AssociatedCar] has `null` name. */
private const val DEFAULT_CAR_NAME = "Default car name"

/** Puts parameters in a map with the expected key as method channel arguments. */
internal fun convertCarInfoToMap(deviceId: String, name: String?) =
  mapOf(
    ConnectedDeviceConstants.CAR_ID_KEY to deviceId,
    ConnectedDeviceConstants.CAR_NAME_KEY to name
  )

/** Creates method channel arguments as a map of device ID and name of [Car] */
internal fun Car.toMap() =
  mapOf(
    ConnectedDeviceConstants.CAR_ID_KEY to deviceId.toString(),
    ConnectedDeviceConstants.CAR_NAME_KEY to (name ?: DEFAULT_CAR_NAME)
  )

/** Creates method channel arguments as a map of device ID and name of [AssociatedCar] */
internal fun AssociatedCar.toMap() =
  mapOf(
    ConnectedDeviceConstants.CAR_ID_KEY to deviceId.toString(),
    ConnectedDeviceConstants.CAR_NAME_KEY to (name ?: DEFAULT_CAR_NAME)
  )

/** Casts [arguments] as a map. Throws exception if any value is not of specified type. */
// As inline so we can retrieve reified type parameters for error logging.
private inline fun <reified K, reified V> castArgumentsAsMap(arguments: Any): Map<K, V> {
  check(arguments is Map<*, *>) { "Expected arguments of type Map." }
  check(arguments.entries.all { (it.key is K) and (it.value is V) }) {
    "Expected arguments to contain key type ${K::class} and value type ${V::class}"
  }

  @Suppress("UNCHECKED_CAST")
  // This cast is safe because it's checked in the condition above.
  return arguments as Map<K, V>
}

/** Retrieves an argument by [key]. */
private fun MethodCall.getValueByKey(key: String): String {
  val arguments = castArgumentsAsMap<String, String>(arguments)
  return arguments.getValue(key)
}

/** Retrieves argument - device ID. */
internal val MethodCall.argumentDeviceId: UUID
  get() {
    val carId = getValueByKey(ConnectedDeviceConstants.CAR_ID_KEY)
    return UUID.fromString(carId)
  }

/** Retrieves argument - device name. */
internal val MethodCall.argumentName: String
  get() = getValueByKey(ConnectedDeviceConstants.CAR_NAME_KEY)

/** Retrieves argument - whether trusted device requires the phone to be unlocked. */
internal val MethodCall.argumentIsDeviceUnlockRequired: Boolean
  get() = getValueByKey(TrustedDeviceConstants.IS_DEVICE_UNLOCK_REQUIRED_KEY).toBoolean()

/** Retrieves argument - whether trusted device shows a notification when unlocking the phone. */
internal val MethodCall.argumentShowShowUnlockNotification: Boolean
  get() = getValueByKey(TrustedDeviceConstants.SHOULD_SHOW_UNLOCK_NOTIFICATION_KEY).toBoolean()
