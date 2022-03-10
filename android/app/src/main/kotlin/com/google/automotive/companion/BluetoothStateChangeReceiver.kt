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

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receiver that listens for changes in the Bluetooth adapter state.
 *
 * Filters the BluetoothAdapter state changes for the [BluetoothState] that Flutter understands.
 *
 * Must be registered for [BluetoothAdapter.ACTION_STATE_CHANGED].
 *
 * @property onBluetoothStateChanged A callback with the current BT state.
 */
class BluetoothStateChangeReceiver(private val onBluetoothStateChanged: (BluetoothState) -> Unit) :
  BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != BluetoothAdapter.ACTION_STATE_CHANGED) {
      Log.e(TAG, "Received intent that does not contain Bluetooth state. Ignoring.")
      return
    }

    val bluetoothState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)

    BluetoothState.fromBluetoothAdapterState(bluetoothState)?.let { onBluetoothStateChanged(it) }
  }

  companion object {
    private const val TAG = "BluetoothStateChangeReceiver"
  }
}

/** The known bluetooth states that the flutter application understands. */
enum class BluetoothState {
  ERROR,
  ON,
  OFF;

  companion object {
    /**
     * Converts a [BluetoothAdapter] state constant to a [BluetoothState].
     *
     * Returns `null` if the state is unsupported.
     */
    internal fun fromBluetoothAdapterState(bluetoothState: Int): BluetoothState? {
      return when (bluetoothState) {
        BluetoothAdapter.ERROR -> BluetoothState.ERROR
        BluetoothAdapter.STATE_ON -> BluetoothState.ON
        BluetoothAdapter.STATE_OFF -> BluetoothState.OFF

        // All other states should not map to anything because they do not need to be conveyed
        // back to the flutter app.
        else -> null
      }
    }
  }
}
