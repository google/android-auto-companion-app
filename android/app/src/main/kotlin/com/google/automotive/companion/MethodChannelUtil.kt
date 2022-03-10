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
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.content.getSystemService

/**
 * Retrieves the notification ID from resources.
 *
 * The value is specified by `R.integer.service_foreground_notification_id`.
 */
val Context.foregroundServiceNotificationId: Int
  get() = resources.getInteger(R.integer.service_foreground_notification_id)

/**
 * Creates a service foreground notification.
 *
 * Creates a notification channel specified by `R.string.service_foreground_notification_channel_id`
 * and `R.string.service_foreground_notification_channel_name`. The title and text of notification
 * is specified by `R.string.service_foreground_notification_title` and
 * `R.string.service_foreground_notification_text`. The notification opens the component specfied by
 * `R.string.service_foreground_notification_intent`.
 */
fun createForegroundServiceNotification(context: Context): Notification {
  val notificationManager = context.getSystemService<NotificationManager>()!!
  val notificationChannelId = context.getString(R.string.service_foreground_notification_channel_id)
  val notificationChannel =
    NotificationChannel(
      notificationChannelId,
      context.getString(R.string.service_foreground_notification_channel_name),
      NotificationManager.IMPORTANCE_LOW
    )
  notificationManager.createNotificationChannel(notificationChannel)

  // Open the application when the notification is pressed.
  val openApplicationIntent =
    PendingIntent.getActivity(
      context,
      /* requestCode= */ 0,
      createNotificationIntent(context),
      PendingIntent.FLAG_IMMUTABLE
    )

  return Notification.Builder(context, notificationChannelId)
    .setContentTitle(context.getString(R.string.service_foreground_notification_title))
    .setContentText(context.getString(R.string.service_foreground_notification_text))
    .setContentIntent(openApplicationIntent)
    .setSmallIcon(R.drawable.ic_service_notification)
    .build()
}

/**
 * Returns an [Intent] of the component that is specified by `R.string.notification_open_component`.
 */
fun createNotificationIntent(context: Context): Intent {
  val packageName = context.getPackageName()
  val componentSimpleName = context.getString(R.string.notification_open_component)
  // Using the full package+name because the notification wouldn't open the activity with a simple
  // name. Not sure why.
  val componentName = ComponentName(packageName, "$packageName.$componentSimpleName")

  return Intent().apply {
    component = componentName
    flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
  }
}

/** Opens the system's application details page. */
fun openApplicationDetailsSettings(context: Context) {
  // The following works for API Level 9 and above, the minimum API level of this app is 26.
  val packageName = context.applicationContext.packageName
  val intent =
    Intent().apply {
      action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
      data = Uri.parse("package:$packageName")
      flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
  context.startActivity(intent)
}

/** Opens the system's bluetooth settings page. */
fun openBluetoothSettings(context: Context) {
  context.startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
}
