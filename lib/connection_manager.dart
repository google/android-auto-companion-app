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

import 'dart:developer';

import 'package:flutter/services.dart';
import 'method_channel_handler.dart';
import 'values/connected_device_constants.dart' as connected_device_constants;

import 'car.dart';

/// This is a singleton method channel used to communicate between the Flutter
/// UI and phone connected device library. This method channel should be able to
/// call method in phone library and also handle method calls from phone's
/// platform.
class ConnectionManager extends MethodChannelHandler {
  final _associationCallbacks = <AssociationCallback>[];
  final _discoveryCallbacks = <DiscoveryCallback>[];
  final _connectionCallbacks = <ConnectionCallback>[];
  final _onLogFilesUpdatedListeners = <OnLogFilesUpdatedListener>[];

  ConnectionManager()
      : super(MethodChannel(connected_device_constants.CHANNEL)) {
    // Internally, the ConnectionManager is the method handler.
    methodChannel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case connected_device_constants.ON_STATE_CHANGED:
          // Iterate through our connection manager callback list and notify
          // them.
          for (final callback in _connectionCallbacks) {
            callback.onBluetoothStateChanged(call.arguments[
                connected_device_constants.CONNECTION_MANAGER_STATE_KEY]);
          }
          break;
        case connected_device_constants.ON_DISCOVERY_ERROR:
          for (final callback in _discoveryCallbacks) {
            callback.onDiscoveryError();
          }
          break;
        case connected_device_constants.ON_ASSOCIATION_DISCOVERY_CANCELLED:
          for (final callback in _discoveryCallbacks) {
            callback.onDiscoveryCancelled();
          }
          break;
        case connected_device_constants.ON_CAR_DISCOVERED:
          for (final callback in _discoveryCallbacks) {
            callback.onCarDiscovered(argumentsToCar(call));
          }
          break;
        case connected_device_constants.ON_CAR_CONNECTION_STATUS_CHANGE:
          // The status is passed as a String. Convert to an int and index to
          // get the right enum value.
          final connectionStatus = CarConnectionStatus.values[int.parse(
              call.arguments[
                  connected_device_constants.CAR_CONNECTION_STATUS_KEY])];

          for (final callback in _connectionCallbacks) {
            callback.onCarConnectionStatusChange(
                call.arguments[connected_device_constants.CAR_ID_KEY],
                connectionStatus);
          }
          break;
        case connected_device_constants.ON_PAIRING_CODE_AVAILABLE:
          for (final callback in _associationCallbacks) {
            callback.onPairingCodeAvailable(
                call.arguments[connected_device_constants.PAIRING_CODE_KEY]);
          }
          break;
        case connected_device_constants.ON_ASSOCIATION_COMPLETED:
          for (final callback in _associationCallbacks) {
            callback.onAssociationCompleted(argumentsToCar(call));
          }
          break;
        case connected_device_constants.ON_ASSOCIATION_ERROR:
          for (final callback in _associationCallbacks) {
            callback.onAssociationError();
          }
          break;
        case connected_device_constants.ON_ASSOCIATION_STARTED:
          for (final callback in _discoveryCallbacks) {
            callback.onAssociationStarted();
          }
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  /// Register the association callbacks when there are updates during the
  /// association process.
  void registerAssociationCallback(AssociationCallback callback) {
    _associationCallbacks.add(callback);
  }

  /// Register the connection callbacks when there are updated during the
  /// connection process.
  void registerConnectionCallback(ConnectionCallback callback) {
    _connectionCallbacks.add(callback);
  }

  /// Register the discovery callbacks when there are updated during the
  /// discovery process.
  void registerDiscoveryCallback(DiscoveryCallback callback) {
    _discoveryCallbacks.add(callback);
  }

  void registerOnLogFilesUpdatedListener(OnLogFilesUpdatedListener listener) {
    _onLogFilesUpdatedListeners.add(listener);
  }

  void unregisterAssociationCallback(AssociationCallback callback) {
    _associationCallbacks.remove(callback);
  }

  void unregisterDiscoveryCallback(DiscoveryCallback callback) {
    _discoveryCallbacks.remove(callback);
  }

  void unregisterConnectionCallback(ConnectionCallback callback) {
    _connectionCallbacks.remove(callback);
  }

  void unregisterOnLogFilesUpdatedListener(OnLogFilesUpdatedListener listener) {
    _onLogFilesUpdatedListeners.remove(listener);
  }

  /// Returns 'true' if Bluetooth is enabled.
  ///
  /// If this value is true, then the connection manager can be used to scan for
  /// and connect to cars.
  Future<bool> get isBluetoothEnabled => methodChannel
      .invokeMethod(connected_device_constants.IS_BLUETOOTH_ENABLED);

  Future<bool> get isBluetoothPermissionGranted => methodChannel
      .invokeMethod(connected_device_constants.IS_BLUETOOTH_PERMISSION_GRANTED);

  /// Starts scanning for cars that are advertising, prepending the given
  /// [namePrefix] to the name of discovered cars.
  void scanForCarsToAssociate(String namePrefix) {
    invokeMethod(
        connected_device_constants.SCAN_FOR_CARS_TO_ASSOCIATE, namePrefix);
  }

  /// Clears the current association state and data. Should be called when user
  /// cancels the association
  void clearCurrentAssociation() {
    invokeMethod(connected_device_constants.CLEAR_CURRENT_ASSOCIATION);
  }

  /// Opens system application details setting of native platform.
  void openApplicationDetailsSettings() {
    invokeMethod(connected_device_constants.OPEN_APPLICATION_DETAILS_SETTINGS);
  }

  void openBluetoothSettings() {
    invokeMethod(connected_device_constants.OPEN_BLUETOOTH_SETTINGS);
  }

  /// Associates a car with the given id.
  void associateCar(String id) {
    invokeMethod(connected_device_constants.ASSOCIATE_CAR, id);
  }

  /// Returns the list of cars that are currently associated with the current
  /// device.
  Future<List<Car>> fetchAssociatedCars() async {
    try {
      return _invokeListMethod(connected_device_constants.GET_ASSOCIATED_CARS);
    } on PlatformException catch (e) {
      log("Failed to fetch associated cars with error: '${e.message}'.");
      return <Car>[];
    }
  }

  /// Returns the list of cars that are currently connected to this device.
  ///
  /// This list is a subset of the list returned by [fetchAssociatedCars] since
  /// a car can only be connected if it is associated.
  Future<List<Car>> fetchConnectedCars() async {
    try {
      return _invokeListMethod(connected_device_constants.GET_CONNECTED_CARS);
    } on PlatformException catch (e) {
      log("Failed to fetch associated cars with error: '${e.message}'.");
      return <Car>[];
    }
  }

  /// Invokes a native method of [methodName] that will return a list of [Car]s.
  Future<List<Car>> _invokeListMethod(String methodName) async {
    final associatedCars =
        await methodChannel.invokeListMethod<Map<dynamic, dynamic>>(methodName);
    return associatedCars
        .map((carMap) => Car(carMap[connected_device_constants.CAR_ID_KEY],
            carMap[connected_device_constants.CAR_NAME_KEY]))
        .toList();
  }

  /// Starts a connection to any cars that have already been associated.
  ///
  /// Once connected, all features that have been enabled for that car will
  /// be stated. For example, trusted device, which unlocks a remote head unit.
  void connectToAssociatedCars() {
    invokeMethod(connected_device_constants.CONNECT_TO_ASSOCIATED_CARS);
  }

  /// Clears an existing association.
  ///
  /// Wait for this method to finish before calling other methods that
  /// retrieve or update the association status, such as [fetchAssociatedCars].
  Future<void> clearAssociation(String carId) async => methodChannel
      .invokeMethod(connected_device_constants.CLEAR_ASSOCIATION, carId);

  /// Renames an associated car based on its id.
  ///
  /// Returns `true` if the rename was successful. This will not be successful
  /// if the `carId` does not correspond to an associated car.
  Future<bool> renameCar(String carId, String name) => invokeMethodWithCar(
      connected_device_constants.RENAME_CAR, Car(carId, name));

  /// Returns 'true' if the [car] is currently connected to phone.
  Future<bool> isCarConnected(Car car) =>
      invokeMethodWithCar(connected_device_constants.IS_CAR_CONNECTED, car);
}

/// Callbacks for events that occur during the association process.
abstract class AssociationCallback {
  /// Called when a pairing code is available and should be shown to the user.
  void onPairingCodeAvailable(String pairingCode);

