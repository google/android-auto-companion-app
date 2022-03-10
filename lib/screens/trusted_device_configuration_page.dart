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
import 'package:automotive_companion/screens/trust_agent_enrollment_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/trusted_device_manager.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Page to configure whether the phone should be unlocked first before the
/// trusted device feature activates.
class TrustedDeviceConfigurationPage extends StatefulWidget {
  final Car associatedCar;

  const TrustedDeviceConfigurationPage({Key? key, required this.associatedCar})
      : super(key: key);

  @override
  State createState() => _TrustedDeviceConfigurationPageState();
}

class _TrustedDeviceConfigurationPageState
    extends State<TrustedDeviceConfigurationPage> {
  var _isDeviceUnlockRequired = true;
  late TrustedDeviceManager _trustedDeviceManager;

  @override
  void initState() {
    super.initState();
    _trustedDeviceManager =
        Provider.of<TrustedDeviceManager>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        _trustedDeviceManager.stopTrustAgentEnrollment(widget.associatedCar);
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: dimensions.titleHorizontalPadding,
                  left: dimensions.titleHorizontalPadding,
                  bottom: dimensions.textSpacing,
                ),
                child: Text(
                  strings.quickUnlockTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.pageHorizontalPadding,
                ),
                child: Text(
                  strings.quickUnlockContent,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.all(dimensions.textSpacing),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(strings.quickUnlockSecureOptionLabel,
                          style: Theme.of(context).textTheme.bodyText2!.apply(
                              color:
                                  Theme.of(context).colorScheme.onBackground)),
                      subtitle: Text(strings.quickUnlockSecureOption,
                          style: Theme.of(context).textTheme.bodyText1),
                      trailing: Visibility(
                          visible: _isDeviceUnlockRequired,
                          child: Icon(Icons.check,
                              color: Theme.of(context).primaryColor)),
                      onTap: () => setState(() {
                        _isDeviceUnlockRequired = true;
                      }),
                    ),
                    ListTile(
                      title: Text(strings.quickUnlockConvenientOptionLabel,
                          style: Theme.of(context).textTheme.bodyText2!.apply(
                              color:
                                  Theme.of(context).colorScheme.onBackground)),
                      subtitle: Text(strings.quickUnlockConvenientOption,
                          style: Theme.of(context).textTheme.bodyText1),
                      trailing: Visibility(
                          visible: !_isDeviceUnlockRequired,
                          child: Icon(Icons.check,
                              color: Theme.of(context).primaryColor)),
                      onTap: () => setState(() {
                        _isDeviceUnlockRequired = false;
                      }),
                    )
                  ],
                ),
              ),
              Spacer(flex: 2),
              ButtonTheme(
                height: dimensions.actionButtonHeight,
                minWidth: dimensions.actionButtonWidth,
                child: RaisedButton(
                  textColor: Theme.of(context).colorScheme.background,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(dimensions.actionButtonRadius)),
                  onPressed: () {
                    _trustedDeviceManager.setDeviceUnlockRequired(
                        widget.associatedCar, _isDeviceUnlockRequired);
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TrustAgentEnrollmentPage(
                                associatedCar: widget.associatedCar)));
                  },
                  child: Text(strings.continueButtonLabel),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
