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
import 'package:automotive_companion/screens/trusted_device_intro_page.dart';
import 'package:automotive_companion/screens/trusted_device_settings_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/trusted_device_manager.dart';
import 'package:automotive_companion/widgets/feature_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Feature item that handles the trusted device feature for the given
/// [currentCar].
class TrustedDeviceFeatureItem extends StatefulWidget {
  final Car currentCar;

  const TrustedDeviceFeatureItem({Key? key, required this.currentCar})
      : super(key: key);

  @override
  State createState() => TrustedDeviceFeatureItemState();
}

@visibleForTesting
class TrustedDeviceFeatureItemState extends State<TrustedDeviceFeatureItem>
    implements TrustAgentCallback {
  late Car _currentCar;
  late TrustedDeviceManager _trustedDeviceManager;

  var _isTrustedDeviceEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentCar = widget.currentCar;

    _trustedDeviceManager =
        Provider.of<TrustedDeviceManager>(context, listen: false)
          ..registerTrustAgentCallback(this);

    _updateTrustedDeviceEnrollmentStatus();
  }

  @override
  void dispose() {
    super.dispose();
    _trustedDeviceManager.unregisterTrustAgentCallback(this);
  }

  void _updateTrustedDeviceEnrollmentStatus() async {
    var isTrustedDeviceEnabled =
        await _trustedDeviceManager.isTrustedDeviceEnrolled(_currentCar);
    setState(() {
      _isTrustedDeviceEnabled = isTrustedDeviceEnabled;
    });
  }

  @override
  void onEnrollmentCompleted(Car car) {
    if (car == _currentCar) {
      _updateTrustedDeviceEnrollmentStatus();
    }
  }

  @override
  void onEnrollmentError(Car car, EnrollmentError error) {
    // Ignored. An enrollment error on this page means that enrollment was
    // initiated from the IHU. So an appropriate error will be shown there
    // instead of the phone.
  }

  @override
  void onUnenroll(String carId) {
    if (carId == _currentCar.id) {
      _updateTrustedDeviceEnrollmentStatus();
    }
  }

  @override
  void onUnlockStatusChanged(String carId, UnlockStatus status) {
    // Ignored because this page does not show unlock information.
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return FeatureItem(
      onTap: () => _handleTrustedDeviceNavigation(),
      icon: Image(image: AssetImage('assets/images/icon_lock.png')),
      title: strings.shortUnlockExplanation,
      subtitle: strings.trustedDeviceFeatureExplanation,
      enabled: _isTrustedDeviceEnabled,
    );
  }

  void _handleTrustedDeviceNavigation() async {
    Widget nextPage;
    if (_isTrustedDeviceEnabled) {
      nextPage = TrustedDeviceSettingsPage(car: _currentCar);
    } else {
      nextPage = TrustedDeviceIntroPage(associatedCar: _currentCar);
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => nextPage));
    _updateTrustedDeviceEnrollmentStatus();
  }
}
