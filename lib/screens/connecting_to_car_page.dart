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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../car.dart';
import '../common_app_bar.dart';
import '../connection_manager.dart';
import '../string_localizations.dart';
import '../values/bluetooth_state.dart';
import '../values/dimensions.dart' as dimensions;
import 'association_error_dialog.dart';
import 'bluetooth_warning_page.dart';
import 'car_details_page.dart';
import 'pairing_code_page.dart';

/// Maximum amount of time to wait for connection to succeed before prompting
/// the user to try again.
@visibleForTesting
const connectionTimeout = Duration(seconds: 8);

/// Page that appears after user picking a car to connect.
///
/// The connection completes under the hood then waits for the pairing code to
/// be generated.
class ConnectingPage extends StatefulWidget {
  @override
  State createState() => ConnectingState();
}

@visibleForTesting
class ConnectingState extends State<ConnectingPage>
    implements AssociationCallback, ConnectionCallback {
  ConnectionManager _connectionManager;
  Timer _connectionTimeoutTimer;
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    _connectionManager.registerAssociationCallback(this);
    _connectionManager.registerConnectionCallback(this);
    _startConnectionTimeoutTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _connectionTimeoutTimer?.cancel();
    _connectionManager.unregisterConnectionCallback(this);
    _connectionManager.unregisterAssociationCallback(this);
  }

  @visibleForTesting
  @override
  void onPairingCodeAvailable(String pairingCode) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => PairingCodePage(pairCode: pairingCode)));
  }

  @override
  void onAssociationCompleted(Car car) {
    _navigateToCarDetailsPage(car);
  }

  @override
  void onAssociationError() {
    _showErrorDialog();
  }

  @override
  void onBluetoothStateChanged(String state) {
    if (state != BluetoothState.on) {
      _navigateToBluetoothWarningPage();
    }
  }

  @override
  void onCarConnectionStatusChange(String carId, CarConnectionStatus status) {
    if (status == CarConnectionStatus.disconnected) {
      _showErrorDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return WillPopScope(
      // Disallow back button presses during connection. The user can still
      // cancel by explicitly pressing the back button in the app bar.
      onWillPop: () async => false,
      child: Scaffold(
        appBar: commonAppBar(
          context,
          onBackPressed: _cancelAssociationAndNavigateBack,
        ),
        body: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(
            top: dimensions.appBarBottomPadding,
            bottom: dimensions.pageBottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: dimensions.pageHorizontalPadding,
                  left: dimensions.pageHorizontalPadding,
                  bottom: dimensions.textSpacing,
                ),
                child: Text(
                  strings.connectingCarTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: dimensions.progressIndicatorTopPadding,
                  left: dimensions.progressIndicatorHorizontalPadding,
                  right: dimensions.progressIndicatorHorizontalPadding,
                  bottom: dimensions.progressIndicatorBottomPadding,
                ),
                child: LinearProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                ),
              ),
              Spacer(),
              if (_showRetry) ..._retryItems(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _retryItems() => [
        Text(
          StringLocalizations.of(context).connectionRetryExplanation,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyText2,
        ),
        Padding(
          padding: EdgeInsets.only(top: dimensions.textSpacing),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: _cancelAssociationAndNavigateBack,
            child: Text(StringLocalizations.of(context).connectionRetryButton),
          ),
        )
      ];

  void _startConnectionTimeoutTimer() {
    if (_connectionTimeoutTimer != null) {
      return;
    }

    _connectionTimeoutTimer = Timer(connectionTimeout, () {
      setState(() {
        _showRetry = true;
      });
    });
  }

  void _cancelAssociationAndNavigateBack() {
    Navigator.of(context).pop();
    _connectionManager.clearCurrentAssociation();
  }

  void _showErrorDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssociationErrorDialog(),
    );

    _cancelAssociationAndNavigateBack();
  }

  void _navigateToBluetoothWarningPage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => BluetoothWarningPage()));
  }

  void _navigateToCarDetailsPage(Car car) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailsPage(currentCar: car),
      ),
    );
  }
}
