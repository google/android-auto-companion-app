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

import 'package:automotive_companion/car.dart';
import 'package:automotive_companion/common_app_bar.dart';
import 'package:automotive_companion/screens/car_not_connected_dialog.dart';
import 'package:automotive_companion/screens/open_settings_alert_dialog.dart';
import 'package:automotive_companion/screens/trust_agent_error_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/trusted_device_manager.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

/// How long to wait for a response from the car before prompting the user with
/// a button to retry association.
const _waitingForResponseTimeout = Duration(seconds: 8);
const _loadingTextVerticalPadding = 10.0;

/// Page that handles the explicit enrollment into the trust agent feature.
class TrustAgentEnrollmentPage extends StatefulWidget {
  final Car associatedCar;

  const TrustAgentEnrollmentPage({Key? key, required this.associatedCar})
      : super(key: key);

  @override
  State createState() => TrustAgentEnrollmentState();
}

class TrustAgentEnrollmentState extends State<TrustAgentEnrollmentPage>
    implements TrustAgentCallback {
  late TrustedDeviceManager _trustedDeviceManager;

  /// A timer that starts after an enrolment has started and determines when a
  /// retry button should be shown.
  Timer? _retryTimer;
  bool _showRetryButton = false;

  /// `true` if the user has issued a request to retry enrollment.
  bool _isRetry = false;

  @override
  void initState() {
    super.initState();
    _trustedDeviceManager =
        Provider.of<TrustedDeviceManager>(context, listen: false);
    _trustedDeviceManager.registerTrustAgentCallback(this);
    _trustedDeviceManager.enrollTrustAgent(widget.associatedCar);
    _startRetryTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _retryTimer?.cancel();
    _trustedDeviceManager.unregisterTrustAgentCallback(this);
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        _trustedDeviceManager.stopTrustAgentEnrollment(widget.associatedCar);
        Navigator.of(context).pop();
        return true;
      },
      child: Scaffold(
        appBar: commonAppBar(
          context,
          onBackPressed: () {
            Navigator.pop(context);
            _trustedDeviceManager
                .stopTrustAgentEnrollment(widget.associatedCar);
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: dimensions.titleHorizontalPadding,
                  left: dimensions.titleHorizontalPadding,
                  bottom: dimensions.textSpacing,
                ),
                child: Text(
                  _isRetry
                      ? strings.resendEnrollmentTitle
                      : strings.enrollingTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.pageHorizontalPadding,
                ),
                child: Text(
                  _isRetry
                      ? strings.resendEnrollmentBody
                      : strings.enrollingExplanation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Spacer(),
              SvgPicture.asset('assets/images/ill_carScreenNotification.svg'),
              Spacer(),
              _showRetryButton
                  ? _retryEnrollmentButton
                  : _enrollmentLoadingText,
            ],
          ),
        ),
      ),
    );
  }

  Widget get _retryEnrollmentButton {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.pageHorizontalPadding,
      ),
      child: FlatButton(
        textColor: Theme.of(context).primaryColor,
        onPressed: () async {
          _trustedDeviceManager.stopTrustAgentEnrollment(widget.associatedCar);
          _trustedDeviceManager.enrollTrustAgent(widget.associatedCar);
          _startRetryTimer();

          setState(() {
            _showRetryButton = false;
            _isRetry = true;
          });
        },
        child:
            Text(StringLocalizations.of(context).resendEnrollmentButtonLabel),
      ),
    );
  }

  Widget get _enrollmentLoadingText {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _loadingTextVerticalPadding,
        horizontal: dimensions.pageHorizontalPadding,
      ),
      child: Text(
        StringLocalizations.of(context).enrollingLoadingLabel,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyText2,
      ),
    );
  }

  @override
  void onEnrollmentCompleted(Car car) {
    if (car == widget.associatedCar) {
      Navigator.pop(context);
    }
  }

  @override
  void onEnrollmentError(Car car, EnrollmentError error) async {
    if (car != widget.associatedCar) {
      return;
    }

    _trustedDeviceManager.stopTrustAgentEnrollment(car);
    await _displayUIForError(context, error);

    // After displaying the error, navigate back to the origin page so that
    // the user can resolve the issue.
    Navigator.pop(context);
  }

  @override
  void onUnenroll(String carId) {
    if (carId == widget.associatedCar.id) {
      Navigator.pop(context);
    }
  }

  /// Displays appropriate UI that corresponds to the given [error].
  ///
  /// This method will either notify the user of the error via a dialog or
  /// navigate to the generic error page. This navigation will be pushed on top
  /// of this page when this method is called.
  Future<void> _displayUIForError(
      BuildContext context, EnrollmentError error) async {
    switch (error) {
      case EnrollmentError.carNotConnected:
        await showDialog(
          context: context,
          builder: (_) => CarNotConnectedDialog(),
        );
        break;
      case EnrollmentError.passcodeNotSet:
        await OpenSettingsAlert.showPasscodeAlert(
          context: context,
          onCancelPressed: () => Navigator.pop(context),
        );
        break;
      default:
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => TrustAgentErrorPage()));
    }
  }

  @override
  void onUnlockStatusChanged(String carId, UnlockStatus status) {
    // No unlock should happen at this stage, so this can be ignored.
  }

  /// Starts a timer that will refresh the page with a retry button when it
  /// goes off.
  void _startRetryTimer() {
    _retryTimer?.cancel();

    _retryTimer = Timer(_waitingForResponseTimeout, () {
      setState(() {
        _showRetryButton = true;
      });
    });
  }
}
