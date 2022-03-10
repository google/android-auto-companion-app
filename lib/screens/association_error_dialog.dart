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

import 'package:automotive_companion/string_localizations.dart';
import 'package:flutter/material.dart';

/// An [AlertDialog] that conveys to the user that there was an error trying
/// to associate with the remote vehicle.
///
/// Use this dialog when there is an unrecoverable error during association.
/// The dialog will prompt the user to restart the association process and
/// simply dismisses itself when its button is pressed.
///
/// Simple usage:
///
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => ConnectionErrorDialog(),
/// );
/// ```
class AssociationErrorDialog extends StatelessWidget {
  const AssociationErrorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.associationErrorDialogTitle),
      content: Text(strings.associationErrorDialogBody),
      actions: [
        FlatButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            strings.associationErrorDialogConfirmButton,
            style: Theme.of(context).textTheme.button,
          ),
        ),
      ],
    );
  }
}
