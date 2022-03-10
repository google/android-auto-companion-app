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

import 'package:automotive_companion/car.dart';
import 'package:automotive_companion/values/connected_device_constants.dart'
    as connected_device_constants;
import 'package:flutter/services.dart';

/// Helper class which provide functions handling flutter method call with
/// input of certain format.
abstract class MethodChannelHandler {
  MethodChannel methodChannel;
  MethodChannelHandler(this.methodChannel);

  /// Call method on the native platform.
  void invokeMethod(String methodName, [String? parameters]) async {
    log('calling $methodName with parameter: $parameters');
    try {
      await methodChannel.invokeMethod<bool>(methodName, parameters);
    } on PlatformException catch (e) {
      log("Failed to invoke method: '${e.message}'.");
    }
  }

  /// Call native method with the given Car.
  /// Only apply to method which return a boolean value.
  Future<bool> invokeMethodWithCar(String methodName, Car car) async {
    log('calling $methodName with car: (${car.id}, ${car.name})');
    try {
      return await methodChannel.invokeMethod(methodName, carToMap(car));
    } on PlatformException catch (e) {
      log("Failed to invoke method: '${e.message}'.");
    }
    return false;
  }

  /// Changes a car object to a Map object to be passed over a method channel.
  Map<String, String> carToMap(Car car) => {
        connected_device_constants.CAR_ID_KEY: car.id,
        connected_device_constants.CAR_NAME_KEY: car.name
      };

  /// Converts the arguments on the given [MethodCall] to an analogous [Car].
  Car argumentsToCar(MethodCall call) => Car(
        call.arguments[connected_device_constants.CAR_ID_KEY],
        call.arguments[connected_device_constants.CAR_NAME_KEY],
      );
}
