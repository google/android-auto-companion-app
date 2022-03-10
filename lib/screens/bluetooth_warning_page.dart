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

import 'package:automotive_companion/common_app_bar.dart';
import 'package:automotive_companion/connection_manager.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/values/bluetooth_state.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

/// A page that displays a warning to the user that they need to enable
/// Bluetooth on their device.
///
/// This page can display an option to navigate the user to system settings if
/// the current platform supports navigating directly to Bluetooth settings.
///
/// If Bluetooth is turned on while the user is on this page, then it will
/// automatically navigate back.
class BluetoothWarningPage extends StatefulWidget {
  const BluetoothWarningPage({Key? key}) : super(key: key);

  @override
  State createState() => BluetoothWarningPageState();
}

@visibleForTesting
class BluetoothWarningPageState extends State<BluetoothWarningPage>
    with WidgetsBindingObserver
    implements ConnectionCallback {
  late ConnectionManager _connectionManager;

  @override
  void initState() {
    super.initState();

    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    _connectionManager.registerConnectionCallback(this);

    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    _connectionManager.unregisterConnectionCallback(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed &&
        await _connectionManager.isBluetoothEnabled()) {
      _clearAssociationAndNavigateBack();
    }
  }

  @override
  void onBluetoothStateChanged(String state) {
    if (state == BluetoothState.on) {
      _clearAssociationAndNavigateBack();
    }
  }

  @override
  void onCarConnectionStatusChange(String carId, CarConnectionStatus status) {}

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return Scaffold(
      appBar: commonAppBar(
        context,
        onBackPressed: _clearAssociationAndNavigateBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: dimensions.appBarBottomPadding,
              right: dimensions.titleHorizontalPadding,
              left: dimensions.titleHorizontalPadding,
              bottom: dimensions.textSpacing,
            ),
            child: Text(
              strings.bluetoothWarningTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline3,
            ),
          ),

          // Explanation text explaining why Bluetooth is required.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: dimensions.pageHorizontalPadding,
            ),
            child: Text(
              strings.bluetoothWarningExplanation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),

          Spacer(),
          SvgPicture.asset('assets/images/ill_bluetooth.svg'),
          Spacer(),

          // Only show the open settings open for Android because we cannot
          // direct the user directly to the Bluetooth settings on iOS.
          if (Theme.of(context).platform == TargetPlatform.android)
            _openSettingsButton
        ],
      ),
    );
  }

  void _clearAssociationAndNavigateBack() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _connectionManager.clearCurrentAssociation();
  }

  Widget get _openSettingsButton {
    return Padding(
      padding: EdgeInsets.only(
        left: dimensions.pageHorizontalPadding,
        right: dimensions.pageHorizontalPadding,
        bottom: dimensions.pageBottomPadding,
      ),
      child: FlatButton(
        textColor: Theme.of(context).primaryColor,
        onPressed: _connectionManager.openBluetoothSettings,
        child: Text(StringLocalizations.of(context).openSettingsLabel),
      ),
    );
  }
}
