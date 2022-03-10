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

import android.app.Activity
import androidx.lifecycle.DefaultLifecycleObserver
import android.bluetooth.BluetoothAdapter
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.IntentSender
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.coroutineScope
import com.google.android.libraries.car.trustagent.AssociatedCar
import com.google.android.libraries.car.trustagent.AssociationRequest
import com.google.android.libraries.car.trustagent.ConnectedDeviceManager
import com.google.android.libraries.car.trustagent.DiscoveryRequest
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch

/**
 * The flutter method channel used to transfer connection related data between Flutter UI and
 * Android library.
 */
class ConnectedDeviceMethodChannel(
  private val contextActivity: Activity,
  lifecycle: Lifecycle,
  dartExecutor: DartExecutor
) : MethodChannel.MethodCallHandler, DefaultLifecycleObserver {

  var callback: Callback? = null

  private val coroutineScope = lifecycle.coroutineScope
  private val methodChannel = MethodChannel(dartExecutor, ConnectedDeviceConstants.CHANNEL)
  private val uiHandler = Handler(Looper.getMainLooper())

  private var connectedDeviceManager: ConnectedDeviceManager? = null
  private var connectedDeviceManagerContinuation: Continuation<ConnectedDeviceManager>? = null

  private val serviceConnection =
    object : ServiceConnection {
      override fun onServiceConnected(name: ComponentName, service: IBinder) {
        val binder = service as ConnectedDeviceService.ServiceBinder
        val manager =
          binder.getService().connectedDeviceManager.apply {
            registerCallback(connectionDeviceManagerCallback)
          }
        connectedDeviceManager = manager
        Log.i(TAG, "onServiceConnected: retrieved connectedDeviceManager")
        connectedDeviceManagerContinuation?.resume(manager)
        connectedDeviceManagerContinuation = null
      }

      override fun onServiceDisconnected(name: ComponentName?) {
        connectedDeviceManager?.unregisterCallback(connectionDeviceManagerCallback)
        connectedDeviceManager = null
        Log.i(TAG, "onServiceDisconnected: set connectedDeviceManager to null")
      }
    }

  private val connectionDeviceManagerCallback =
    object : ConnectedDeviceManager.Callback {
      override fun onAssociationStart() {}

      override fun onDeviceDiscovered(chooserLauncher: IntentSender) {
        Log.i(TAG, "onDeviceDiscovered")
        callback?.onDeviceDiscovered(chooserLauncher)
      }

      override fun onDiscoveryFailed() {
        Log.i(TAG, "onDiscoveryFailed")
        invokeMethodOnMainThread(ConnectedDeviceConstants.ON_DISCOVERY_ERROR)
      }

      override fun onAuthStringAvailable(authString: String) {
        Log.i(TAG, "onAuthStringAvailable: $authString.")
        invokeMethodOnMainThread(
          ConnectedDeviceConstants.ON_PAIRING_CODE_AVAILABLE,
          mapOf(ConnectedDeviceConstants.PAIRING_CODE_KEY to authString)
        )
      }

      override fun onAssociated(associatedCar: AssociatedCar) {
        Log.i(TAG, "onAssociated: ${associatedCar.deviceId}.")
        invokeMethodOnMainThread(
          ConnectedDeviceConstants.ON_ASSOCIATION_COMPLETED,
          associatedCar.toMap()
        )
      }

      override fun onAssociationFailed() {
        Log.i(TAG, "onAssociationFailed")
        invokeMethodOnMainThread(ConnectedDeviceConstants.ON_ASSOCIATION_ERROR)
      }

      override fun onConnected(associatedCar: AssociatedCar) {
        Log.i(TAG, "onConnected: ${associatedCar.deviceId}.")
        invokeMethodOnMainThread(
          ConnectedDeviceConstants.ON_CAR_CONNECTION_STATUS_CHANGE,
          CarConnectionStatus.CONNECTED.toMapWithCarId(associatedCar.deviceId)
        )
      }

      override fun onDisconnected(associatedCar: AssociatedCar) {
        Log.i(TAG, "onDisconnected: ${associatedCar.deviceId}.")
        invokeMethodOnMainThread(
          ConnectedDeviceConstants.ON_CAR_CONNECTION_STATUS_CHANGE,
          CarConnectionStatus.DISCONNECTED.toMapWithCarId(associatedCar.deviceId)
        )
      }
    }

  private val bluetoothStateChangeReceiver =
    BluetoothStateChangeReceiver() { bluetoothState ->
      Log.i(TAG, "Bluetooth state changed to $bluetoothState.")

      val bluetoothStateString = bluetoothState.ordinal.toString()
      invokeMethodOnMainThread(
        ConnectedDeviceConstants.ON_STATE_CHANGED,
        hashMapOf(ConnectedDeviceConstants.CONNECTION_MANAGER_STATE_KEY to bluetoothStateString)
      )
    }

  init {
    methodChannel.setMethodCallHandler(this)
    lifecycle.addObserver(this)

    contextActivity.startService(createConnectedDeviceServiceIntent(contextActivity))
  }

  override fun onCreate(owner: LifecycleOwner) {
    contextActivity.bindService(
      ConnectedDeviceService.createIntent(contextActivity),
      serviceConnection,
      Context.BIND_AUTO_CREATE
    )

    contextActivity.registerReceiver(
      bluetoothStateChangeReceiver,
      IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
    )
  }

  override fun onDestroy(owner: LifecycleOwner) {
    contextActivity.unbindService(serviceConnection)
    contextActivity.unregisterReceiver(bluetoothStateChangeReceiver)
    connectedDeviceManager?.unregisterCallback(connectionDeviceManagerCallback)
  }

  /**
   * [connectedDeviceManager] is retrieved by binding to the service. If the property is accessed
   * before the service binding, the field will be null. This suspend fun provides a guaranteed
   * non-null access.
   *
   * NOTE: Do not block waiting for this method on the main thread. If the service is not bound yet,
   * block waiting will keep the main thread from handling the service connection callback, leading
   * to ANR.
   */
  private suspend fun getConnectedDeviceManager(): ConnectedDeviceManager {
    return connectedDeviceManager
      ?: suspendCoroutine<ConnectedDeviceManager> { connectedDeviceManagerContinuation = it }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    Log.i(TAG, "onMethodCall: ${call.method}")
    when (call.method) {
      ConnectedDeviceConstants.IS_BLUETOOTH_ENABLED -> isBluetoothEnabled(result)
      ConnectedDeviceConstants.IS_CAR_CONNECTED -> isCarConnected(call, result)
      ConnectedDeviceConstants.IS_BLUETOOTH_PERMISSION_GRANTED ->
        isBluetoothPermissionGranted(result)
      ConnectedDeviceConstants.SCAN_FOR_CARS_TO_ASSOCIATE -> scanForCarsToAssociate(call)
      ConnectedDeviceConstants.GET_ASSOCIATED_CARS -> retrieveAssociatedCars(result)
      ConnectedDeviceConstants.GET_CONNECTED_CARS -> retrieveConnectedCars(result)
      ConnectedDeviceConstants.CLEAR_CURRENT_ASSOCIATION -> clearCurrentAssociation()
      ConnectedDeviceConstants.CLEAR_ASSOCIATION -> clearAssociation(call, result)
      ConnectedDeviceConstants.RENAME_CAR -> renameCar(call, result)
      ConnectedDeviceConstants.OPEN_APPLICATION_DETAILS_SETTINGS ->
        openApplicationDetailsSettings(contextActivity)
      ConnectedDeviceConstants.OPEN_BLUETOOTH_SETTINGS -> openBluetoothSettings(contextActivity)
      else -> result.notImplemented()
    }
  }

  private fun renameCar(call: MethodCall, result: MethodChannel.Result) {
    coroutineScope.launch {
      result.success(
        getConnectedDeviceManager().renameCar(call.argumentDeviceId, call.argumentName)
      )
    }
  }

  private fun isBluetoothPermissionGranted(result: MethodChannel.Result) {
    result.success(PermissionController.isPermissionsGranted(contextActivity))
  }

  private fun isBluetoothEnabled(result: MethodChannel.Result) {
    coroutineScope.launch { result.success(getConnectedDeviceManager().isBluetoothEnabled) }
  }

  private fun isCarConnected(call: MethodCall, result: MethodChannel.Result) {
    coroutineScope.launch {
      val deviceId = call.argumentDeviceId
      result.success(getConnectedDeviceManager().connectedCars.any { it.deviceId == deviceId })
    }
  }

  private fun scanForCarsToAssociate(call: MethodCall) {
    coroutineScope.launch {
      val request = with(DiscoveryRequest.Builder(contextActivity)) {
        namePrefix = call.arguments as String
        build()
      }
      getConnectedDeviceManager().startDiscovery(request)
    }
  }

  private fun retrieveAssociatedCars(result: MethodChannel.Result) {
    coroutineScope.launch {
      val associatedCars =
        getConnectedDeviceManager().let { it.retrieveAssociatedCars().get().map { it.toMap() } }

      result.success(associatedCars)
    }
  }

  private fun retrieveConnectedCars(result: MethodChannel.Result) {
    coroutineScope.launch {
      result.success(getConnectedDeviceManager().connectedCars.map { it.toMap() })
    }
  }

  private fun clearCurrentAssociation() {
    coroutineScope.launch { getConnectedDeviceManager().clearCurrentAssociation() }
  }

  private fun clearAssociation(call: MethodCall, result: MethodChannel.Result) {
    coroutineScope.launch {
      val deviceId = UUID.fromString(call.arguments as String)

      getConnectedDeviceManager().disassociate(deviceId).await()
      result.success(null)
    }
  }

  private fun invokeMethodOnMainThread(methodName: String, args: Any = "") {
    uiHandler.post { methodChannel.invokeMethod(methodName, args) }
  }

  fun interface Callback {
    /**
     * Invoked when a companion device has been discovered.
     *
     * `chooserLauncher` should be launched by `startIntentSenderForResult`.
     */
    fun onDeviceDiscovered(chooserLauncher: IntentSender)
  }

  /** Associates the device contained by `Intent` passed to `onActivityResult`. */
  fun associateDevice(data: Intent) {
    val request = AssociationRequest.Builder(data).build()
    connectedDeviceManager?.associate(request)
    // Make the callback here instead of in the CDM callback so that the app will navigate
    // to the next page directly after the user has selected a device in CDM dialog.
    invokeMethodOnMainThread(ConnectedDeviceConstants.ON_ASSOCIATION_STARTED)
  }

  /** Informs the UI that the discovery dialog is cancelled by the user. */
  fun onAssociationDiscoveryCancelled() {
    invokeMethodOnMainThread(ConnectedDeviceConstants.ON_ASSOCIATION_DISCOVERY_CANCELLED)
  }

  companion object {
    private const val TAG = "ConnectedDeviceMethodChannel"

    /** Creates an intent of [ConnectedDeviceService] that posts a notification when connected. */
    private fun createConnectedDeviceServiceIntent(context: Context) =
      ConnectedDeviceService.createStartingIntent(
        context,
        createForegroundServiceNotification(context),
        context.foregroundServiceNotificationId
      )
  }
}
