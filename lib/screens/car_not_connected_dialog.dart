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

import '../string_localizations.dart';

/// An [AlertDialog] that conveys to the user that an action cannot be taken
/// because the phone is not currently connected to the car.
///
/// Use this dialog when an active connection is required to perform a certain
/// action.
///
/// Simple usage:
///
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => CarNotConnectedDialog(),
/// );
/// ```
class CarNotConnectedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.carNotConnectedWarningTitle),
      content: Text(strings.carNotConnectedWarningContent),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: Navigator.of(context).pop,
          child: Text(strings.alertDialogOkButton),
        ),
      ],
    );
  }
}
