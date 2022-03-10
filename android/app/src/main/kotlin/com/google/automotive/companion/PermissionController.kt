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

import android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
import android.Manifest.permission.ACCESS_FINE_LOCATION
import android.Manifest.permission.BLUETOOTH_CONNECT
import android.Manifest.permission.BLUETOOTH_SCAN
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

/** Manages the permissions needed for each API level. */
object PermissionController {
  private const val TAG = "PermissionController"

  /** Required platform runtime permissions based on current API level. */
  val requiredPermissions: List<String> =
    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
      listOf(ACCESS_FINE_LOCATION)
    } else if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
      listOf(ACCESS_FINE_LOCATION, ACCESS_BACKGROUND_LOCATION)
    } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.S) {
      Log.w(TAG, "returning connect and scan.")
      listOf(BLUETOOTH_CONNECT, BLUETOOTH_SCAN)
    } else {
      Log.e(TAG, "Unsupported API level, return empty list of required permissions.")
      emptyList()
    }

  /** Returns `true` if all the [requiredPermissions] are granted, otherwise returns `false`. */
  fun isPermissionsGranted(context: Context): Boolean =
    requiredPermissions.all {
      ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }
}