  /// Called when association has been completed successfully.
  void onAssociationCompleted(Car car);

  /// Called when an unrecoverable error has occurred during association.
  void onAssociationError();
}

/// The possible connection states that an associated car can be in.
enum CarConnectionStatus {
  /// Indicates that the car and phone have discovered each other and are
  /// attempting to set up a secure communication channel.
  detected,

  /// Indicates that the car and phone have set up a secure communication
  /// channel.
  connected,

  /// Indicates that a car and phone have disconnected from each other.
  disconnected,
}

/// Callbacks for connection events.
abstract class ConnectionCallback {
  /// Called when the Bluetooth status has changed.
  void onBluetoothStateChanged(String state);

  /// Called when a car's connection status has changed to the indicated
  /// [status].
  void onCarConnectionStatusChange(String carId, CarConnectionStatus status);
}

/// Callbacks for discovery events.
abstract class DiscoveryCallback {
  /// Called when a new car that can be associated has been discovered.
  void onCarDiscovered(Car car);

  /// Called when an unrecoverable discovery error has occurred during
  /// association.
  /// Currently restart the bluetooth is the only recovery method.
  void onDiscoveryError();

  /// Called if the user cancels a discovery.
  void onDiscoveryCancelled();

  /// Called when a car is selected by the user and the association is started.
  void onAssociationStarted();
}

/// Listener for log files updates.
abstract class OnLogFilesUpdatedListener {
  /// Called when log files have updates.
  void onLogFilesUpdated();
}
