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

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log

/**
 * Receives broadcast to start BLE scanning.
 */
class StartDiscoveryBroadcastReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context?, intent: Intent?) {
    if (context == null) {
      Log.i(TAG, "Context is null when receive broadcast")
      return
    }
    Log.i(TAG, "Received $intent")

    // Missing permission will prevent the service from starting. More context on b/191835245.
    if (PermissionController.isPermissionsGranted(context)) {
      context.startService(ConnectedDeviceService.createIntent(context))
    } else {
      Log.w(TAG, "Required permissions not granted. Cannot start service.")
    }
  }

  companion object {
    private const val TAG = "StartDiscovery"
  }
}
