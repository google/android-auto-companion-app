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

import android.app.Notification
import android.content.Context
import android.content.Intent
import com.google.android.libraries.car.calendarsync.feature.CalendarSyncManager
import com.google.android.libraries.car.communication.messagingsync.MessagingSyncManager
import com.google.android.libraries.car.connectionservice.ConnectedDeviceBaseService
import com.google.android.libraries.car.trustagent.FeatureManager
import com.google.android.libraries.car.trusteddevice.TrustedDeviceManager

/** A service that creates all features offered by Companion Device. */
class ConnectedDeviceService : ConnectedDeviceBaseService() {

  override fun createFeatureManagers(): List<FeatureManager> =
    listOf(
      TrustedDeviceManager(context = this),
      CalendarSyncManager(context = this),
      MessagingSyncManager(context = this),
    )

  override fun onBind(intent: Intent): ServiceBinder {
    super.onBind(intent)
    return ServiceBinder()
  }

  inner class ServiceBinder : ConnectedDeviceBaseService.ServiceBinder() {
    override fun getService(): ConnectedDeviceService = this@ConnectedDeviceService
  }

  companion object {
    /** Creates an intent of [ConnectedDeviceService]. */
    @JvmStatic
    fun createIntent(context: Context) = Intent(context, ConnectedDeviceService::class.java)

    /**
     * Creates an intent of [ConnectedDeviceService] with a notification.
     *
     * The intent created is meant for starting this service. The notification will be posted when
     * the service receives a connected device, and canceled when no device is connected.
     */
    @JvmStatic
    fun createStartingIntent(context: Context, notification: Notification, notificationId: Int) =
      createIntent(context).apply {
        putExtra(EXTRA_FOREGROUND_NOTIFICATION, notification)
        putExtra(EXTRA_FOREGROUND_NOTIFICATION_ID, notificationId)
      }
  }
}
