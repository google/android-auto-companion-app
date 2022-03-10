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
 * Constants for mapping messaging sync methods across the flutter `MethodChannel`.
 *
 * This file is auto-generated.
 */
object MessagingSyncConstants {
  const val CHANNEL = "google.gas.batmobile.trusteddevice.messaging_sync/method"
  const val IS_MESSAGING_SYNC_FEATURE_ENABLED = "isMessagingSyncFeatureEnabled"
  const val ENABLE_MESSAGING_SYNC_FEATURE = "enableMessagingSyncFeature"
  const val DISABLE_MESSAGING_SYNC_FEATURE = "disableMessagingSyncFeature"
  const val ON_FAILURE_TO_ENABLE_MESSAGING_SYNC_ROUTE = "onFailureToEnableMessagingSyncRoute"
  const val ON_MESSAGING_SYNC_ENABLED_ROUTE = "onMessagingSyncEnabledRoute"
}
