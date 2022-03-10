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

import 'package:automotive_companion/calendar_sync_service.dart';
import 'package:automotive_companion/car.dart';
import 'package:automotive_companion/common_app_bar.dart';
import 'package:automotive_companion/screens/calendar_page.dart';
import 'package:automotive_companion/screens/open_settings_alert_dialog.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Page introducing the Calendar Sync Feature.
///
/// This page will also request calendar read permissions after the 'sync'
/// button is pressed. If the permissions are granted the user will be forwarded
/// to the calendar page, otherwise it will return to the calling page.
class CalendarIntroPage extends StatefulWidget {
  final Car car;

  const CalendarIntroPage({Key? key, required this.car}) : super(key: key);

  @override
  State createState() => _CalendarIntroPageState();
}

class _CalendarIntroPageState extends State<CalendarIntroPage> {
  late CalendarSyncService _calendarSyncService;

  @override
  void initState() {
    super.initState();
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return Scaffold(
      appBar: commonAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: dimensions.appBarBottomPadding,
                        right: dimensions.titleHorizontalPadding,
                        left: dimensions.titleHorizontalPadding,
                        bottom: dimensions.textSpacing,
                      ),
                      child: Text(
                        strings.calendarFeatureIntroTitle,
                        style: Theme.of(context).textTheme.headline4,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: dimensions.pageHorizontalPadding,
                      ),
                      child: Text(
                        strings.calendarFeatureIntroSubtitle,
                        style: Theme.of(context).textTheme.bodyText1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Spacer(),
                    // TODO(b/149678041): Placeholder, awaiting asset from UX.
                    Image(
                        image: AssetImage('assets/images/calendar_intro.png')),
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(
                        left: dimensions.pageHorizontalPadding,
                        right: dimensions.pageHorizontalPadding,
                        bottom: dimensions.pageBottomPadding,
                      ),
                      child: RaisedButton(
                        textColor: Theme.of(context).colorScheme.background,
                        onPressed: _requestPermissionsAndProceed,
                        child: Text(strings.calendarFeatureIntroButtonText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _requestPermissionsAndProceed() async {
    final strings = StringLocalizations.of(context);
    // Permission has not been granted for this page to show.
    if (!await _calendarSyncService.requestPermissions()) {
      // The user may have selected to not be asked again. Ask again...
      await OpenSettingsAlert.showRequestingPermissionsDialog(
          context: context,
          title: strings.calendarPermissionsAlertDialogTitle,
          content: strings.calendarPermissionsAlertDialogContent);
    }

    if (await _calendarSyncService.hasPermissions()) {
      await _calendarSyncService.enableCar(carId: widget.car.id);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CalendarPage(car: widget.car),
        ),
      );
    }
    Navigator.pop(context);
  }
}
