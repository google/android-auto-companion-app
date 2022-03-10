// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Constants for mapping methods across the flutter `MethodChannel`.
///
/// This file is auto-generated.
enum TrustedDeviceConstants {
  static let channel = "google.gas.batmobile.trusteddevice/method"
  static let openSecuritySettings = "openSecuritySettings"
  static let onUnlockStatusChanged = "onUnlockStatusChanged"
  static let onTrustAgentEnrollmentCompleted = "onTrustAgentEnrollmentCompleted"
  static let onTrustAgentUnenrolled = "onTrustAgentUnenrolled"
  static let onTrustAgentEnrollmentError = "onTrustAgentEnrollmentError"
  static let enrollTrustAgent = "enrollTrustAgent"
  static let stopTrustAgentEnrollment = "stopTrustAgentEnrollment"
  static let trustAgentEnrollmentErrorKey = "trustAgentEnrollmentErrorKey"
  static let unlockStatusKey = "unlockStatusKey"
  static let getUnlockHistory = "getUnlockHistory"
  static let isTrustedDeviceEnrolled = "isTrustedDeviceEnrolled"
  static let setDeviceUnlockRequired = "setDeviceUnlockRequired"
  static let isDeviceUnlockRequired = "isDeviceUnlockRequired"
  static let isDeviceUnlockRequiredKey = "isDeviceUnlockRequiredKey"
  static let shouldShowUnlockNotification = "shouldShowUnlockNotification"
  static let shouldShowUnlockNotificationKey = "shouldShowUnlockNotificationKey"
  static let setShowUnlockNotification = "setShowUnlockNotification"
}
