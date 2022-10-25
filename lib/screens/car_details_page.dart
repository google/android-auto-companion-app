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

import 'package:automotive_companion/widgets/calendar_sync_feature_item.dart';
import 'package:automotive_companion/widgets/messaging_sync_feature_item.dart';
import 'package:automotive_companion/widgets/trusted_device_feature_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

import '../car.dart';
import '../connection_manager.dart';
import '../string_localizations.dart';
import '../values/bluetooth_state.dart';
import '../values/dimensions.dart' as dimensions;
import 'looking_for_car_page.dart';
import 'rename_car_page.dart';
import 'welcome_page.dart';

const _statusIconSize = 10.0;
const _statusIconPadding = 7.0;
const _statusTitlePadding = 25.0;
const _drawerTopPadding = 75.0;
const _drawerBottomPadding = 25.0;
const _drawerTitleHorizontalPadding = 30.0;
const _drawerTitleBottomPadding = 10.0;
const _drawerHorizontalPadding = 20.0;
const _versionNumberStartPadding = 40.0;
const _featureListTopPadding = 66.0;
const _connectionStatusTopPadding = 10.0;
const _connectionStatusIndicatorSize = 10.0;
const _bluetoothIndicatorSize = 16.0;
const _connectionIndicatorPadding = 10.0;

/// Page which shows car details including name and connection status, and also
/// provides entries for feature managers' configuration page.
class CarDetailsPage extends StatefulWidget {
  final Car currentCar;

  CarDetailsPage({Key key, @required this.currentCar}) : super(key: key);

  @override
  State createState() => CarDetailsPageState();
}

