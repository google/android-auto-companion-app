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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The localizations used in this application.
///
/// All strings that are shown in the UI should be defined here and then
/// retrieved from a [LocalizationsDelegate].
abstract class StringLocalizations {
  String get appBarBackLabel;
  String get startButtonLabel;
  String get cancelButtonLabel;
  String get doneButtonLabel;

  String get needsBluetoothWarning;
  String get bluetoothWarningTitle;
  String get bluetoothWarningExplanation;
  String get alertDialogOkButton;

  String versionNumberLabel(String versionNumber);

  // Welcome page.
  String get welcomeTitle;
  String get welcomeContent;
  String get trustedDeviceShortExplanation;
  String get calendarSyncShortExplanation;
  String get messengerSyncShortExplanation;
  String get bluetoothRequirementExplanation;
  String get getStartedButtonLabel;

  // Passcode not set alert dialog
  String get passcodeAlertDialogTitle;
  String get passcodeAlertDialogContent;
  String get openSettingsLabel;

  // Bluetooth permission not granted alert dialog
  String get bluetoothPermissionAlertDialogTitleIos;
  String get bluetoothPermissionAlertDialogContentIos;
  String get bluetoothPermissionAlertDialogTitleAndroid;
  String get bluetoothPermissionAlertDialogContentAndroid;
  String get bluetoothPermissionAlertDialogTitleAndroidBeforeSdk29;
  String get bluetoothPermissionAlertDialogContentAndroidBeforeSdk29;

  // Home page title.
  String get trustedDeviceTitle;
  String get trustedDeviceExplanation;

  // Looking for car page.
  String get associationNamePrefix;
  String get lookingForCarTitle;
  String get lookingForCarExplanation;
  String get lookingForCarProgress;
  String get restartBluetoothDialogTitle;
  String get restartBluetoothDialogContent;

  // One car found page.
  String vehicleFoundTitle(String name);
  String get connectConfirmationExplanation;
  String get notMyCarButtonLabel;
  String get connectButtonLabel;

  // Select car page title.
  String get selectCarTitle;
  String get selectCarExplanation;
  String get selectCarListTitle;
  String get refreshCarListButtonLabel;

  // Connecting page
  String get connectingCarTitle;
  String get connectionRetryExplanation;
  String get connectionRetryButton;

  // Association error dialog
  String get associationErrorDialogTitle;
  String get associationErrorDialogBody;
  String get associationErrorDialogConfirmButton;

  // Pairing code page
  String get pairingCodeTitle;
  String get pairingCodeExplanation;

  // Rename car page
  String get renamePageTitle;
  String get saveButtonLabel;

  // Adding trusted device page
  String get addingDeviceTitle;

  // Trust Agent enrollment page
  String get enrollingTitle;
  String get enrollingExplanation;
  String get enrollingLoadingLabel;
  String get resendEnrollmentButtonLabel;
  String get resendEnrollmentTitle;
  String get resendEnrollmentBody;

  // Trust Agent enrollment error page.
  String get enrollingErrorTitle;
  String get enrollingErrorDescription;

  // Car details page.
  String get settingsIconTooltip;
  String get securityTitle;
  String get dataSyncTitle;
  String get shortUnlockExplanation;
  String get calendarsTitle;
  String get calendarsExplanation;
  String get messagingTitle;
  String get messagingExplanation;
  String get detectedState;
  String get connectedState;
  String get disconnectedState;
  String get bluetoothDisabled;
  String get featureOn;
  String get trustedDeviceFeatureExplanation;
  String get carListTitle;
  String get addCarButtonLabel;
  String get editNameLabel;
  String get experimentalFeaturesLabel;
  String get removeCarLabel;
  String get removeCarDialogTitle;
  String get removeCarDialogContent;
  String get removeButtonLabel;
  String get reportIssueLabel;
  String get shareLogsLabel;
  String get shareLogsButtonLabel;
  String get selectLogsTitle;

