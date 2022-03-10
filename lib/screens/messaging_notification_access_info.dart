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
import 'package:automotive_companion/messaging_channel_handler.dart';
import 'package:automotive_companion/screens/car_details_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main Page introducing the need for Notification access.
class MessagingNotificationAccessInfoPage extends StatelessWidget {
  final Car car;

  const MessagingNotificationAccessInfoPage({Key? key, required this.car})
      : super(key: key);

  void _navigateTo(BuildContext context, Widget widget) async {
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
                strings.messagingNotificationAccessTitle,
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
                strings.messagingNotificationAccessSubtitle,
                style: Theme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(),
            Image(image: AssetImage('assets/images/notification_access.png')),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions.pageHorizontalPadding,
              ),
              child: RaisedButton(
                textColor: Theme.of(context).colorScheme.onPrimary,
                splashColor: Theme.of(context).primaryColorLight,
                onPressed: () {
                  onSuccess() {
                    _navigateTo(context, CarDetailsPage(currentCar: car));
                  }

                  Provider.of<MessagingMethodChannelHandler>(context,
                          listen: false)
                      .enableMessagingSync(car.id,
                          onSuccess: onSuccess, onFailure: null);
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
