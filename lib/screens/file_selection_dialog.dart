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

/// Generic wrapper to track whether an item in the list is selected.
class ListItem<T> {
  bool isSelected = false;
  T value;
  ListItem(this.value);
}

/// Provider of the items wrapping a list of strings to be displayed in a
/// `TextItemsList`.
class TextItemsProvider {
  List<dynamic> items = []; // Label wrappers tracking selection.
  TextItemsProvider(List<String> labels) {
    for (var label in labels) {
      items.add(ListItem<String>(label));
    }
  }
  List getSelectedLabels() {
    var names = [];
    for (var item in items) {
      if (item.isSelected) {
        names.add(item.value);
      }
    }
    return names;
  }
}

/// Widget displaying a list of selectable text items.
class TextItemsList extends StatefulWidget {
  final items;
  TextItemsList(this.items);
  @override
  State<StatefulWidget> createState() => _TextItemsState(items);
}

/// State managing the list of selected items and their display.
class _TextItemsState extends State {
  final items;
  _TextItemsState(this.items);
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: items.length, itemBuilder: getListViewRow);
  }

  Widget getListViewRow(BuildContext context, int index) {
    final item = items[index];
    return Container(
      child: ListTile(
        leading: Checkbox(
          value: item.isSelected,
          onChanged: (newValue) {
            setState(() {
              item.isSelected = newValue;
            });
          },
        ),
        title: Text(
          item.value,
          style: Theme.of(context).textTheme.subtitle1,
        ),
      ),
    );
  }
}
