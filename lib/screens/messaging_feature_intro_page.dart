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
import 'package:flutter_svg/svg.dart';

import '../car.dart';
import '../common_app_bar.dart';
import '../string_localizations.dart';
import '../values/dimensions.dart' as dimensions;
import 'messaging_notification_access_info.dart';

/// Main Page introducing the Text/MMS Messaging Feature.
class MessagingFeatureIntroPage extends StatelessWidget {
  final Car car;

  MessagingFeatureIntroPage({this.car}) : super();

  void _navigateTo(BuildContext context, Widget widget) async {
    if (context == null) {
      return;
    }
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return Scaffold(
      appBar: commonAppBar(context),
      body: Container(
        margin: EdgeInsets.only(
          top: dimensions.appBarBottomPadding,
          bottom: dimensions.pageBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions.titleHorizontalPadding,
              ),
              child: Text(
                strings.messagingFeatureIntroTitle,
                style: Theme.of(context).textTheme.headline3,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: dimensions.textSpacing,
                left: dimensions.pageHorizontalPadding,
                right: dimensions.pageHorizontalPadding,
              ),
              child: Text(
                strings.messagingFeatureIntroSubtitle,
                style: Theme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: dimensions.pageHorizontalPadding,
                right: dimensions.pageHorizontalPadding,
              ),
              child: Divider(color: Theme.of(context).dividerColor),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: dimensions.textSpacing,
                left: dimensions.pageHorizontalPadding,
                right: dimensions.pageHorizontalPadding,
              ),
              child: Text(
                strings.messagingFeatureIntroSubtitleTwo,
                style: Theme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(),
            SvgPicture.asset('assets/images/ill_msgSync.svg'),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions.pageHorizontalPadding,
              ),
              child: ElevatedButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.onPrimary),
                  overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Theme.of(context).primaryColorLight;
                        }
                        return null; // Defer to the widget's default.
                      }),
                ),
                onPressed: () {
                  _navigateTo(
                      context, MessagingNotificationAccessInfoPage(car: car));
                },
                child: Text(strings.actionContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