@visibleForTesting
class CarDetailsPageState extends State<CarDetailsPage>
    implements ConnectionCallback {
  ConnectionManager _connectionManager;

  var _isBluetoothEnabled = false;

  final _detectedCarIds = <String>{};
  final _connectedCarsIds = <String>{};

  final _associatedCars = <Car>{};
  Car _currentCar;
  String _versionNumber;

  @override
  void initState() {
    super.initState();

    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);

    _connectionManager.registerConnectionCallback(this);
    _currentCar = widget.currentCar;
    _updateCarListAndConnectionStatus();
    _updateBluetoothState();

    _fetchVersionInformation();
  }

  void _fetchVersionInformation() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _versionNumber = packageInfo.version;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectionManager.unregisterConnectionCallback(this);
  }

  @override
  void onBluetoothStateChanged(String state) {
    setState(() {
      _isBluetoothEnabled = state == BluetoothState.on;
    });
  }

  @override
  void onCarConnectionStatusChange(String carId, CarConnectionStatus status) {
    switch (status) {
      case CarConnectionStatus.detected:
        _onCarDetected(carId);
        break;
      case CarConnectionStatus.connected:
        _onCarConnected(carId);
        break;
      case CarConnectionStatus.disconnected:
        _onCarDisconnected(carId);
        break;
    }
  }

  void _onCarDetected(String carId) {
    setState(() {
      _detectedCarIds.add(carId);
      _connectedCarsIds.remove(carId);
    });
  }

  void _onCarConnected(String carId) {
    setState(() {
      _detectedCarIds.remove(carId);
      _connectedCarsIds.add(carId);
    });
  }

  void _onCarDisconnected(String carId) {
    setState(() {
      _detectedCarIds.remove(carId);
      _connectedCarsIds.remove(carId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          IconButton(
            icon: ImageIcon(AssetImage('assets/images/icon_settings.png')),
            onPressed: () {
              _showBottomSheet(context);
            },
            tooltip: strings.settingsIconTooltip,
          )
        ],
      ),
      drawer: Drawer(
        child: Padding(
          padding: EdgeInsets.only(
            top: _drawerTopPadding,
            bottom: _drawerBottomPadding,
          ),
          child: _drawerContents,
        ),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(
          top: dimensions.appBarBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Car name and connection status.
            Padding(
              padding: EdgeInsets.only(
                right: dimensions.titleHorizontalPadding,
                left: dimensions.titleHorizontalPadding,
                bottom: _featureListTopPadding,
              ),
              child: Column(
                children: [
                  Text(
                    _currentCar.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline3,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: _connectionStatusTopPadding),
                    child: _connectionStatusLabel,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: ListView(
                  children: [
                    // Security sub feature group.
                    _subGroupTitle(strings.securityTitle),
                    TrustedDeviceFeatureItem(currentCar: _currentCar),

                    Divider(color: Theme.of(context).dividerColor),

                    // Data sync sub feature group.
                    _subGroupTitle(strings.dataSyncTitle),
                    CalendarSyncFeatureItem(currentCar: _currentCar),

                    // Message sync feature entry, only for Android.
                    if (Theme.of(context).platform == TargetPlatform.android)
                      MessagingSyncFeatureItem(currentCar: _currentCar),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _drawerContents {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: _drawerTitleHorizontalPadding,
            right: _drawerTitleHorizontalPadding,
            bottom: _drawerTitleBottomPadding,
          ),
          child: Text(
            StringLocalizations.of(context).carListTitle,
            style: Theme.of(context).textTheme.headline3,
          ),
        ),
        Divider(color: Theme.of(context).dividerColor),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _drawerHorizontalPadding),
            child: ListView(
              padding: EdgeInsets.all(0.0),
              children: [
                if (_associatedCars.isNotEmpty)
                  Column(
                    children: [
                      for (var car in _associatedCars) _createCarListItem(car),
                    ],
                  ),
                _createConnectCarButton,
              ],
            ),
          ),
        ),
        if (_versionNumber != null) _versionNumberText,
      ],
    );
  }

  /// A widget that displays the current version of the application.
  Widget get _versionNumberText {
    final strings = StringLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: dimensions.textSpacing,
        left: _versionNumberStartPadding,
        right: _drawerHorizontalPadding,
      ),
      child: Text(
        strings.versionNumberLabel(_versionNumber),
        style: Theme.of(context)
            .textTheme
            .caption
            .apply(color: Theme.of(context).colorScheme.onSecondary),
      ),
    );
  }

  /// Conveys whether the car on this page is currently connected.
  Widget get _connectionStatusLabel {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: _connectionIndicatorPadding),
          child: _connectionStatusIndicator,
        ),
        Text(
          _connectionStatusText,
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ],
    );
  }

  String get _connectionStatusText {
    final strings = StringLocalizations.of(context);

    if (_connectedCarsIds.contains(_currentCar.id)) {
      return strings.connectedState;
    }

    if (_detectedCarIds.contains(_currentCar.id)) {
      return strings.detectedState;
    }

    return _isBluetoothEnabled
        ? strings.disconnectedState
        : strings.bluetoothDisabled;
  }

  Widget get _connectionStatusIndicator {
    if (_connectedCarsIds.contains(_currentCar.id)) {
      return _circleIndicator(color: Colors.green[300]);
    }

    if (_detectedCarIds.contains(_currentCar.id)) {
      return _circleIndicator(color: Colors.yellow[700]);
    }

    return _isBluetoothEnabled
        ? _circleIndicator(color: Color(0xFF9AA0A6))
        : Icon(
            Icons.bluetooth_disabled,
            color: Colors.red[300],
            size: _bluetoothIndicatorSize,
          );
  }

  /// A circular widget that can be used to represent connection status.
  ///
  /// The indicator will be of the given [color].
  Widget _circleIndicator({@required Color color}) {
    assert(color != null);

    return Container(
      width: _connectionStatusIndicatorSize,
      height: _connectionStatusIndicatorSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// A row which display the feature sub group title.
  Widget _subGroupTitle(String groupName) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          top: dimensions.textSpacing,
          left: dimensions.titleHorizontalPadding,
          right: dimensions.titleHorizontalPadding,
        ),
        child: Text(
          groupName,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.subtitle1,
        ),
      ),
    );
  }

  void _updateBluetoothState() async {
    final isBluetoothEnabled = await _connectionManager.isBluetoothEnabled;
    setState(() {
      _isBluetoothEnabled = isBluetoothEnabled;
    });
  }

  void _updateConnectedCarList() async {
    _connectedCarsIds.clear();
    for (var car in _associatedCars) {
      var isConnected = await _connectionManager.isCarConnected(car);
      if (isConnected) {
        setState(() {
          _connectedCarsIds.add(car.id);
        });
      }
    }
  }

  Widget _createCarListItem(Car car) {
    final baseStyle = Theme.of(context).textTheme.subtitle1;
    final carNameStyle = car.id == _currentCar.id
        ? baseStyle.apply(color: Theme.of(context).colorScheme.onBackground)
        : baseStyle;

    return TextButton(
      onPressed: () {
        // Just close the drawer if user selects the current car.
        car.id == widget.currentCar.id
            ? Navigator.pop(context)
            : Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => CarDetailsPage(currentCar: car)));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dimensions.smallIconPadding),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: _statusIconPadding),
              width: _statusIconSize,
              height: _statusIconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _connectedCarsIds.contains(car.id)
                    ? Colors.green
                    : Theme.of(context).dividerColor,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _statusTitlePadding),
              child: Text(car.name, style: carNameStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _createConnectCarButton {
    final strings = StringLocalizations.of(context);
    return TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LookingForCarPage()),
      ),
      child: Row(
        children: [
          Icon(Icons.add, color: Theme.of(context).primaryColor),
          Padding(
            padding: const EdgeInsets.only(left: dimensions.smallIconPadding),
            child: Text(
              strings.addCarButtonLabel,
              style: Theme.of(context).textTheme.button,
            ),
          )
        ],
      ),
    );
  }

  void _showBottomSheet(context) {
    final strings = StringLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 208,
          child: Column(
            children: [
              ListTile(
                  leading: ImageIcon(AssetImage('assets/images/icon_edit.png')),
                  title: _buttomSheetText(strings.editNameLabel),
                  onTap: _navigateToEditNamePage),
              ListTile(
                  leading:
                      ImageIcon(AssetImage('assets/images/icon_delete.png')),
                  title: _buttomSheetText(strings.removeCarLabel),
                  onTap: _showConfirmRemoveDialog),
              ListTile(
                  leading:
                      ImageIcon(AssetImage('assets/images/icon_cancel.png')),
                  title: _buttomSheetText(strings.cancelButtonLabel),
                  onTap: () => Navigator.pop(context))
            ],
          ),
        );
      },
    );
  }

  Widget _buttomSheetText(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .subtitle1
          .apply(color: Theme.of(context).colorScheme.onBackground),
    );
  }

  void _navigateToEditNamePage() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => RenameCarPage(car: _currentCar)));
    Navigator.pop(context);
    _updateCarList();
  }

  void _updateCarList() async {
    final associatedCarsList = await _connectionManager.fetchAssociatedCars();
    setState(() {
      _associatedCars.addAll(associatedCarsList);
      _currentCar =
          _associatedCars.firstWhere((car) => car.id == _currentCar.id);
    });
  }

  void _showConfirmRemoveDialog() {
    final strings = StringLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.removeCarDialogTitle),
          content: Text(strings.removeCarDialogContent),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(strings.cancelButtonLabel,
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Theme.of(context).primaryColor)),
            ),
            TextButton(
              onPressed: _removeCurrentCar,
              child: Text(strings.removeButtonLabel,
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .apply(color: Colors.red[300])),
            ),
          ],
        );
      },
    );
  }

  void _updateCarListAndConnectionStatus() async {
    final associatedCars = await _connectionManager.fetchAssociatedCars();
    setState(() {
      _associatedCars.addAll(associatedCars);
      _updateConnectedCarList();
    });
  }

  void _removeCurrentCar() async {
    await _connectionManager.clearAssociation(_currentCar.id);

    final associatedCars = await _connectionManager.fetchAssociatedCars();

    MaterialPageRoute route;
    if (associatedCars.isEmpty) {
      route = MaterialPageRoute(builder: (_) => WelcomePage());
    } else {
      route = MaterialPageRoute(
        builder: (_) => CarDetailsPage(currentCar: associatedCars.first),
      );
    }

    // Remove all the previous pages out so that clicking the back button will
    // not go back to the association process again.
    await Navigator.pushAndRemoveUntil(context, route, (_) => false);
  }
}