  // Unlock history page
  String get recentUnlockActivityTitle;
  String get today;
  String get yesterday;
  String get daysAgo;

  // Calendar Sync
  String get calendarFeatureIntroButtonText;
  String get calendarFeatureIntroSubtitle;
  String get calendarFeatureIntroTitle;

  String get calendarSyncListTitle;
  String get calendarSyncButtonLabel;
  String get calendarScreenTitle;
  String get calendarSyncDescription;
  String get calendarSyncDefaultAccount;

  String get calendarPermissionsAlertDialogTitle;
  String get calendarPermissionsAlertDialogContent;
  String get noCalendarsFound;

  // Messaging setup flow page
  String get messagingFeatureIntroTitle;
  String get messagingFeatureIntroSubtitle;
  String get messagingFeatureIntroSubtitleTwo;
  String get messagingNotificationAccessTitle;
  String get messagingNotificationAccessSubtitle;
  String get actionContinue;
  String get messagingFeatureSetupTitle;
  String get messagingFeatureSetupSubtitle;
  String get messagingFeatureSetupCTA;
  String get turnOn;
  String get turnOff;

  // Trusted device setup flow page
  String get carNotConnectedWarningTitle;
  String get carNotConnectedWarningContent;
  String get trustedDeviceFeatureIntroTitle;
  String get trustedDeviceFeatureIntroContent;
  String get continueButtonLabel;
  String get quickUnlockTitle;
  String get quickUnlockContent;
  String get quickUnlockSecureOptionLabel;
  String get quickUnlockSecureOption;
  String get quickUnlockConvenientOptionLabel;
  String get quickUnlockConvenientOption;
  String get quickUnlockConfigurationLabel;
  String get secureOptionExplanation;
  String get convenientOptionExplanation;
  String get unlockNotificationTitle;
  String get unlockNotificationExplanation;

  // Experimental features page
  String get experimentalFeaturesTitle;

  static StringLocalizations of(BuildContext context) {
    return Localizations.of(context, StringLocalizations);
  }
}

/// The default implementation of [StringLocalizations].
///
/// It exposes a static [delegate] that Flutter uses to load this class
/// and expose it to the widget tree.
///
/// When it is loaded, Widgets inside of an app can retrieve it by using
/// [StringLocalizations.of].
class IntlStringLocalizations extends StringLocalizations {
  @override
  String get appBarBackLabel => Intl.message('Back');

  @override
  String get startButtonLabel => Intl.message('Start');

  @override
  String get cancelButtonLabel => Intl.message('Cancel');

  @override
  String get doneButtonLabel => Intl.message('Done');

  @override
  String get needsBluetoothWarning => Intl.message(
      'Make sure Bluetooth is on and discoverable for your phone and car.');

  @override
  String get bluetoothWarningTitle => Intl.message('Turn on Bluetooth');

  @override
  String get bluetoothWarningExplanation => Intl.message(
      'To connect to your car, this app needs Bluetooth. Turn on '
      'Bluetooth from your phone settings or quick settings, then go back.');

  @override
  String get alertDialogOkButton => Intl.message('OK');

  @override
  String versionNumberLabel(String versionNumber) =>
      Intl.message('Version $versionNumber', args: [versionNumber]);

  @override
  String get passcodeAlertDialogTitle =>
      Intl.message('You need a passcode for this phone');

  @override
  String get passcodeAlertDialogContent => Intl.message(
      'Your phone needs a passcode in order to use it to unlock your profile. '
      'You can set one up in Settings.');

  @override
  String get openSettingsLabel => Intl.message('Settings');

  @override
  String get trustedDeviceTitle =>
      Intl.message('Automatically unlock your car profile');

  @override
  String get trustedDeviceExplanation => Intl.message(
      'Unlock your profile on the car screen automatically when your phone is '
      'nearby. You won\'t have to manually unlock every time.');

  @override
  String get carNotConnectedWarningTitle =>
      Intl.message('This requires an active connection with your car');

