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

import 'package:automotive_companion/car.dart';
import 'package:automotive_companion/common_app_bar.dart';
import 'package:automotive_companion/connection_manager.dart';
import 'package:automotive_companion/screens/bluetooth_warning_page.dart';
import 'package:automotive_companion/screens/connecting_to_car_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/values/bluetooth_state.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

const _buttonHorizontalPadding = 24.0;

/// Displays to the user that a car has been found with a given id.
///
/// This screen will prompt the user whether or not they wish to connect to the
/// car or to indicate that the car found isn't the one they're looking for.
class OneCarFoundPage extends StatefulWidget {
  final carToConnect;

  const OneCarFoundPage({Key? key, @required this.carToConnect})
      : super(key: key);

  @override
  State createState() => OneCarFoundPageState();
}

@visibleForTesting
class OneCarFoundPageState extends State<OneCarFoundPage>
    implements ConnectionCallback, DiscoveryCallback {
  late ConnectionManager _connectionManager;

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
    _connectionManager.unregisterConnectionCallback(this);
    _connectionManager.unregisterDiscoveryCallback(this);
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        _connectionManager.clearCurrentAssociation();
        return true;
      },
      child: Scaffold(
        appBar: commonAppBar(context, onBackPressed: _navigateBack),
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
                  left: dimensions.titleHorizontalPadding,
                  right: dimensions.titleHorizontalPadding,
                  bottom: dimensions.textSpacing,
                ),
                child: Text(
                  strings.vehicleFoundTitle(widget.carToConnect.name),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: dimensions.pageHorizontalPadding),
                child: Text(
                  strings.connectConfirmationExplanation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Spacer(),
              SvgPicture.asset('assets/images/ill_carSignal.svg'),
              Spacer(),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: _buttonHorizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FlatButton(
                      textColor: Theme.of(context).primaryColor,
                      onPressed: _navigateBack,
                      child: Text(strings.notMyCarButtonLabel),
                    ),
                    RaisedButton(
                      textColor: Theme.of(context).colorScheme.background,
                      onPressed: () {
                        _connectionManager.associateCar(widget.carToConnect.id);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ConnectingPage()));
                      },
                      child: Text(strings.connectButtonLabel),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onCarDiscovered(Car car) {
    // Ignore any newly discovered cars because this page should only display
    // on car to connect to. If the car is not what the user expects, there is
    // a button to restart the scan.
  }

  @override
  void onDiscoveryError() {}

  @override
  void onDiscoveryCancelled() {}

  @override
  void onAssociationStarted() {}

  @override
  void onBluetoothStateChanged(String newState) {
    if (newState == BluetoothState.off) {
      _navigateToBluetoothWarningPage();
    }
  }

  @override
  void onCarConnectionStatusChange(String carId, CarConnectionStatus status) {}

  void _navigateBack() {
    _connectionManager.clearCurrentAssociation();
    Navigator.of(context).pop();
  }

  void _navigateToBluetoothWarningPage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => BluetoothWarningPage()));
  }
}
