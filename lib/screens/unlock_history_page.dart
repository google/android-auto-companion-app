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

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../car.dart';
import '../common_app_bar.dart';
import '../string_localizations.dart';
import '../trusted_device_manager.dart';
import '../values/dimensions.dart' as dimensions;

const _screenBottomPadding = 15.0;

/// Page which shows the unlock history for the car.
class UnlockHistoryPage extends StatefulWidget {
  final Car car;

  UnlockHistoryPage({Key key, @required this.car}) : super(key: key);

  @override
  State createState() => UnlockHistoryPageState();
}

// The base class for the different types of items the list can contain.
abstract class ListItem {
  final DateTime date;

  ListItem(this.date);
}

// A ListItem that contains data for the section header.
class DateHeaderItem implements ListItem {
  @override
  final DateTime date;

  DateHeaderItem(this.date);
}

// A ListItem that contains data for the unlock event.
class UnlockTimeItem implements ListItem {
  @override
  final DateTime date;

  UnlockTimeItem(this.date);
}

@visibleForTesting
class UnlockHistoryPageState extends State<UnlockHistoryPage> {
  TrustedDeviceManager _trustedDeviceManager;
  final _unlockHistoryItems = <ListItem>[];
  final _dateFormatter = DateFormat.yMMMd();
  final _timeFormatter = DateFormat.jm();

  @override
  void initState() {
    super.initState();
    _trustedDeviceManager =
        Provider.of<TrustedDeviceManager>(context, listen: false);
    _fetchUnlockHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        context,
        title: StringLocalizations.of(context).recentUnlockActivityTitle,
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(
          top: dimensions.pageVerticalPadding,
          left: dimensions.pageHorizontalPadding,
          right: dimensions.pageHorizontalPadding,
          bottom: _screenBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The list of unlock activity events.
            Expanded(
              child: Scrollbar(child: _unlockHistoryList),
            ),
          ],
        ),
      ),
    );
  }

  /// The list of unlock history events.
  ListView get _unlockHistoryList {
    return ListView.builder(
      itemCount: _unlockHistoryItems.length,
      itemBuilder: (context, index) {
        final item = _unlockHistoryItems[index];

        if (item is DateHeaderItem) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _daysAgoText(item.date).toUpperCase(),
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Text(
                _dateFormatter.format(item.date).toUpperCase(),
                style: Theme.of(context).textTheme.subtitle1,
              )
            ],
          );
        } else if (item is UnlockTimeItem) {
          return ListTile(
              title: Text(
            _timeFormatter.format(item.date),
            style: Theme.of(context).textTheme.bodyText1.apply(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ));
        } else {
          throw ArgumentError('Unknown item type');
        }
      },
    );
  }

  String _daysAgoText(DateTime date) {
    final daysDiff = clock.now().difference(date).inDays;
    switch (daysDiff) {
      case 0:
        return StringLocalizations.of(context).today;
      case 1:
        return StringLocalizations.of(context).yesterday;
      default:
        return '$daysDiff ${StringLocalizations.of(context).daysAgo}';
    }
  }

  void _fetchUnlockHistory() async {
    final dates = await _trustedDeviceManager.fetchUnlockHistory(widget.car);

    setState(() {
      // Show the newest unlocks first, so sort from newest to oldest.
      final descendingDates = dates.reversed.toList();

      for (var i = 0; i < descendingDates.length; i++) {
        final currentDate = descendingDates[i];
        final currentDateTime =
            DateTime(currentDate.year, currentDate.month, currentDate.day);
        if (i == 0) {
          // Always add a header for the first item.
          _unlockHistoryItems.add(DateHeaderItem(currentDateTime));
        } else {
          final previousDate = descendingDates[i - 1];
          final previousDateTime =
              DateTime(previousDate.year, previousDate.month, previousDate.day);
          if (previousDateTime.difference(currentDateTime).inDays != 0) {
            // If new date is different from the previous, it gets its own
            // header.
            _unlockHistoryItems.add(DateHeaderItem(currentDateTime));
          }
        }

        // Always add the unlock event.
        _unlockHistoryItems.add(UnlockTimeItem(currentDate));
      }
    });
  }
}