  @override
  String get carNotConnectedWarningContent =>
      Intl.message('Make sure your car and phone have bluetooth turned on, and '
          'the car screen is within reach.');

  @override
  String get associationNamePrefix => Intl.message('Vehicle ');

  @override
  String get lookingForCarTitle =>
      Intl.message('Go to your car screen to begin connecting');

  @override
  String get lookingForCarExplanation =>
      Intl.message('On your car screen, go to Settings > Companion Device');

  @override
  String get lookingForCarProgress => Intl.message('Looking for a car ...');

  @override
  String get restartBluetoothDialogTitle =>
      Intl.message('Something went wrong');

  @override
  String get restartBluetoothDialogContent => Intl.message(
      'Try turning your Bluetooth off and on and connecting to your car again');

  @override
  String vehicleFoundTitle(String name) =>
      Intl.message('$name found', args: [name]);

  @override
  String get connectConfirmationExplanation =>
      Intl.message('Connect to this car?');

  @override
  String get notMyCarButtonLabel => Intl.message('Not my car');

  @override
  String get connectButtonLabel => Intl.message('Connect');

  @override
  String get selectCarTitle => Intl.message('Select your car');

  @override
  String get selectCarExplanation =>
      Intl.message('Select the car that matches the name displayed on your '
          'car screen');

  @override
  String get selectCarListTitle => Intl.message('Nearby cars');

  @override
  String get refreshCarListButtonLabel => Intl.message('Refresh');

  @override
  String get connectingCarTitle => Intl.message('Connecting to Car');

  @override
  String get connectionRetryExplanation =>
      Intl.message('This is taking a long time...');

  @override
  String get connectionRetryButton => Intl.message('Try again?');

  @override
  String get associationErrorDialogTitle =>
      Intl.message('Something went wrong');

  @override
  String get associationErrorDialogBody =>
      Intl.message('Try connecting to your car again');

  @override
  String get associationErrorDialogConfirmButton => Intl.message('Ok');

  @override
  String get welcomeTitle => Intl.message('Welcome to Companion App');

  @override
  String get welcomeContent =>
      Intl.message('To manage these tasks, connect this app to your car');

  @override
  String get trustedDeviceShortExplanation =>
      Intl.message('Unlock your profile');

  @override
  String get calendarSyncShortExplanation =>
      Intl.message('Find routes to event');

  @override
  String get messengerSyncShortExplanation =>
      Intl.message('Chat safely with friends');

  @override
  String get bluetoothRequirementExplanation => Intl.message('Companion App '
      'uses your phone\'s Bluetooth to communicate with your car');

  @override
  String get getStartedButtonLabel => Intl.message('Get started');

  @override
  String get pairingCodeTitle => Intl.message('Confirm pair code');

  @override
  String get pairingCodeExplanation =>
      Intl.message('Check that this code matches the one on your car screen');

  @override
  String get renamePageTitle => Intl.message('Edit vehicle name');

  @override
  String get saveButtonLabel => Intl.message('Save');

  @override
  String get addingDeviceTitle => Intl.message('Adding car');

  @override
  String get enrollingTitle =>
      Intl.message('To continue, look for a notification on your car screen');

  @override
  String get enrollingExplanation =>
      Intl.message('You need to finish setting up this feature in your car');

  @override
  String get enrollingLoadingLabel => Intl.message('Waiting for a response...');

  @override
  String get resendEnrollmentButtonLabel =>
      Intl.message('Not seeing a notification?');

  @override
  String get resendEnrollmentTitle =>
      Intl.message('A new notification has been sent');

  @override
  String get resendEnrollmentBody => Intl.message(
      'You may need to swipe from the top of the screen or go to your '
      'notifications');

  @override
  String get enrollingErrorTitle => Intl.message('Something went wrong');

  @override
  String get enrollingErrorDescription => Intl.message(
      'Unfortunately, this feature could not be turned on at this time. '
      'Please try again.');

