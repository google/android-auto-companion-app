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

/**
 * Constants for mapping methods across the flutter `MethodChannel` for the trusted device
 * feature.
 *
 * This file is auto-generated.
 */
object TrustedDeviceConstants {
  const val CHANNEL = "google.gas.batmobile.trusteddevice/method"
  const val OPEN_SECURITY_SETTINGS = "openSecuritySettings"
  const val ON_UNLOCK_STATUS_CHANGED = "onUnlockStatusChanged"
  const val ON_TRUST_AGENT_ENROLLMENT_COMPLETED = "onTrustAgentEnrollmentCompleted"
  const val ON_TRUST_AGENT_UNENROLLED = "onTrustAgentUnenrolled"
  const val ON_TRUST_AGENT_ENROLLMENT_ERROR = "onTrustAgentEnrollmentError"
  const val ENROLL_TRUST_AGENT = "enrollTrustAgent"
  const val STOP_TRUST_AGENT_ENROLLMENT = "stopTrustAgentEnrollment"
  const val TRUST_AGENT_ENROLLMENT_ERROR_KEY = "trustAgentEnrollmentErrorKey"
  const val UNLOCK_STATUS_KEY = "unlockStatusKey"
  const val GET_UNLOCK_HISTORY = "getUnlockHistory"
  const val IS_TRUSTED_DEVICE_ENROLLED = "isTrustedDeviceEnrolled"
  const val SET_DEVICE_UNLOCK_REQUIRED = "setDeviceUnlockRequired"
  const val IS_DEVICE_UNLOCK_REQUIRED = "isDeviceUnlockRequired"
  const val IS_DEVICE_UNLOCK_REQUIRED_KEY = "isDeviceUnlockRequiredKey"
  const val SHOULD_SHOW_UNLOCK_NOTIFICATION = "shouldShowUnlockNotification"
  const val SHOULD_SHOW_UNLOCK_NOTIFICATION_KEY = "shouldShowUnlockNotificationKey"
  const val SET_SHOW_UNLOCK_NOTIFICATION = "setShowUnlockNotification"
}
