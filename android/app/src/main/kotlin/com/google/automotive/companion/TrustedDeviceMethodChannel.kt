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
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.getSystemService
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.google.android.libraries.car.connectionservice.FeatureManagerServiceBinder
import com.google.android.libraries.car.trustagent.FeatureManager
import com.google.android.libraries.car.trusteddevice.TrustedDeviceFeature
import com.google.android.libraries.car.trusteddevice.TrustedDeviceFeature.EnrollmentError
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.time.Instant
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.runBlocking

/**
 * The flutter method channel used to transfer data between Flutter UI and Android library.
 */
class TrustedDeviceMethodChannel(
  private val context: Context,
  lifecycle: Lifecycle,
  dartExecutor: DartExecutor
) : MethodChannel.MethodCallHandler, DefaultLifecycleObserver {
  private val sharedPref = context.getSharedPreferences(SHARED_PREF, Context.MODE_PRIVATE)

  private val notificationManager: NotificationManager
  private val notificationIdCounter: AtomicInteger
  private var trustedDeviceFeature: TrustedDeviceFeature? = null

  // Maps device ID to a Car with that ID.
  private val methodChannel = MethodChannel(dartExecutor, TrustedDeviceConstants.CHANNEL)
  private val uiHandler = Handler(Looper.getMainLooper())

  private enum class UnlockStatus {
    // The status is not known
    UNKNOWN,

    // The unlock is in progress
    INPROGRESS,

    // The unlock was successful
    SUCCESS,

    // An error was encountered during the unlock process
    ERROR,
  }

  /** The possible errors that can result from a phone-initiated enrollment in trusted device. */
  private enum class TrustedDeviceEnrollmentError {
    UNKNOWN,
    CAR_NOT_CONNECTED,
    PASSCODE_NOT_SET,
  }

  private val serviceConnection = object : ServiceConnection {
    override fun onServiceConnected(name: ComponentName, service: IBinder) {
      val connectedDeviceService = (service as FeatureManagerServiceBinder).getService()

      trustedDeviceFeature =
        connectedDeviceService.getFeatureManager(TrustedDeviceFeature::class.java)?.apply {
          registerCallback(trustedDeviceCallback)
          isPasscodeRequired = true
        }
    }

    override fun onServiceDisconnected(name: ComponentName?) {
      trustedDeviceFeature?.unregisterCallback(trustedDeviceCallback)
      trustedDeviceFeature = null
    }
  }

  private val trustedDeviceCallback = TrustedDeviceCallback()

  private inner class TrustedDeviceCallback : TrustedDeviceFeature.Callback {
    override fun onEnrollmentRequested(carId: UUID) {}

    override fun onEnrollmentSuccess(carId: UUID, initiatedFromCar: Boolean) {
      val name = (trustedDeviceFeature as FeatureManager).getConnectedCarNameById(carId)

      if (initiatedFromCar) {
        pushTrustedDeviceEnrollmentNotification(name)
      }

      invokeMethodOnMainThread(
        TrustedDeviceConstants.ON_TRUST_AGENT_ENROLLMENT_COMPLETED,
        convertCarInfoToMap(carId.toString(), name)
      )
    }

    override fun onUnenroll(carId: UUID, initiatedFromCar: Boolean) {
      if (initiatedFromCar) {
        val name = (trustedDeviceFeature as FeatureManager).getConnectedCarNameById(carId)
        pushTrustedDeviceUnenrollmentNotification(name)
      }

      invokeMethodOnMainThread(
        TrustedDeviceConstants.ON_TRUST_AGENT_UNENROLLED,
        mapOf(ConnectedDeviceConstants.CAR_ID_KEY to carId.toString()),
      )
    }

    override fun onEnrollmentFailure(carId: UUID, error: EnrollmentError) {
      Log.e(TAG, "Encountered error during trusted device enrollment: error code $error")

      val convertedError = when (error) {
        EnrollmentError.PASSCODE_NOT_SET -> TrustedDeviceEnrollmentError.PASSCODE_NOT_SET
        EnrollmentError.CAR_NOT_CONNECTED -> TrustedDeviceEnrollmentError.CAR_NOT_CONNECTED
        else -> TrustedDeviceEnrollmentError.UNKNOWN
      }

      val arguments = convertCarInfoToMap(carId.toString(), name = "").toMutableMap().apply {
        put(
          TrustedDeviceConstants.TRUST_AGENT_ENROLLMENT_ERROR_KEY,
          convertedError.ordinal.toString()
        )
      }

      invokeMethodOnMainThread(TrustedDeviceConstants.ON_TRUST_AGENT_ENROLLMENT_ERROR, arguments)
    }

    override fun onUnlockingStarted(carId: UUID) {}

    override fun onUnlockingSuccess(carId: UUID) {
      Log.i(TAG, "Successfully unlocked car with id $carId")

      val name = (trustedDeviceFeature as FeatureManager).getConnectedCarNameById(carId)

      if (shouldShowUnlockNotification(carId)) {
        pushTrustedDeviceUnlockNotification(name)
      }

      invokeMethodOnMainThread(
        TrustedDeviceConstants.ON_UNLOCK_STATUS_CHANGED,
        convertUnlockStatusToMap(carId, UnlockStatus.SUCCESS)
      )
    }

    override fun onUnlockingFailure(carId: UUID) {
      invokeMethodOnMainThread(
        TrustedDeviceConstants.ON_UNLOCK_STATUS_CHANGED,
        convertUnlockStatusToMap(carId, UnlockStatus.ERROR)
      )
    }
  }

  /** Generates a notification ID. */
  private fun nextNotificationId(): Int {
    return notificationIdCounter.getAndIncrement()
  }

  private fun createTrustedDeviceNotificationChannel() {
    val channel = NotificationChannel(
      TRUSTED_DEVICE_NOTIFICATION_CHANNEL_ID,
      context.getString(R.string.trusted_device_notification_channel_name),
      NotificationManager.IMPORTANCE_DEFAULT
    )

    notificationManager.createNotificationChannel(channel)
  }

  private fun pushTrustedDeviceEnrollmentNotification(carName: String?) {
    val name = carName ?: TRUSTED_DEVICE_NOTIFICATION_DEFAULT_CAR_NAME
    pushNotification(
      title = context.getString(R.string.trusted_device_enrollment_notification_title),
      text = context.getString(R.string.trusted_device_enrollment_notification_text, name),
      notificationId = nextNotificationId()
    )
  }

  private fun pushTrustedDeviceUnenrollmentNotification(carName: String?) {
    val name = carName ?: TRUSTED_DEVICE_NOTIFICATION_DEFAULT_CAR_NAME
    pushNotification(
      title = context.getString(R.string.trusted_device_unenrollment_notification_title),
      text = context.getString(R.string.trusted_device_unenrollment_notification_text, name),
      notificationId = nextNotificationId()
    )
  }

  private fun pushTrustedDeviceUnlockNotification(carName: String?) {
    val name = carName ?: TRUSTED_DEVICE_NOTIFICATION_DEFAULT_CAR_NAME
    pushNotification(
      title = null,
      text = context.getString(R.string.trusted_device_unlock_notification_text, name),
      notificationId = nextNotificationId()
    )
  }

  private fun pushNotification(
    title: String?,
    text: String,
    notificationId: Int
  ) {
    // Open the application whenever the notification is pressed.
    val notificationIntent = createNotificationIntent(context)

    val pendingIntent = PendingIntent.getActivity(
      context,
      /* requestCode= */ 0,
      notificationIntent,
      PendingIntent.FLAG_IMMUTABLE
    )

    val notification = Notification.Builder(context, TRUSTED_DEVICE_NOTIFICATION_CHANNEL_ID)
      .setContentTitle(title)
      .setContentText(text)
      .setSmallIcon(R.drawable.ic_notification)
      .setShowWhen(true)
      .setContentIntent(pendingIntent)
      .setStyle(Notification.BigTextStyle().bigText(text))
      .setAutoCancel(true)
      .build()

    notificationManager.notify(notificationId, notification)
  }

  init {
    lifecycle.addObserver(this)
    methodChannel.setMethodCallHandler(this)
    context.bindService(
      ConnectedDeviceService.createIntent(context), serviceConnection, Context.BIND_AUTO_CREATE)
    notificationManager = context.getSystemService<NotificationManager>()!!
    createTrustedDeviceNotificationChannel()

    notificationIdCounter = AtomicInteger(context.foregroundServiceNotificationId + 1)
  }

  override fun onDestroy(owner: LifecycleOwner) {
    context.unbindService(serviceConnection)
    notificationManager.deleteNotificationChannel(TRUSTED_DEVICE_NOTIFICATION_CHANNEL_ID)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      TrustedDeviceConstants.ENROLL_TRUST_AGENT -> enrollTrustAgent(call)
      TrustedDeviceConstants.STOP_TRUST_AGENT_ENROLLMENT -> stopTrustAgentEnrollment(call)
      TrustedDeviceConstants.GET_UNLOCK_HISTORY -> getUnlockHistory(call, result)
      TrustedDeviceConstants.IS_TRUSTED_DEVICE_ENROLLED ->
        result.success(isTrustedDeviceEnrolled(call))
      TrustedDeviceConstants.OPEN_SECURITY_SETTINGS -> openSecuritySettings()
      TrustedDeviceConstants.SET_DEVICE_UNLOCK_REQUIRED ->
        setDeviceUnlockRequired(call)
      TrustedDeviceConstants.IS_DEVICE_UNLOCK_REQUIRED ->
        result.success(isDeviceUnlockRequired(call))
      TrustedDeviceConstants.SHOULD_SHOW_UNLOCK_NOTIFICATION ->
        result.success(shouldShowUnlockNotification(call))
      TrustedDeviceConstants.SET_SHOW_UNLOCK_NOTIFICATION -> setShowUnlockNotification(call)
      else -> result.notImplemented()
    }
  }

  private fun setDeviceUnlockRequired(call: MethodCall) {
    trustedDeviceFeature?.setDeviceUnlockRequired(
      call.argumentDeviceId,
      call.argumentIsDeviceUnlockRequired
    )
  }

  private fun isDeviceUnlockRequired(call: MethodCall): Boolean {
    return trustedDeviceFeature?.isDeviceUnlockRequired(call.argumentDeviceId) ?: true
  }

  private fun shouldShowUnlockNotification(call: MethodCall): Boolean {
    return shouldShowUnlockNotification(call.argumentDeviceId)
  }

  private fun shouldShowUnlockNotification(carId: UUID): Boolean =
    sharedPref.getBoolean(NEED_PUSH_UNLOCK_NOTIFICATION_KEY_PREFIX + carId.toString(), true)

  private fun setShowUnlockNotification(call: MethodCall) {
    val deviceId = call.argumentDeviceId
    val shouldShow = call.argumentShowShowUnlockNotification

    sharedPref
      .edit()
      .putBoolean(NEED_PUSH_UNLOCK_NOTIFICATION_KEY_PREFIX + deviceId, shouldShow)
      .apply()
  }

  private fun isTrustedDeviceEnrolled(call: MethodCall): Boolean {
    val deviceId = call.argumentDeviceId
    val manager = trustedDeviceFeature
    if (manager == null) {
      return false
    }
    return runBlocking { manager.isEnabled(deviceId) }
  }

  private fun enrollTrustAgent(call: MethodCall) {
    val deviceId = call.argumentDeviceId
    if (trustedDeviceFeature == null) {
      Log.e(TAG, "ENROLL_TRUST_AGENT: service has not been bound")
      return
    }
    trustedDeviceFeature?.enroll(deviceId)
  }

  private fun stopTrustAgentEnrollment(call: MethodCall) {
    if (trustedDeviceFeature == null) {
      Log.e(TAG, "STOP_ENROLL_TRUST_AGENT: Service has not been bound. Ignore.")
      return
    }
    val deviceId = call.argumentDeviceId
    runBlocking { trustedDeviceFeature?.stopEnrollment(deviceId) }
  }

  private fun getUnlockHistory(call: MethodCall, result: MethodChannel.Result) {
    val deviceId = call.argumentDeviceId

    if (trustedDeviceFeature == null) {
      Log.e(TAG, "GET_UNLOCK_HISTORY: Service has not been bound. Ignore.")
      return
    }
    val instants = runBlocking { trustedDeviceFeature?.getUnlockHistory(deviceId) }
    if (instants == null) {
      Log.e(TAG, "GET_UNLOCK_HISTORY: Unlock history of car: $deviceId is null")
      result.success(emptyList<Instant>())
      return
    }

    // create ISO8601 date format
    val iso8601Format = SimpleDateFormat(ISO_8601_DATE_FORMAT, Locale.US)
    iso8601Format.timeZone = TimeZone.getTimeZone("UTC")
    @Suppress("NewApi") // Date.from() is supported with Java8 desugaring
    result.success(instants.map { instant -> iso8601Format.format(Date.from(instant)) })
  }

  private fun openSecuritySettings() {
    context.startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
  }

  private fun convertUnlockStatusToMap(carId: UUID, unlockStatus: UnlockStatus) = mapOf(
    ConnectedDeviceConstants.CAR_ID_KEY to carId.toString(),
    TrustedDeviceConstants.UNLOCK_STATUS_KEY to unlockStatus.ordinal.toString()
  )

  private fun invokeMethodOnMainThread(methodName: String, args: Any = "") {
    uiHandler.post { methodChannel.invokeMethod(methodName, args) }
  }

  companion object {
    private const val TAG = "TrustedDeviceMethodChannel"

    // Default car name substitution in notification text.
    private const val TRUSTED_DEVICE_NOTIFICATION_DEFAULT_CAR_NAME = "your car"
    private const val TRUSTED_DEVICE_NOTIFICATION_CHANNEL_ID = "trusted_device_notification_channel"

    private const val SHARED_PREF =
      "com.google.android.apps.internal.auto.embedded.trusteddeviceapp.TrustedDeviceMethodChannel"

    /**
     * `SharedPreferences` key for if a notification should be shown for a car when it is unlocked.
     *
     * This value is appended to the car id to differentiate.
     */
    private const val NEED_PUSH_UNLOCK_NOTIFICATION_KEY_PREFIX = "need_push_unlock_notification_key"

    private const val ISO_8601_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm'Z'"
  }
}
