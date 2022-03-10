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

import android.app.ActivityManager
import android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
import android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.google.android.libraries.car.communication.messagingsync.MessagingSyncManager
import com.google.android.libraries.car.connectionservice.FeatureManagerServiceBinder
import com.google.automotive.companion.MessagingSyncConstants.DISABLE_MESSAGING_SYNC_FEATURE
import com.google.automotive.companion.MessagingSyncConstants.ENABLE_MESSAGING_SYNC_FEATURE
import com.google.automotive.companion.MessagingSyncConstants.IS_MESSAGING_SYNC_FEATURE_ENABLED
import com.google.automotive.companion.MessagingSyncConstants.ON_FAILURE_TO_ENABLE_MESSAGING_SYNC_ROUTE
import com.google.automotive.companion.MessagingSyncConstants.ON_MESSAGING_SYNC_ENABLED_ROUTE
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 *  Messaging Sync Method Channel to bridge Flutter app to native Android code
 */
class MessagingSyncMethodChannel(
  private val context: Context,
  lifecycle: Lifecycle,
  dartExecutor: DartExecutor
) : MethodChannel.MethodCallHandler, DefaultLifecycleObserver {
  private val methodChannel = MethodChannel(dartExecutor, MessagingSyncConstants.CHANNEL)
  private var messagingSyncManager: MessagingSyncManager? = null

  private val serviceConnection = object : ServiceConnection {
    override fun onServiceConnected(name: ComponentName, service: IBinder) {
      val binder = service as FeatureManagerServiceBinder
      val connectedDeviceService = binder.getService()
      messagingSyncManager = connectedDeviceService.getFeatureManager(MessagingSyncManager::class.java)
      messagingSyncManager = connectedDeviceService.getFeatureManager(MessagingSyncManager::class.java)
    }

    override fun onServiceDisconnected(name: ComponentName?) {
      messagingSyncManager = null
    }
  }

  init {
    lifecycle.addObserver(this)
    methodChannel.setMethodCallHandler(this)
    context.bindService(
      ConnectedDeviceService.createIntent(context),
      serviceConnection,
      Context.BIND_AUTO_CREATE
    )
  }

  override fun onDestroy(owner: LifecycleOwner) {
    context.unbindService(serviceConnection)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      IS_MESSAGING_SYNC_FEATURE_ENABLED -> isMessagingSyncFeatureEnabled(call, result)
      ENABLE_MESSAGING_SYNC_FEATURE -> enableMessagingSyncFeature(call)
      DISABLE_MESSAGING_SYNC_FEATURE -> disableMessagingSyncFeature(call)
    }
  }

  private fun isMessagingSyncFeatureEnabled(call: MethodCall, result: MethodChannel.Result) {
    val carId = call.arguments as? String ?: return result.success(false)
    result.success(messagingSyncManager?.isMessagingSyncEnabled(carId))
  }

  private fun enableMessagingSyncFeature(call: MethodCall) {
    val carId = call.arguments as? String ?: return
    val onSuccess = {
      moveToForeground()
      methodChannel.invokeMethod(ON_MESSAGING_SYNC_ENABLED_ROUTE, carId)
    }

    val onFailure = {
      moveToForeground()
      methodChannel.invokeMethod(ON_FAILURE_TO_ENABLE_MESSAGING_SYNC_ROUTE, carId)
    }
    messagingSyncManager?.enableMessagingSync(carId, onSuccess, onFailure)
  }

  private fun disableMessagingSyncFeature(call: MethodCall) {
    val carId = call.arguments as? String ?: return
    messagingSyncManager?.disableMessagingSync(carId)
  }

  private fun moveToForeground() {
    if (isForeground()) return
    val intent = Intent(context, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
    }
    context.startActivity(intent)
  }

  private fun isForeground(): Boolean {
    val appProcessInfo = ActivityManager.RunningAppProcessInfo()
    ActivityManager.getMyMemoryState(appProcessInfo)
    return appProcessInfo.importance == IMPORTANCE_FOREGROUND ||
           appProcessInfo.importance == IMPORTANCE_VISIBLE
  }
}
