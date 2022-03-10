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

/// Constants for mapping methods across the flutter `MethodChannel`.
///
/// This file is auto-generated.
enum ConnectedDeviceConstants {
  static let channel = "google.gas.batmobile.connecteddevice/method"
  static let isBluetoothEnabled = "isBluetoothEnabled"
  static let onStateChanged = "onStateChanged"
  static let onCarDiscovered = "onCarDiscovered"
  static let scanForCarsToAssociate = "scanForCarsToAssociate"
  static let associateCar = "associateCar"
  static let getConnectedCars = "getConnectedCars"
  static let onPairingCodeAvailable = "onPairingCodeAvailable"
  static let onAssociationCompleted = "onAssociationCompleted"
  static let onAssociationError = "onAssociationError"
  static let openSecuritySettings = "openSecuritySettings"
  static let openApplicationDetailsSettings = "openApplicationDetailsSettings"
  static let openBluetoothSettings = "openBluetoothSettings"
  static let getAssociatedCars = "getAssociatedCars"
  static let connectToAssociatedCars = "connectToAssociatedCars"
  static let clearCurrentAssociation = "clearCurrentAssociation"
  static let clearAssociation = "clearAssociation"
  static let onCarConnectionStatusChange = "onCarConnectionStatusChange"
  static let carNameKey = "carNameKey"
  static let carIdKey = "carIdKey"
  static let carConnectionStatusKey = "carConnectionStatusKey"
  static let connectionManagerStateKey = "connectionManagerStateKey"
  static let pairingCodeKey = "pairingCodeKey"
  static let renameCar = "renameCar"
  static let isCarConnected = "isCarConnected"
  static let isLogSharingSupported = "isLogSharingSupported"
  static let onDiscoveryError = "onDiscoveryError"
  static let isBluetoothPermissionGranted = "isBluetoothPermissionGranted"
}