  @override
  String get addCarButtonLabel => Intl.message('Connect a car');

  @override
  String get settingsIconTooltip => Intl.message('Car settings');

  @override
  String get securityTitle => Intl.message('Security');

  @override
  String get dataSyncTitle => Intl.message('Data Sync');

  @override
  String get shortUnlockExplanation =>
      Intl.message('Unlock profile with phone');

  @override
  String get calendarsTitle => Intl.message('Calendars');

  @override
  String get calendarsExplanation =>
      Intl.message('Set up event navigation and more');

  @override
  String get messagingTitle => Intl.message('Messaging');

  @override
  String get messagingExplanation =>
      Intl.message('Set up message notifications');

  @override
  String get detectedState => Intl.message('Detected');

  @override
  String get connectedState => Intl.message('Connected');

  @override
  String get disconnectedState => Intl.message('Not detected');

  @override
  String get bluetoothDisabled => Intl.message('Bluetooth is off');

  @override
  String get featureOn => Intl.message('On');

  @override
  String get trustedDeviceFeatureExplanation =>
      Intl.message('Set up automatic unlocking');

  @override
  String get recentUnlockActivityTitle => Intl.message('Recent activity');

  @override
  String get today => Intl.message('Today');

  @override
  String get yesterday => Intl.message('Yesterday');

  @override
  String get daysAgo => Intl.message('Days Ago');

  @override
  String get calendarFeatureIntroButtonText => Intl.message('Sync calendars');

  @override
  String get calendarFeatureIntroSubtitle =>
      Intl.message('See event notifications, get directions, and more');

  @override
  String get calendarFeatureIntroTitle => Intl.message('Find routes to events');

  @override
  String get calendarSyncListTitle => Intl.message('Calendars');

  @override
  String get calendarSyncButtonLabel => Intl.message('Synchronize');

  @override
  String get calendarScreenTitle => Intl.message('Calendar');

  @override
  String get calendarSyncDescription => Intl.message(
      'While your phone is connected to this car, you can get notifications '
      'and directions for today’s events on the car screen');

  @override
  String get calendarSyncDefaultAccount => Intl.message('Other');

  @override
  String get calendarPermissionsAlertDialogTitle =>
      Intl.message('Calendar Permissions are required');

  @override
  String get calendarPermissionsAlertDialogContent => Intl.message(
      'You must grant access to your calendar to use this feature. '
      'Please grant and try again.');

  @override
  String get noCalendarsFound =>
      Intl.message('There are no calendars available on your device.');

  @override
  String get messagingFeatureIntroTitle =>
      Intl.message('Chat safely with friends');

  @override
  String get messagingFeatureIntroSubtitle =>
      Intl.message('Receive and respond to chat messages using your voice.');

  @override
  String get messagingFeatureIntroSubtitleTwo => Intl.message(
      'Messages may be shared with a third party, such as a digital assistant '
      'for voice transcription.');

  @override
  String get actionContinue => Intl.message('Continue');

  @override
  String get messagingNotificationAccessTitle =>
      Intl.message('Grant access to notifications');

  @override
  String get messagingNotificationAccessSubtitle => Intl.message(
      'To display your chat messages on the car screen, [Companion app] '
      'needs to read your phone’s notifications.');

  @override
  String get messagingFeatureSetupTitle => Intl.message('Messaging');

  @override
  String get messagingFeatureSetupSubtitle =>
      Intl.message('Allow your car to read notifications on your phone and'
          ' display them on your car screen.');

  @override
  String get messagingFeatureSetupCTA => Intl.message(
      'To control whether an app sends messages to your car screen, '
      'open the app on your phone and check its notification settings.\n\n'
      'If notifications are turned on and the app supports cars, you\'ll '
      'see its messages.');

  @override
  String get turnOn => Intl.message('Turn On');

  @override
  String get turnOff => Intl.message('Turn Off');

  @override
  String get carListTitle => Intl.message('Cars');

