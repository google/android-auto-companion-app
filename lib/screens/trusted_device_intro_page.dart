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
import 'package:flutter_svg/flutter_svg.dart';

import 'package:automotive_companion/car.dart';
import 'package:automotive_companion/common_app_bar.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:automotive_companion/screens/trusted_device_configuration_page.dart';

/// Page introducing the Trusted Device Feature.
class TrustedDeviceIntroPage extends StatelessWidget {
  final Car associatedCar;

  const TrustedDeviceIntroPage({Key? key, required this.associatedCar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return Scaffold(
      appBar: commonAppBar(
        context,
        onBackPressed: () {
          Navigator.pop(context);
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
                strings.trustedDeviceFeatureIntroTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions.pageHorizontalPadding,
              ),
              child: Text(
                strings.trustedDeviceFeatureIntroContent,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            Spacer(),
            SvgPicture.asset('assets/images/phone_unlock.svg'),
            Spacer(),
            ButtonTheme(
              height: dimensions.actionButtonHeight,
              minWidth: dimensions.actionButtonWidth,
              child: RaisedButton(
                textColor: Theme.of(context).colorScheme.background,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(dimensions.actionButtonRadius)),
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TrustedDeviceConfigurationPage(
                              associatedCar: associatedCar)));
                },
                child: Text(strings.continueButtonLabel),
              ),
            )
          ],
        ),
      ),
    );
  }
}
