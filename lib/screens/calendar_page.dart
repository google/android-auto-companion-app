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

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../calendar_sync_service.dart';
import '../calendar_view_data.dart';
import '../car.dart';
import '../common_app_bar.dart';
import '../string_localizations.dart';
import '../values/dimensions.dart' as dimensions;
import 'on_off_button.dart';
import 'open_settings_alert_dialog.dart';

/// Page for the calendar sync feature.
///
/// It shows a list of locally available calendars, allows the user to select
/// one or more that will be kept in sync with the head unit when connected.
class CalendarPage extends StatefulWidget {
  final Car car;

  CalendarPage({Key key, @required this.car}) : super(key: key);

  @override
  State createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarSyncService _calendarSyncService;
  Map<String, List<CalendarViewData>> _accountToCalendars;
  List<String> _selectedCalendarIds;
  bool _enabled;

  @override
  void initState() {
    super.initState();
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: false);
    _load();
  }

  void _load() async {
    try {
      var permissionsGranted = await _calendarSyncService.requestPermissions();
      if (!permissionsGranted) {
        await OpenSettingsAlert.showRequestingPermissionsDialog(
            context: context,
            title: _strings.calendarPermissionsAlertDialogTitle,
            content: _strings.calendarPermissionsAlertDialogContent);
        return;
      }

      final calendars = await _calendarSyncService.fetchCalendars();
      final enabled =
          await _calendarSyncService.isCarEnabled(carId: widget.car.id);
      final selectedCalendarIds = await _calendarSyncService
          .fetchCalendarIdsToSync(carId: widget.car.id);

      final accountToCalendars = <String, List<CalendarViewData>>{};
      for (var calendar in calendars) {
        accountToCalendars
            .putIfAbsent(calendar.account, () => [])
            .add(calendar);
      }
      // Make sure the list of calendars are sorted for each account.
      for (var calendar in accountToCalendars.values) {
        calendar.sort((a, b) => a.title.compareTo(b.title));
      }

      setState(() {
        _accountToCalendars = accountToCalendars;
        _selectedCalendarIds = List<String>.from(selectedCalendarIds);
        _enabled = enabled;
      });
    } on PlatformException catch (e) {
      log('Failed to retrieve calendars from CalendarSyncService: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        context,
        title: _strings.calendarScreenTitle,
      ),
      body: Container(
        margin: EdgeInsets.only(top: dimensions.featurePageTopPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _textItem(
              Text(
                _strings.calendarSyncDescription,
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ),
            if (_enabled != null) ..._content(),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _content() {
    return [
      Padding(
        padding: EdgeInsets.only(bottom: 12.0),
        child: OnOffButton(
          _enabled ? _strings.turnOff : _strings.turnOn,
          onChanged: _updateSyncState,
          value: _enabled,
        ),
      ),
      Expanded(
        // Do not allow calendars to be changed while fading.
        child: IgnorePointer(
          ignoring: !_enabled,
          child: AnimatedOpacity(
            opacity: _enabled ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _accountList(),
          ),
        ),
      )
    ];
  }

  void _updateSyncState(bool enable) {
    setState(() {
      _enabled = enable;
    });
    enable
        ? _calendarSyncService.enableCar(carId: widget.car.id)
        : _calendarSyncService.disableCar(carId: widget.car.id);
  }

  /// The list of accounts containing calendars.
  ///
  /// If no calendars are found on the device we'll let the users know.
  Widget _accountList() {
    if (_accountToCalendars.isEmpty) {
      return _textItem(Text(_strings.noCalendarsFound));
    }
    return ListView.builder(
      itemCount: _accountToCalendars.length,
      itemBuilder: (context, index) {
        final account = _accountToCalendars.keys.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(),
            _textItem(Text(
              account ?? _strings.calendarSyncDefaultAccount,
              style: Theme.of(context).textTheme.subtitle1,
            )),
            _calendarForAccount(account),
          ],
        );
      },
    );
  }

  /// The list of calendar's for the given account name.
  ///
  /// If no calendars are found on the device we'll let the users know.
  Widget _calendarForAccount(String account) {
    final calendars = _accountToCalendars[account];
    return Column(children: calendars.map(_calendarItem).toList());
  }

  /// A row within the list of calendars that displays the calendar's title and
  /// allows to select them for synchronization.
  Widget _calendarItem(CalendarViewData calendar) {
    return SwitchListTile(
      title: Text(
        calendar.title,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: Theme.of(context)
            .textTheme
            .bodyText1
            .apply(color: Theme.of(context).colorScheme.onBackground),
      ),
      secondary: _calendarColorIndicator(calendar.color),
      value: _selectedCalendarIds.contains(calendar.id),
      onChanged: (value) {
        setState(() {
          if (value) {
            _selectedCalendarIds.add(calendar.id);
          } else {
            _selectedCalendarIds.remove(calendar.id);
          }
        });
        _calendarSyncService.storeCalendarIdsToSync(_selectedCalendarIds,
            carId: widget.car.id);
      },
    );
  }

  Widget _calendarColorIndicator(Color color) {
    return Container(
      width: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  /// Sets up common padding for element on the page that only contains text.
  Widget _textItem(Text child) {
    return Padding(
      padding: const EdgeInsets.only(
        right: dimensions.featurePageHorizontalPadding,
        left: dimensions.featurePageHorizontalPadding,
        bottom: dimensions.textSpacing,
      ),
      child: child,
    );
  }

  /// Cannot be a final field because localizations can only be accessed after
  /// [initState].
  StringLocalizations get _strings => StringLocalizations.of(context);
}
