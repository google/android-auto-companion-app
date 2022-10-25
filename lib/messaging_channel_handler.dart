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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'values/messaging_sync_constants.dart' as messaging_sync_constants;

/// Method Channel Handler for Messaging Sync.
class MessagingMethodChannelHandler {
  var _channel = MethodChannel(messaging_sync_constants.CHANNEL);
  Function _onMessagingSyncEnabled;
  Function _onFailureToEnableMessagingSync;

  MessagingMethodChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case messaging_sync_constants.ON_MESSAGING_SYNC_ENABLED_ROUTE:
          if (_onMessagingSyncEnabled != null) {
            _onMessagingSyncEnabled();
          }
          break;
        case messaging_sync_constants.ON_FAILURE_TO_ENABLE_MESSAGING_SYNC_ROUTE:
          if (_onFailureToEnableMessagingSync != null) {
            _onFailureToEnableMessagingSync();
          }
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  /// Checks if messaging sync feature is enabled.
  Future<bool> isMessagingSyncFeatureEnabled(String carId) async {
    return _channel.invokeMethod(
        messaging_sync_constants.IS_MESSAGING_SYNC_FEATURE_ENABLED, carId);
  }

  /// Enables messaging sync which goes through a variety of setup flow to
  /// enable messaging sync.
  void enableMessagingSync(
      String carId, Function onSuccess, Function onFailure) {
    _onMessagingSyncEnabled = onSuccess;
    _onFailureToEnableMessagingSync = onFailure;
    _channel.invokeMethod(
        messaging_sync_constants.ENABLE_MESSAGING_SYNC_FEATURE, carId);
  }

  /// Disables messaging sync for car id.
  void _disableMessagingSync(String carId) {
    _channel.invokeMethod(
        messaging_sync_constants.DISABLE_MESSAGING_SYNC_FEATURE, carId);
  }

  /// Helper method for enabling or disabling messaging sync feature.
  void setMessagingEnabled(String carId, bool enabled) {
    if (enabled) {
      enableMessagingSync(carId, null, null);
    } else {
      _disableMessagingSync(carId);
    }
  }

  @visibleForTesting
  void setMockMethodChannel(MethodChannel mockChannel) {
    _channel = mockChannel;
  }
}
