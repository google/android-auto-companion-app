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
import 'package:automotive_companion/screens/trusted_device_intro_page.dart';
import 'package:automotive_companion/screens/unlock_history_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/trusted_device_manager.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _bodyPadding = 16.0;
const _buttonHeight = 36.0;
const _buttonWidth = 271.0;

/// Trusted device feature main page. Shows feature enrollment status and also
/// allows user to turn on/off the feature.
class TrustedDeviceSettingsPage extends StatefulWidget {
  final Car car;
  const TrustedDeviceSettingsPage({Key? key, required this.car})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TrustedDeviceSettingsState();
}

@visibleForTesting
class TrustedDeviceSettingsState extends State<TrustedDeviceSettingsPage>
    implements TrustAgentCallback {
  late TrustedDeviceManager _trustedDeviceManager;
  var _isTrustedDeviceEnabled = false;
  var _isDeviceUnlockRequired = true;
  var _shouldShowUnlockNotification = true;

  @override
  void initState() {
    super.initState();
    _trustedDeviceManager =
        Provider.of<TrustedDeviceManager>(context, listen: false);
    _trustedDeviceManager.registerTrustAgentCallback(this);
    _updateConfigurationAndStatus();
  }

  @override
  void dispose() {
    super.dispose();
    _trustedDeviceManager.unregisterTrustAgentCallback(this);
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);
    return Scaffold(
      appBar: commonAppBar(
        context,
        title: strings.shortUnlockExplanation,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: dimensions.featurePageTopPadding,
                      right: dimensions.featurePageHorizontalPadding,
                      left: dimensions.featurePageHorizontalPadding,
                    ),
                    child: Text(
                      strings.trustedDeviceExplanation,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                  _toggleButton(),
                ],
              ),
            ),
            _divider(),
            if (_isTrustedDeviceEnabled) ..._enabledEntries()
          ],
        ),
      ),
    );
  }

  @override
  void onEnrollmentCompleted(Car car) {
    if (car == widget.car) {
      _updateConfigurationAndStatus();
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
    if (carId == widget.car.id) {
      _updateConfigurationAndStatus();
    }
  }

  @override
  void onUnlockStatusChanged(String carId, UnlockStatus status) {
    // Ignored. Unlock status is not displayed on this page.
  }

  Widget _toggleButton() {
    final strings = StringLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.all(_bodyPadding),
      child: ButtonTheme(
        height: _buttonHeight,
        minWidth: _buttonWidth,
        child: RaisedButton(
          color: _isTrustedDeviceEnabled
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).primaryColor,
          textColor: _isTrustedDeviceEnabled
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onPrimary,
          onPressed: () async {
            if (_isTrustedDeviceEnabled) {
              _trustedDeviceManager.stopTrustAgentEnrollment(widget.car);
            } else {
              await _navigateToTrustedDeviceInfoPage();
            }
            _updateConfigurationAndStatus();
          },
          child:
              Text(_isTrustedDeviceEnabled ? strings.turnOff : strings.turnOn),
        ),
      ),
    );
  }

  Future<void> _navigateToTrustedDeviceInfoPage() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TrustedDeviceIntroPage(associatedCar: widget.car)));
    _updateConfigurationAndStatus();
  }

  List<Widget> _enabledEntries() => [
        _unlockConfiguration(),
        _divider(),
        _recentActivity(),
        _unlockNotificationToggle(),
        _unlockNotificationExplanation()
      ];

  Widget _divider() => Divider(color: Theme.of(context).dividerColor);

  Widget _unlockConfiguration() {
    final strings = StringLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(bottom: dimensions.textSpacing),
      child: Column(
        children: [
          ListTile(
            title: Text(
              strings.quickUnlockConfigurationLabel,
              style: Theme.of(context)
                  .textTheme
                  .subtitle1!
                  .apply(color: Theme.of(context).colorScheme.onBackground),
            ),
          ),
          ListTile(
              title: Text(strings.quickUnlockSecureOption,
                  style: Theme.of(context).textTheme.bodyText1),
              trailing: Visibility(
                visible: _isDeviceUnlockRequired,
                child: Icon(Icons.check, color: Theme.of(context).primaryColor),
              ),
              onTap: () => setDeviceUnlockRequired(true)),
          ListTile(
              title: Text(strings.quickUnlockConvenientOption,
                  style: Theme.of(context).textTheme.bodyText1),
              trailing: Visibility(
                visible: !_isDeviceUnlockRequired,
                child: Icon(Icons.check, color: Theme.of(context).primaryColor),
              ),
              onTap: () => setDeviceUnlockRequired(false)),
          ListTile(
            title: Text(
                _isDeviceUnlockRequired
                    ? strings.secureOptionExplanation
                    : strings.convenientOptionExplanation,
                style: Theme.of(context).textTheme.bodyText2),
          ),
        ],
      ),
    );
  }

  void setDeviceUnlockRequired(bool isRequired) {
    _trustedDeviceManager.setDeviceUnlockRequired(widget.car, isRequired);
    setState(() {
      _isDeviceUnlockRequired = isRequired;
    });
  }

  Widget _recentActivity() {
    final strings = StringLocalizations.of(context);
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UnlockHistoryPage(car: widget.car)));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.featurePageHorizontalPadding,
          vertical: dimensions.textSpacing,
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: dimensions.smallIconPadding,
              ),
              child: Icon(
                Icons.access_time,
                size: dimensions.smallIconSize,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              strings.recentUnlockActivityTitle,
              style: Theme.of(context)
                  .textTheme
                  .subtitle1!
                  .apply(color: Theme.of(context).colorScheme.onBackground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unlockNotificationToggle() {
    final strings = StringLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.featurePageHorizontalPadding,
        vertical: dimensions.textSpacing,
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: dimensions.smallIconPadding,
            ),
            child: Icon(
              Icons.notifications_none,
              size: dimensions.smallIconSize,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Text(
            strings.unlockNotificationTitle,
            style: Theme.of(context)
                .textTheme
                .subtitle1!
                .apply(color: Theme.of(context).colorScheme.onBackground),
          ),
          Spacer(),
          Switch.adaptive(
            value: _shouldShowUnlockNotification,
            onChanged: (isToggled) {
              setState(() {
                _shouldShowUnlockNotification = isToggled;
                _trustedDeviceManager.setShowUnlockNotification(
                    widget.car, isToggled);
              });
            },
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _unlockNotificationExplanation() {
    final strings = StringLocalizations.of(context);
    return ListTile(
      title: Text(strings.unlockNotificationExplanation,
          style: Theme.of(context).textTheme.bodyText2),
    );
  }

  void _updateConfigurationAndStatus() async {
    final isTrustedDeviceEnabled =
        await _trustedDeviceManager.isTrustedDeviceEnrolled(widget.car);
    final isDeviceUnlockRequired =
        await _trustedDeviceManager.isDeviceUnlockRequired(widget.car);
    final shouldShowUnlockNotification =
        await _trustedDeviceManager.shouldShowUnlockNotification(widget.car);
    setState(() {
      _isTrustedDeviceEnabled = isTrustedDeviceEnabled;
      _isDeviceUnlockRequired = isDeviceUnlockRequired;
      _shouldShowUnlockNotification = shouldShowUnlockNotification;
    });
  }
}
