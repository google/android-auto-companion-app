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
import android.app.AlertDialog
import android.app.Dialog
import android.content.DialogInterface
import android.content.Intent
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.fragment.app.DialogFragment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * Main activity that handles the set up of method channels for communication with the
 * `ConnectedDeviceManager` library.
 *
 * When started, this activity wil request the location permission, which is required for BLE
 * operations.
 */
class MainActivity: FlutterFragmentActivity() {
  private lateinit var methodChannel: ConnectedDeviceMethodChannel
  private lateinit var trustedDeviceMethodChannel: TrustedDeviceMethodChannel
  private lateinit var messageSyncMethodChannel: MessagingSyncMethodChannel

  // Permissions necessary to use Companion Device APIs.
  private val requiredPermissions = PermissionController.requiredPermissions

  private val connectedDeviceManagerCallback =
    ConnectedDeviceMethodChannel.Callback {
      startIntentSenderForResult(
        /* intent= */ it,
        /* requestCode= */ SELECT_DEVICE_REQUEST_CODE,
        /* fillInIntent= */ null,
        /* flagsMask= */ 0,
        /* flagsValues= */ 0,
        /* extraFlags= */ 0
      )
    }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    Log.i(TAG, "onCreate")
    checkPermissions()
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    methodChannel = ConnectedDeviceMethodChannel(this, lifecycle, flutterEngine.dartExecutor).apply {
      callback = connectedDeviceManagerCallback
    }
    trustedDeviceMethodChannel =
      TrustedDeviceMethodChannel(this, lifecycle, flutterEngine.dartExecutor)
    messageSyncMethodChannel =
      MessagingSyncMethodChannel(this, lifecycle, flutterEngine.dartExecutor)

    val shim = ShimPluginRegistry(flutterEngine)
    CalendarSyncMethodChannel.registerWith(shim.registrarFor("google.calendarsync"))
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    when (requestCode) {
      SELECT_DEVICE_REQUEST_CODE -> handleSelectDeviceRequest(resultCode, data)
      else -> Log.i(TAG, "onActivityResult received $requestCode. Ignored.")
    }
  }

  private fun handleSelectDeviceRequest(resultCode: Int, data: Intent?) {
    if (resultCode != RESULT_OK) {
      Log.e(TAG, "SELECT_DEVICE_REQUEST_CODE received non-OK resultCode $resultCode.")
      if (resultCode == RESULT_CANCELED) {
        Log.d(TAG, "Notifying method channel that the discovery is cancelled.")
        (methodChannel as? ConnectedDeviceMethodChannel)?.onAssociationDiscoveryCancelled()
      }
      return
    }
    if (data == null) {
      Log.e(TAG, "SELECT_DEVICE_REQUEST_CODE received null data. Ignored.")
      return
    }
    (methodChannel as? ConnectedDeviceMethodChannel)?.associateDevice(data)
  }

  private fun checkPermissions() {
    if (requiredPermissions.any { checkSelfPermission(it) != PERMISSION_GRANTED }) {
      if (
        requiredPermissions.any {
          ActivityCompat.shouldShowRequestPermissionRationale(this, it)
        }
      ) {
        showPermissionRationale()
      } else {
        requestPermissions(requiredPermissions.toTypedArray(), PERMISSION_REQUEST_CODE)
      }
    }
  }

  private fun showPermissionRationale() {
    PermissionRationaleDialogFragment().run {
      listener = PermissionRationaleDialogFragment.OnDismissListener {
        this@MainActivity.requestPermissions(
          requiredPermissions.toTypedArray(),
          PERMISSION_REQUEST_CODE
        )
      }
      show(supportFragmentManager, PERMISSION_DIALOG_TAG)
    }
  }

  companion object {
    private const val TAG = "MainActivity"
    private const val PERMISSION_DIALOG_TAG = "permission_dialog_tag"
    private const val PERMISSION_REQUEST_CODE = 1
    private const val SELECT_DEVICE_REQUEST_CODE = 2
  }
}

/** A dialog fragment that displays the rationale for requesting permission. */
class PermissionRationaleDialogFragment() : DialogFragment() {
  internal var listener: OnDismissListener? = null

  override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
    return activity?.let {
      // Use the Builder class for convenient dialog construction
      with(AlertDialog.Builder(it)) {
        setMessage(R.string.permission_dialog_rationale)
        // No-op because clicking button automatically dismisses the dialog.
        setNeutralButton(R.string.ok) { _, _ -> }
        create()
      }
    } ?: throw IllegalStateException("Activity cannot be null")
  }

  override fun onDismiss(dialog: DialogInterface) {
    super.onDismiss(dialog)
    listener?.onDismiss()
  }

  fun interface OnDismissListener {
    fun onDismiss()
  }
}