  @override
  String get editNameLabel => Intl.message('Edit name');

  @override
  String get experimentalFeaturesLabel => Intl.message('Experimental features');

  @override
  String get removeCarLabel => Intl.message('Remove this car');

  @override
  String get removeCarDialogTitle => Intl.message('Remove this car?');

  @override
  String get removeCarDialogContent => Intl.message(
      'To re-connect, you\'ll need to go through the pairing process again.');

  @override
  String get removeButtonLabel => Intl.message('Remove');

  @override
  String get reportIssueLabel => Intl.message('Report an Issue');

  @override
  String get shareLogsLabel => Intl.message('Share Logs');

  @override
  String get shareLogsButtonLabel => Intl.message('Share');

  @override
  String get selectLogsTitle => Intl.message('Share Selected Logs');

  @override
  String get trustedDeviceFeatureIntroTitle =>
      Intl.message('Use your phone to unlock your profile');

  @override
  String get trustedDeviceFeatureIntroContent => Intl.message(
      'When it\'s near your car, your phone can unlock your profile. You '
      'won\'t have to unlock it manually.');

  @override
  String get quickUnlockTitle =>
      Intl.message('How do you want to unlock your profile?');

  @override
  String get quickUnlockContent =>
      Intl.message('Control when you want your phone to unlock your profile');

  @override
  String get quickUnlockSecureOptionLabel => Intl.message('More secure');

  @override
  String get quickUnlockSecureOption =>
      Intl.message('Only when phone is unlocked');

  @override
  String get quickUnlockConvenientOptionLabel =>
      Intl.message('More convenient');

  @override
  String get quickUnlockConvenientOption =>
      Intl.message('Even when phone is locked');

  @override
  String get continueButtonLabel => Intl.message('Continue');

  @override
  String get quickUnlockConfigurationLabel => Intl.message('When to use');

  @override
  String get secureOptionExplanation => Intl.message(
      'You must unlock your phone before it can unlock your profile');

  @override
  String get convenientOptionExplanation => Intl.message(
      'Your profile will unlock automatically even if your phone is locked.');

  @override
  String get unlockNotificationTitle => Intl.message('Notify when unlocked');

  @override
  String get unlockNotificationExplanation => Intl.message(
      'Receive a notification each time your phone unlocks your profile.');

  @override
  String get experimentalFeaturesTitle => Intl.message('Experimental features');

  @override
  String get bluetoothPermissionAlertDialogTitleIos =>
      Intl.message('Allow "Companion App" to use Bluetooth');

  @override
  String get bluetoothPermissionAlertDialogContentIos => Intl.message(
      'This app needs Bluetooth to connect to your car. You can allow '
      'Bluetooth access in Settings.');

  @override
  String get bluetoothPermissionAlertDialogTitleAndroid =>
      Intl.message('CompanionApp always needs location access');

  @override
  String get bluetoothPermissionAlertDialogTitleAndroidBeforeSdk29 =>
      Intl.message('CompanionApp needs location access');

  @override
  String get bluetoothPermissionAlertDialogContentAndroid => Intl.message(
      'To connect whenever your car is nearby, allow access all the time');

  @override
  String get bluetoothPermissionAlertDialogContentAndroidBeforeSdk29 =>
      Intl.message('To connect whenever your car is nearby, allow access');

  static Future<StringLocalizations> load(Locale locale) async {
    return Future.value(IntlStringLocalizations());
  }

  static const LocalizationsDelegate<StringLocalizations> delegate =
      _IntlStringLocalizationsDelegate();
}

class _IntlStringLocalizationsDelegate
    extends LocalizationsDelegate<StringLocalizations> {
  const _IntlStringLocalizationsDelegate();

  @override
  Future<StringLocalizations> load(Locale locale) =>
      IntlStringLocalizations.load(locale);

  @override
  bool isSupported(Locale locale) => true;

  @override
  bool shouldReload(LocalizationsDelegate<StringLocalizations> old) => false;
}
