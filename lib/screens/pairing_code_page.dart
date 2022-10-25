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

import 'package:flutter/cupertino.dart';
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

const _pinLetterSpacing = 8.0;
const _pinVerticalPadding = 12.0;
const _pinHorizontalPadding = 24.0;

// Ensure a ratio of 3:1.
const _spacerTopFlex = 1;
const _spacerBottomFlex = 3;

/// Page that shows the pairing code.
///
/// Pairing code is a 4-digits string showing on both screens of the two
/// connected devices so that user can confirm they are connecting to the right
/// device.
class PairingCodePage extends StatefulWidget {
  final String pairCode;
  PairingCodePage({Key key, @required this.pairCode}) : super(key: key);

  @override
  State createState() => PairingCodePageState();
}

class PairingCodePageState extends State<PairingCodePage>
    implements AssociationCallback, ConnectionCallback {
  ConnectionManager _connectionManager;

  @override
  void initState() {
    super.initState();
    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    _connectionManager.registerAssociationCallback(this);
    _connectionManager.registerConnectionCallback(this);
  }

  @override
  void dispose() {
    super.dispose();
    _connectionManager.unregisterAssociationCallback(this);
    _connectionManager.unregisterConnectionCallback(this);
  }

  @override
  void onBluetoothStateChanged(String state) {
    if (state != BluetoothState.on) {
      _navigateToBluetoothWarningPage();
    }
  }

  @override
  void onPairingCodeAvailable(String pairingCode) {}

  @override
  void onAssociationCompleted(Car car) {
    _navigateToCarDetailsPage(car);
  }

  @override
  void onAssociationError() {
    _showErrorDialog();
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
      // Disallow back button presses during pairing code confirmation to
      // prevent accidental dismissal.
      onWillPop: () async => false,
      child: Scaffold(
        appBar: commonAppBar(
          context,
          onBackPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            _connectionManager.clearCurrentAssociation();
          },
        ),
        body: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(
            top: dimensions.appBarBottomPadding,
            bottom: dimensions.pageBottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: dimensions.titleHorizontalPadding,
                  left: dimensions.titleHorizontalPadding,
                  bottom: dimensions.textSpacing,
                ),
                child: Text(
                  strings.pairingCodeTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.pageHorizontalPadding,
                ),
                child: Text(
                  strings.pairingCodeExplanation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Spacer(flex: _spacerTopFlex),
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: _pinVerticalPadding,
                  horizontal: _pinHorizontalPadding,
                ),
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.surface),
                child: Text(widget.pairCode,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline3.copyWith(
                        color: Theme.of(context).primaryColor,
                        letterSpacing: _pinLetterSpacing)),
              ),
              Spacer(flex: _spacerBottomFlex),
            ],
          ),
        ),
      ),
    );
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

  void _showErrorDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssociationErrorDialog(),
    );

    // When the dialog is dismissed, navigate back to the starting page.
    _connectionManager.clearCurrentAssociation();
    Navigator.of(context).pop();
  }

  void _navigateToBluetoothWarningPage() {
    _connectionManager.clearCurrentAssociation();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => BluetoothWarningPage()));
  }
}
