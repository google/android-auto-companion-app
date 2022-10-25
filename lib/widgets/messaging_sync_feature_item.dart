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
import 'package:automotive_companion/messaging_channel_handler.dart';
import 'package:automotive_companion/screens/messaging_feature_intro_page.dart';
import 'package:automotive_companion/screens/messaging_setup_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'feature_item.dart';

/// Feature item that handles the messaging sync feature for the given
/// [currentCar].
class MessagingSyncFeatureItem extends StatefulWidget {
  final Car currentCar;

  MessagingSyncFeatureItem({Key key, @required this.currentCar})
      : super(key: key);

  @override
  State createState() => _MessagingSyncFeatureItemState();
}

class _MessagingSyncFeatureItemState extends State<MessagingSyncFeatureItem> {
  MessagingMethodChannelHandler _messagingChannelHandler;
  var _isMessagingSyncFeatureEnabled = false;
  Car _currentCar;

  @override
  void initState() {
    super.initState();
    _currentCar = widget.currentCar;
    _messagingChannelHandler =
        Provider.of<MessagingMethodChannelHandler>(context, listen: false);

    // The status of messaging sync only needs be triggered once. However, this
    // call is dependent on the BuildContext of this page, so wrap in a
    // PostFrameCallback to ensure it is available.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateMessagingSyncStatus());
  }

  void _updateMessagingSyncStatus() async {
    // Messaging sync is only available for Android devices.
    if (Theme.of(context).platform != TargetPlatform.android) return;

    final isMessagingSyncEnabled = await _messagingChannelHandler
        .isMessagingSyncFeatureEnabled(_currentCar.id);

    setState(() {
      _isMessagingSyncFeatureEnabled = isMessagingSyncEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return FeatureItem(
      onTap: () async {
        final nextPage = _isMessagingSyncFeatureEnabled
            ? MessagingSetupPage(
                messagingSyncEnabled: true, carId: _currentCar.id)
            : MessagingFeatureIntroPage(car: _currentCar);

        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => nextPage));

        // The state of messaging can be changed by the next page, so ensure
        // it is updated.
        _updateMessagingSyncStatus();
      },
      icon: Image(image: AssetImage('assets/images/icon_msg.png')),
      title: strings.messagingTitle,
      subtitle: strings.messagingExplanation,
      enabled: _isMessagingSyncFeatureEnabled,
    );
  }
}
