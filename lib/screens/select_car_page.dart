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
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:provider/provider.dart';

import '../car.dart';
import '../common_app_bar.dart';
import '../connection_manager.dart';
import '../string_localizations.dart';
import '../values/bluetooth_state.dart';
import '../values/dimensions.dart' as dimensions;
import 'bluetooth_warning_page.dart';
import 'connecting_to_car_page.dart';

const _carVerticalPadding = 10.0;
const _carListTopPadding = 64.0;

/// Page which shows the list of cars which are broadcasting.
class SelectCarPage extends StatefulWidget {
  /// A list of cars that can be associated with.
  final discoveredCars;

  SelectCarPage({Key key, @required this.discoveredCars}) : super(key: key);

  @override
  State createState() => SelectCarPageState();
}

@visibleForTesting
class SelectCarPageState extends State<SelectCarPage>
    implements ConnectionCallback, DiscoveryCallback {
  ConnectionManager _connectionManager;
  final _discoveredCars = <Car>{};

  @override
  void initState() {
    super.initState();
    _discoveredCars.addAll(widget.discoveredCars);
    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    _connectionManager.registerConnectionCallback(this);
    _connectionManager.registerDiscoveryCallback(this);
  }

  @override
  void dispose() {
    super.dispose();
    _connectionManager.unregisterConnectionCallback(this);
    _connectionManager.unregisterDiscoveryCallback(this);
    _discoveredCars.clear();
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
        appBar: commonAppBar(context, onBackPressed: () {
          Navigator.of(context).pop();
          _connectionManager.clearCurrentAssociation();
        }),
        body: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(bottom: dimensions.pageBottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: dimensions.appBarBottomPadding,
                  right: dimensions.pageHorizontalPadding,
                  left: dimensions.pageHorizontalPadding,
                ),
                child: Text(
                  strings.selectCarTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),

              // Text explaining why Bluetooth is required.
              Padding(
                padding: EdgeInsets.only(
                  top: dimensions.textSpacing,
                  right: dimensions.pageHorizontalPadding,
                  left: dimensions.pageHorizontalPadding,
                  bottom: _carListTopPadding,
                ),
                child: Text(
                  strings.selectCarExplanation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: dimensions.titleHorizontalPadding,
                  ),
                  child: Text(
                    strings.selectCarListTitle,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ),

              // The list of discovered cars.
              Expanded(child: Scrollbar(child: _carList)),

              Padding(
                padding: EdgeInsets.only(top: dimensions.textSpacing),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: _refreshList,
                  child: Text(strings.refreshCarListButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A list of discovered cars that are available for association.
  ListView get _carList {
    // Note: not using ListView.separated so that a dividing line can be added
    // at the top of the view.
    // This is not accomplished via a border because the line should disappear
    // if there are no items.
    return ListView.builder(
      itemCount: _discoveredCars.length,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Divider(),
          _carItem(_discoveredCars.elementAt(index)),
        ],
      ),
    );
  }

  /// A row within the car list that represents a car that can be associated
  /// with.
  Widget _carItem(Car car) {
    return InkWell(
      onTap: () {
        _connectionManager.associateCar(car.id);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => ConnectingPage()));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: _carVerticalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: dimensions.smallIconPadding),
              child: Icon(Icons.directions_car),
            ),
            Expanded(
              child: Text(
                car.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .apply(color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Exposed for testing because unit tests cannot mock the method handler
  // invocations.
  @visibleForTesting
  @override
  void onCarDiscovered(Car car) {
    setState(() {
      _discoveredCars.add(car);
    });
  }

  @override
  void onDiscoveryError() {}

  @override
  void onDiscoveryCancelled() {}

  @override
  void onAssociationStarted() {}

  @visibleForTesting
  @override
  void onBluetoothStateChanged(String newState) {
    setState(() {
      _discoveredCars.clear();
    });

    if (newState == BluetoothState.on) {
      _connectionManager.scanForCarsToAssociate(
          StringLocalizations.of(context).associationNamePrefix);
    } else {
      _navigateToBluetoothWarningPage();
    }
  }

  @override
  void onCarConnectionStatusChange(String carId, CarConnectionStatus status) {}

  void _navigateToBluetoothWarningPage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => BluetoothWarningPage()));
  }

  /// Initiates a refresh of the car list by re-scanning for cars that can be
  /// associated with.
  void _refreshList() {
    setState(() {
      _discoveredCars.clear();
    });

    _connectionManager.scanForCarsToAssociate(
        StringLocalizations.of(context).associationNamePrefix);
  }
}
