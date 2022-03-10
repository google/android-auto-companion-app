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

import 'package:automotive_companion/common_app_bar.dart';
import 'package:automotive_companion/messaging_channel_handler.dart';
import 'package:automotive_companion/screens/on_off_button.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main page which is the messaging setup page.
class MessagingSetupPage extends StatefulWidget {
  final bool messagingSyncEnabled;
  final String carId;

  const MessagingSetupPage(
      {Key? key, required this.messagingSyncEnabled, required this.carId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _MessagingSettingState(messagingSyncEnabled);
}

class _MessagingSettingState extends State<MessagingSetupPage> {
  late MessagingMethodChannelHandler _channelHandler;
  bool _messagingSyncEnabled = false;

  _MessagingSettingState(bool messagingSyncEnabled) {
    _messagingSyncEnabled = messagingSyncEnabled;
  }

  @override
  void initState() {
    super.initState();
    _channelHandler =
        Provider.of<MessagingMethodChannelHandler>(context, listen: false);
  }

  void _updateSyncState(bool isEnabled) {
    setState(() {
      _messagingSyncEnabled = isEnabled;
    });
    _channelHandler.setMessagingEnabled(widget.carId, _messagingSyncEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);
    return Scaffold(
      appBar: commonAppBar(
        context,
        title: strings.messagingFeatureSetupTitle,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
            top: dimensions.appBarBottomPadding,
            left: dimensions.featurePageHorizontalPadding,
            right: dimensions.featurePageHorizontalPadding,
            bottom: dimensions.pageBottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.messagingFeatureSetupSubtitle,
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: OnOffButton(
                  _messagingSyncEnabled ? strings.turnOff : strings.turnOn,
                  value: _messagingSyncEnabled,
                  onChanged: _updateSyncState,
                ),
              ),
              Visibility(
                visible: _messagingSyncEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(color: Theme.of(context).dividerColor),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: dimensions.textSpacing,
                      ),
                      child: Text(
                        strings.messagingFeatureSetupCTA,
                        style: Theme.of(context).textTheme.bodyText2,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
