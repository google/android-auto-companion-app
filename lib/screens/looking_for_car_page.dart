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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../car.dart';
import '../common_app_bar.dart';
import '../connection_manager.dart';
import '../string_localizations.dart';
import '../values/bluetooth_state.dart';
import '../values/dimensions.dart' as dimensions;
import 'bluetooth_warning_page.dart';
import 'connecting_to_car_page.dart';
import 'one_car_found_page.dart';
import 'select_car_page.dart';

/// How long to scan for cars after one car has been found.
const _waitingForOtherCarsTimeout = Duration(seconds: 2);

/// Displays to the user that a scan for cars that can be associated is in
/// progress.
class LookingForCarPage extends StatefulWidget {
  @override
  State createState() => LookingForCarPageState();
}

class LookingForCarPageState extends State<LookingForCarPage>
    implements ConnectionCallback, DiscoveryCallback {
  ConnectionManager _connectionManager;

  /// A list of names for cars that can be associated with.
  final _discoveredCars = <Car>{};

  /// A timer that starts after a car is discovered and determines when a
  /// navigation to the next page should occur.
  Timer nextPageNavigationTimer;

  @override
  void initState() {
    super.initState();
    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    _connectionManager.registerConnectionCallback(this);
    _connectionManager.registerDiscoveryCallback(this);
  }

  @override
  void dispose() {
    super.dispose();
    nextPageNavigationTimer?.cancel();
    _connectionManager.unregisterConnectionCallback(this);
    _connectionManager.unregisterDiscoveryCallback(this);
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);
    _scanForCarsToAssociate(strings.associationNamePrefix);

    return WillPopScope(
      onWillPop: () async {
        _connectionManager.clearCurrentAssociation();
        return true;
      },
      child: Scaffold(
        appBar: commonAppBar(context, onBackPressed: () {
          _connectionManager.clearCurrentAssociation();
          Navigator.of(context).pop();
        }),
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
                padding: const EdgeInsets.only(
                  left: dimensions.titleHorizontalPadding,
                  right: dimensions.titleHorizontalPadding,
                  bottom: dimensions.textSpacing,
                ),
                child: Text(
                  strings.lookingForCarTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),

              // Explanation text explaining why Bluetooth is required.
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.pageHorizontalPadding,
                ),
                child: Text(
                  strings.lookingForCarExplanation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),

              Spacer(),
              SvgPicture.asset('assets/images/ill_carScreenSettings.svg'),
              Spacer(),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.pageHorizontalPadding,
                ),
                child: Text(
                  strings.lookingForCarProgress,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @visibleForTesting
  @override
  void onCarDiscovered(Car car) {
    _discoveredCars.add(car);

    // Ensure the next page navigation timer is only initialized once -- when
    // the first car is discovered.
    if (nextPageNavigationTimer != null) {
      return;
    }

    // Schedule a timer so that a scan will continue to run. At the end of the
    // timer, navigate based on how many total cars were discovered.
    nextPageNavigationTimer = Timer(_waitingForOtherCarsTimeout, () {
      final nextPage = _discoveredCars.length == 1
          ? OneCarFoundPage(carToConnect: _discoveredCars.first)
          : SelectCarPage(discoveredCars: _discoveredCars);

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => nextPage));
    });
  }

  @override
  void onAssociationStarted() {
    nextPageNavigationTimer?.cancel();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => ConnectingPage()));
  }

  @visibleForTesting
  @override
  void onBluetoothStateChanged(String newState) {
    _discoveredCars.clear();

    if (newState == BluetoothState.on) {
      _connectionManager.scanForCarsToAssociate(
          StringLocalizations.of(context).associationNamePrefix);
    } else {
      _navigateToBluetoothWarningPage();
    }
  }

  @override
  void onDiscoveryError() {
    _showRestartBluetoothDialog();
  }

  @override
  void onDiscoveryCancelled() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void onCarConnectionStatusChange(String carId, CarConnectionStatus status) {}

  void _navigateToBluetoothWarningPage() {
    // Prevent a navigation to another page when navigating to the Bluetooth
    // warning page.
    nextPageNavigationTimer?.cancel();

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => BluetoothWarningPage()));
  }

  void _scanForCarsToAssociate(String namePrefix) async {
    if (await _connectionManager.isBluetoothEnabled) {
      _connectionManager.scanForCarsToAssociate(namePrefix);
    } else {
      _navigateToBluetoothWarningPage();
    }
  }

  void _showRestartBluetoothDialog() {
    final strings = StringLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            strings.restartBluetoothDialogTitle,
            style: Theme.of(context).textTheme.headline4,
          ),
          content: Text(strings.restartBluetoothDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              ),
              child: Text(strings.alertDialogOkButton,
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Theme.of(context).primaryColor)),
            ),
          ],
        );
      },
    );
  }
}
