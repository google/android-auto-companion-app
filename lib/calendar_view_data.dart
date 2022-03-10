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

import 'dart:ui' show Color, hashValues;

/// Represents a calendar on the user's device, bundling all information that
/// are required in the UI.
class CalendarViewData {
  /// The unique identifier for this calendar.
  final String id;

  /// The name of this calendar.
  final String title;

  /// The color of this calendar.
  final Color? color;

  /// The name of the account that owns this calendar.
  ///
  /// For example, "someone@company.com".
  final String account;

  /// Whether the calendar should be marked in the UI as selected.
  bool isSelected = false;

  CalendarViewData(this.id, this.title, this.color, this.account);

  CalendarViewData.fromJson(Map<String, dynamic> json)
      : this(
          json['id'],
          json['title'],
          json['color'] != null ? Color(json['color']) : null,
          json['account'],
        );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'color': color?.value,
        'account': account,
      };

  @override
  bool operator ==(other) =>
      other is CalendarViewData &&
      other.id == id &&
      other.title == title &&
      other.color == color &&
      other.account == account;

  @override
  int get hashCode => hashValues(title, id, color, account);

  @override
  String toString() =>
      'CalendarViewData[id=$id, title=$title, color=$color, account=$account]';
}
