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

import 'package:automotive_companion/connection_manager.dart';
import 'package:automotive_companion/screens/looking_for_car_page.dart';
import 'package:automotive_companion/screens/open_settings_alert_dialog.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

const _featureIconSize = 48.0;
const _featureIconBorderRadius = 8.0;

/// The max screen height before we switch to smaller top padding.
const _screenHeightPaddingBreakPoint = 600.0;
const _titleFlex = 19;
const _featureListBottomFlex = 20;
const _versionCodeTopFlex = 1;
const _bottomPadding = 48.0;
const _featureItemPadding = 10.0;

/// Main page which is the association entry point.
class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late ConnectionManager _connectionManager;
  String? _versionNumber;

  /// The current Android SDK version.
  ///
  /// This value is will only be non-null if the current platform is Android.
  /// https://developer.android.com/studio/releases/platforms
  int _androidSdk = 0;

  @override
  void initState() {
    super.initState();
    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    _fetchVersionInformation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method cannot be called in `initState` because it relies on calling
    // Theme.of(), which can only be used after `initState`. Flutter recommends
    // using `didChangeDependencies` for this purpose.
    _fetchAndroidInformation();
  }

  void _fetchVersionInformation() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _versionNumber = packageInfo.version;
    });
  }

  void _fetchAndroidInformation() async {
    if (Theme.of(context).platform != TargetPlatform.android) {
      return;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    setState(() {
      _androidSdk = androidInfo.version.sdkInt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final strings = StringLocalizations.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Spacer(flex: _titleFlex),

          // Explanation title.
          Padding(
            padding: EdgeInsets.only(
              right: dimensions.titleHorizontalPadding,
              left: dimensions.titleHorizontalPadding,
            ),
            child: Text(
              strings.welcomeTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline4,
            ),
          ),

          // Explanation text.
          Padding(
            padding: EdgeInsets.only(
              top: dimensions.textSpacing,
              right: dimensions.pageHorizontalPadding,
              left: dimensions.pageHorizontalPadding,
            ),
            child: Text(
              strings.welcomeContent,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: dimensions.largeIconPadding,
              horizontal: dimensions.pageHorizontalPadding,
            ),
            child: Column(
              children: [
                _featureLabel(
                    Image(
                      image: AssetImage('assets/images/icon_welcome_lock.png'),
                    ),
                    strings.trustedDeviceShortExplanation),
                if (Theme.of(context).platform == TargetPlatform.android)
                  ..._androidOnlyFeatures,
              ],
            ),
          ),

          Spacer(flex: _featureListBottomFlex),

          // The button to begin the process of associating a new car.
          Container(
            padding: EdgeInsets.only(
              right: dimensions.pageHorizontalPadding,
              left: dimensions.pageHorizontalPadding,
              bottom: dimensions.textSpacing,
            ),
            child: Text(
              strings.bluetoothRequirementExplanation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
          ButtonTheme(
            height: dimensions.actionButtonHeight,
            minWidth: dimensions.actionButtonWidth,
            child: RaisedButton(
              textColor: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(dimensions.actionButtonRadius)),
              onPressed: () async {
                if (await _connectionManager.isBluetoothPermissionGranted()) {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LookingForCarPage()));
                  return;
                }
                _showBluetoothPermissionDialog();
              },
              child: Text(strings.getStartedButtonLabel),
            ),
          ),

          Spacer(flex: _versionCodeTopFlex),

          if (_versionNumber != null) _versionNumberText(screenHeight),
        ],
      ),
    );
  }

  List<Widget> get _androidOnlyFeatures {
    final strings = StringLocalizations.of(context);
    return [
      _featureLabel(
        Image(
          image: AssetImage('assets/images/icon_welcome_cal.png'),
        ),
        strings.calendarSyncShortExplanation,
      ),
      _featureLabel(
        Image(
          image: AssetImage('assets/images/icon_welcome_msg.png'),
        ),
        strings.messengerSyncShortExplanation,
      ),
    ];
  }

  /// A widget that displays the current version of the application.
  Widget _versionNumberText(double screenHeight) {
    final strings = StringLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: screenHeight > _screenHeightPaddingBreakPoint
            ? _bottomPadding
            : dimensions.textSpacing,
        bottom: dimensions.textSpacing,
      ),
      child: Text(
        strings.versionNumberLabel(_versionNumber ?? ''),
        style: Theme.of(context)
            .textTheme
            .caption!
            .apply(color: Theme.of(context).colorScheme.onSecondary),
      ),
    );
  }

  Widget _featureLabel(Image icon, String explanation) => Padding(
        padding: const EdgeInsets.symmetric(vertical: _featureItemPadding),
        child: ListTile(
          leading: Container(
            height: _featureIconSize,
            width: _featureIconSize,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(_featureIconBorderRadius),
            ),
            child: icon,
          ),
          title: Text(
            explanation,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
      );

  void _showBluetoothPermissionDialog() {
    var bluetoothPermissionDialogTitle = '';
    var bluetoothPermissionDialogContent = '';
    final strings = StringLocalizations.of(context);
    if (Theme.of(context).platform == TargetPlatform.android) {
      // Show different text after SDK level 29 because extra permission is
      // required.
      if (_androidSdk < 29) {
        bluetoothPermissionDialogTitle =
            strings.bluetoothPermissionAlertDialogTitleAndroidBeforeSdk29;
        bluetoothPermissionDialogContent =
            strings.bluetoothPermissionAlertDialogContentAndroidBeforeSdk29;
      } else {
        bluetoothPermissionDialogTitle =
            strings.bluetoothPermissionAlertDialogTitleAndroid;
        bluetoothPermissionDialogContent =
            strings.bluetoothPermissionAlertDialogContentAndroid;
      }
    } else {
      bluetoothPermissionDialogTitle =
          strings.bluetoothPermissionAlertDialogTitleIos;
      bluetoothPermissionDialogContent =
          strings.bluetoothPermissionAlertDialogContentIos;
    }
    OpenSettingsAlert.showRequestingPermissionsDialog(
        context: context,
        title: bluetoothPermissionDialogTitle,
        content: bluetoothPermissionDialogContent);
  }
}
