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

import android.Manifest.permission
import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat.requestPermissions
import androidx.core.content.ContextCompat.checkSelfPermission
import com.google.android.libraries.car.calendarsync.feature.CalendarSyncFeature
import com.google.android.libraries.car.connectionservice.FeatureManagerServiceBinder
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.UUID
import org.json.JSONArray
import java.lang.ClassCastException
import kotlin.collections.filterIsInstance

/**
 * CalendarSync Flutter Plugin to communicate with the Flutter TrustDeviceApp. Permissions are
 * platform specific and require a View to work, and are thus handled are handled in the plugin.
 */
class CalendarSyncMethodChannel(private val registrar: Registrar) : MethodCallHandler {
  private val calendarViewItemData: CalendarViewItemData =
    CalendarViewItemData(registrar.context().contentResolver)

  private var grantPermissionsResult: MethodChannel.Result? = null
  private var calendarSyncManager: CalendarSyncFeature? = null

  init {
    val serviceConnection: ServiceConnection = object : ServiceConnection {
      override fun onServiceConnected(name: ComponentName, service: IBinder) {
        val connectedDeviceService = (service as FeatureManagerServiceBinder).getService()
        calendarSyncManager = connectedDeviceService.getFeatureManager(CalendarSyncFeature::class.java)
      }

      override fun onServiceDisconnected(name: ComponentName) {
        calendarSyncManager = null
      }
    }

    registrar.context().bindService(
      ConnectedDeviceService.createIntent(registrar.context()),
      serviceConnection,
      Context.BIND_AUTO_CREATE
    )
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      CalendarSyncConstants.METHOD_HAS_PERMISSIONS -> result.success(hasPermissions())

      CalendarSyncConstants.METHOD_REQUEST_PERMISSIONS -> {
        if (grantPermissionsResult != null) {
          result.error(
            "ERROR_ALREADY_REQUESTING_PERMISSIONS",
            "A request for permissions is already running, please wait for it to finish before"
            + " making another request",
            null)
          return
        }
        grantPermissionsResult = result
        requestCalendarPermissions()
      }

      CalendarSyncConstants.METHOD_RETRIEVE_CALENDARS -> if (hasPermissions()) {
        val calendarList = calendarViewItemData.fetchCalendarViewItems()
        result.success(toJsonArrayString(calendarList))
      } else {
        result.error(
          "READ_CALENDAR_PERMISSION_NOT_GRANTED",
          "Permission to read calendar was not granted.",
          null)
      }

      CalendarSyncConstants.METHOD_DISABLE_CAR -> {
        carIdFromMethodCall(call)?.let {
          calendarSyncManager?.disableCar(UUID.fromString(it))
        }
        result.success(null)
      }

      CalendarSyncConstants.METHOD_ENABLE_CAR -> {
        carIdFromMethodCall(call)?.let {
          calendarSyncManager?.enableCar(UUID.fromString(it))
        }
        result.success(null)
      }

      CalendarSyncConstants.METHOD_IS_CAR_ENABLED -> {
        val carId = carIdFromMethodCall(call) ?: return result.success(null)
        result.success(calendarSyncManager?.isCarEnabled(UUID.fromString(carId)))
      }

      CalendarSyncConstants.METHOD_FETCH_CALENDAR_IDS_TO_SYNC -> {
        val carId = carIdFromMethodCall(call) ?: return result.success(emptyList<String>())
        val calendars = calendarSyncManager?.getCalendarIdsToSync(UUID.fromString(carId))
        result.success(calendars?.toList() ?: emptyList<String>())
      }

      CalendarSyncConstants.METHOD_STORE_CALENDAR_IDS_TO_SYNC -> {
        val rawCalendars = call.argument(CalendarSyncConstants.ARGUMENT_CALENDARS) as? Collection<*>
        val carId = call.argument(CalendarSyncConstants.ARGUMENT_CAR_ID) as? String
        if (rawCalendars == null || carId == null) {
          result.success(null)
          return
        }

        val calendarIds = rawCalendars.filterIsInstance<String>().toSet()
        calendarSyncManager?.setCalendarIdsToSync(calendarIds, UUID.fromString(carId))

        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  /**
   * Defaulting permission code used to 0 assuming no other permissions are requested at this
   * instant.
   */
  private fun  requestCalendarPermissions() {
    requestPermissions(registrar.activity(), arrayOf(permission.READ_CALENDAR), 0)
  }

  private fun hasPermissions(): Boolean {
    return checkSelfPermission(registrar.context(), permission.READ_CALENDAR) ==
      PackageManager.PERMISSION_GRANTED
  }

  private fun handlePermissionsRequest(permissions: Array<String>, grantResults: IntArray) {
    if (grantPermissionsResult == null) {
      Log.e(
        TAG,
        "grantPermissionsResult is null. handlePermissionsRequest shouldn't have been called.")
      return
    }

    var granted = true
    for (i in permissions.indices) {
      granted = granted && grantResults[i] == PackageManager.PERMISSION_GRANTED
    }
    grantPermissionsResult!!.success(granted)
    grantPermissionsResult = null
  }

  private fun carIdFromMethodCall(call: MethodCall): String? =
    try {
      call.argument(CalendarSyncConstants.ARGUMENT_CAR_ID)
    } catch (e: ClassCastException) {
      call.arguments()
    }


  /** Returns a string of [CalendarViewItem]s converted to a json array  */
  private fun toJsonArrayString(calendarList: List<CalendarViewItem>): String =
    JSONArray(calendarList.map { it.toJson() }).toString()

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CalendarSyncConstants.CHANNEL)
      val callHandler = CalendarSyncMethodChannel(registrar)
      channel.setMethodCallHandler(callHandler)

      // Assuming READ_CALENDAR is the only permission granted at this exact moment.
      registrar.addRequestPermissionsResultListener { _, permissions, grantResults ->
        callHandler.handlePermissionsRequest(permissions, grantResults)
        true
      }
    }

    private const val TAG = "CalendarSyncMethodChannel"
  }
}
