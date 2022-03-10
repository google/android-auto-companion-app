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
import 'package:automotive_companion/screens/calendar_intro_page.dart';
import 'package:automotive_companion/screens/calendar_page.dart';
import 'package:automotive_companion/string_localizations.dart';
import 'package:automotive_companion/widgets/feature_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Feature item that handles the calendar sync feature for the given
/// [currentCar].
class CalendarSyncFeatureItem extends StatefulWidget {
  final Car currentCar;

  const CalendarSyncFeatureItem({Key? key, required this.currentCar})
      : super(key: key);

  @override
  State createState() => _CalendarSyncFeatureItemState();
}

class _CalendarSyncFeatureItemState extends State<CalendarSyncFeatureItem> {
  late CalendarSyncService _calendarSyncService;
  late Car _currentCar;

  var _isCalendarSyncFeatureEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentCar = widget.currentCar;
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: false);

    _updateCalendarSyncServiceStatus();
  }

  void _updateCalendarSyncServiceStatus() async {
    var isEnabled =
        await _calendarSyncService.isCarEnabled(carId: _currentCar.id);

    setState(() {
      _isCalendarSyncFeatureEnabled = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);

    return FeatureItem(
      onTap: () async {
        final hasPermissions = await _calendarSyncService.hasPermissions();
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => hasPermissions
                    ? CalendarPage(car: _currentCar)
                    : CalendarIntroPage(car: _currentCar)));
        // The CalendarSync feature state can be changed on the next page.
        // Ensure it is updated.
        _updateCalendarSyncServiceStatus();
      },
      icon: Image(image: AssetImage('assets/images/icon_cal.png')),
      title: strings.calendarsTitle,
      subtitle: strings.calendarsExplanation,
      enabled: _isCalendarSyncFeatureEnabled,
    );
  }
}
