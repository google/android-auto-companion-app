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
import 'values/trusted_device_constants.dart' as trusted_device_constants;
import 'values/connected_device_constants.dart' as connected_device_constants;
import 'car.dart';

/// This is a singleton method channel used to communicate between the Flutter
/// UI and phone's trust agent library. This method channel should be able to
/// call method in phone's library and also handle method calls from phone's
/// platform.
class TrustedDeviceManager extends MethodChannelHandler {
  final _trustAgentCallbacks = <TrustAgentCallback>[];
  TrustedDeviceManager()
      : super(MethodChannel(trusted_device_constants.CHANNEL)) {
    // Internally, the TrustedDeviceManager is the method handler.
    methodChannel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case trusted_device_constants.ON_TRUST_AGENT_ENROLLMENT_COMPLETED:
          for (final callback in _trustAgentCallbacks) {
            callback.onEnrollmentCompleted(argumentsToCar(call));
          }
          break;
        case trusted_device_constants.ON_TRUST_AGENT_ENROLLMENT_ERROR:
          final car = argumentsToCar(call);
          final error = int.parse(call.arguments[
              trusted_device_constants.TRUST_AGENT_ENROLLMENT_ERROR_KEY]);
          for (final callback in _trustAgentCallbacks) {
            callback.onEnrollmentError(car, EnrollmentError.values[error]);
          }
          break;
        case trusted_device_constants.ON_TRUST_AGENT_UNENROLLED:
          for (final callback in _trustAgentCallbacks) {
            callback.onUnenroll(
                call.arguments[connected_device_constants.CAR_ID_KEY]);
          }
          break;
        case trusted_device_constants.ON_UNLOCK_STATUS_CHANGED:
          // The status is passed as a String. Convert to an int and index to
          // get the right enum value.
          final unlockStatus = UnlockStatus.values[int.parse(
              call.arguments[trusted_device_constants.UNLOCK_STATUS_KEY])];
          for (final callback in _trustAgentCallbacks) {
            callback.onUnlockStatusChanged(
                call.arguments[connected_device_constants.CAR_ID_KEY],
                unlockStatus);
          }
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  /// Register the trusted device callbacks when there are updated during the
  /// unlock process.
  void registerTrustAgentCallback(TrustAgentCallback callback) {
    _trustAgentCallbacks.add(callback);
  }

  /// Unregister the trusted device callbacks to stop listening to trusted
  /// device related events.
  void unregisterTrustAgentCallback(TrustAgentCallback callback) {
    _trustAgentCallbacks.remove(callback);
  }

  /// Opens system security setting of native platform.
  void openSecuritySettings() {
    invokeMethod(trusted_device_constants.OPEN_SECURITY_SETTINGS);
  }

  /// Enrolls the given car with the trust agent feature.
  void enrollTrustAgent(Car car) {
    invokeMethodWithCar(trusted_device_constants.ENROLL_TRUST_AGENT, car);
  }

  /// Clears enrollment data of the [car] with the trust agent feature.
  void stopTrustAgentEnrollment(Car car) {
    invokeMethodWithCar(
        trusted_device_constants.STOP_TRUST_AGENT_ENROLLMENT, car);
  }

  /// Gets the unlock history for a car, sorted from oldest to newest.
  ///
  /// Returns an empty list if the car has no unlock history, including if it's
  /// a car that hasn't been associated to this device.
  Future<List<DateTime>> fetchUnlockHistory(Car car) async {
    try {
      final unlockHistory = await methodChannel.invokeListMethod<dynamic>(
          trusted_device_constants.GET_UNLOCK_HISTORY, carToMap(car));
      return unlockHistory.map((m) => DateTime.parse(m).toLocal()).toList();
    } on PlatformException catch (e) {
      log("Failed to fetch associated cars with error: '${e.message}'.");
      return <DateTime>[];
    }
  }

  /// Returns 'true' if the [car] has been enrolled as a trusted device.
  Future<bool> isTrustedDeviceEnrolled(Car car) => invokeMethodWithCar(
      trusted_device_constants.IS_TRUSTED_DEVICE_ENROLLED, car);

  /// Returns whether the phone needs to be unlocked first to unlock the profile
  /// on the [car].
  Future<bool> isDeviceUnlockRequired(Car car) => invokeMethodWithCar(
      trusted_device_constants.IS_DEVICE_UNLOCK_REQUIRED, car);

  /// Sets whether the phone needs to be unlocked first to unlock the profile on
  /// the car.
  void setDeviceUnlockRequired(Car car, bool isRequired) => methodChannel
          .invokeMethod(trusted_device_constants.SET_DEVICE_UNLOCK_REQUIRED, {
        connected_device_constants.CAR_ID_KEY: car.id,
        connected_device_constants.CAR_NAME_KEY: car.name,
        trusted_device_constants.IS_DEVICE_UNLOCK_REQUIRED_KEY:
            isRequired.toString()
      });

  /// Returns `true` if the phone needs to show notification after unlocking the
  /// profile on the [car].
  Future<bool> shouldShowUnlockNotification(Car car) => invokeMethodWithCar(
      trusted_device_constants.SHOULD_SHOW_UNLOCK_NOTIFICATION, car);

  /// Sets whether the phone needs to show notification after unlocking the
  /// profile on the [car].
  void setShowUnlockNotification(Car car, bool shouldShow) => methodChannel
          .invokeMethod(trusted_device_constants.SET_SHOW_UNLOCK_NOTIFICATION, {
        connected_device_constants.CAR_ID_KEY: car.id,
        connected_device_constants.CAR_NAME_KEY: car.name,
        trusted_device_constants.SHOULD_SHOW_UNLOCK_NOTIFICATION_KEY:
            shouldShow.toString()
      });
}

// LINT.IfChange
enum UnlockStatus {
  /// The status is not known
  unknown,

  /// The unlock is in progress
  inProgress,

  /// The unlock was successful
  success,

  /// An error was encountered during the unlock process
  error,
}

/// The possible errors that can result from a phone-initiated enrollment in
/// trusted device.
enum EnrollmentError {
  unknown,
  carNotConnected,
  passcodeNotSet,
}

/// Callbacks for events related to the trust agent.
abstract class TrustAgentCallback {
  /// Called when trust agent enrollment has completed for the specified [car].
  ///
  /// After completion, the current device will be able to unlock the head unit.
  void onEnrollmentCompleted(Car car);

  /// Called when the specified [car] has encountered an error during trust
  /// agent enrollment.
  void onEnrollmentError(Car car, EnrollmentError error);

  /// Called when the car with the given [carId] has been un-enrolled from the
  /// trusted device feature.
  ///
  /// The user will be required to re-enroll to utilize the trusted device
  /// feature.
  void onUnenroll(String carId);

  /// Called when the unlock status of a remote car has changed.
  void onUnlockStatusChanged(String carId, UnlockStatus status);
}
