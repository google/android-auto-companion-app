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
 * Constants for mapping methods across the flutter `MethodChannel`.
 *
 * This file is auto-generated.
 */
object ConnectedDeviceConstants {
  const val CHANNEL = "google.gas.batmobile.connecteddevice/method"
  const val IS_BLUETOOTH_ENABLED = "isBluetoothEnabled"
  const val ON_STATE_CHANGED = "onStateChanged"
  const val ON_CAR_DISCOVERED = "onCarDiscovered"
  const val SCAN_FOR_CARS_TO_ASSOCIATE = "scanForCarsToAssociate"
  const val ASSOCIATE_CAR = "associateCar"
  const val GET_CONNECTED_CARS = "getConnectedCars"
  const val ON_PAIRING_CODE_AVAILABLE = "onPairingCodeAvailable"
  const val ON_ASSOCIATION_COMPLETED = "onAssociationCompleted"
  const val ON_ASSOCIATION_ERROR = "onAssociationError"
  const val OPEN_SECURITY_SETTINGS = "openSecuritySettings"
  const val OPEN_APPLICATION_DETAILS_SETTINGS = "openApplicationDetailsSettings"
  const val OPEN_BLUETOOTH_SETTINGS = "openBluetoothSettings"
  const val GET_ASSOCIATED_CARS = "getAssociatedCars"
  const val CONNECT_TO_ASSOCIATED_CARS = "connectToAssociatedCars"
  const val CLEAR_CURRENT_ASSOCIATION = "clearCurrentAssociation"
  const val CLEAR_ASSOCIATION = "clearAssociation"
  const val ON_CAR_CONNECTED = "onCarConnected"
  const val ON_CAR_DISCONNECTED = "onCarDisconnected"
  const val CAR_NAME_KEY = "carNameKey"
  const val CAR_ID_KEY = "carIdKey"
  const val CONNECTION_MANAGER_STATE_KEY = "connectionManagerStateKey"
  const val PAIRING_CODE_KEY = "pairingCodeKey"
  const val RENAME_CAR = "renameCar"
  const val IS_CAR_CONNECTED = "isCarConnected"
  const val IS_LOG_SHARING_SUPPORTED = "isLogSharingSupported"
  const val ON_DISCOVERY_ERROR = "onDiscoveryError"
  const val IS_BLUETOOTH_PERMISSION_GRANTED = "isBluetoothPermissionGranted"
  const val ON_CAR_CONNECTION_STATUS_CHANGE = "onCarConnectionStatusChange"
  const val CAR_CONNECTION_STATUS_KEY = "carConnectionStatusKey"
  const val ON_ASSOCIATION_STARTED = "onAssociationStarted"
  const val ON_ASSOCIATION_DISCOVERY_CANCELLED = "onAssociationDiscoveryCancelled"
}
