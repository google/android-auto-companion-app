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

import 'package:automotive_companion/trusted_device_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection_manager.dart';
import '../string_localizations.dart';
import '../trusted_device_manager.dart';

/// An [AlertDialog] providing a way to open the platform-specific application
/// settings on the mobile device.
///
/// The dialog will have a [title] and [description] text, which can be set by
/// the caller.
///
/// The dialog also displays two buttons:
/// - `Open Settings`: will send the user to the platform specific app settings.
/// - `Cancel`: the action needs to be provided through [onCancelPressed]
///
/// Sample usage:
///
/// ```dart
///  OpenSettingsAlertDialog(
///    title: 'Permission Needed',
///    content: 'The app needs some permission to work',
///    onCancelPressed: () => Navigator.of(context).pop(),
///    onOpenPressed: () => Navigator.of(context).pop(),
/// ```
@visibleForTesting
class OpenSettingsAlertDialog extends StatelessWidget {
  OpenSettingsAlertDialog({
    Key key,
    @required this.title,
    @required this.content,
    @required this.onCancelPressed,
    @required this.onOpenPressed,
  }) : super(key: key);

  /// The title of the dialog is displayed in a large font at the top of the
  /// [AlertDialog].
  final String title;

  /// The content of the dialog is displayed in the center of the [AlertDialog]
  /// in a lighter font.
  final String content;

  /// A callback which will be invoked when the `Cancel` button is clicked.
  final VoidCallback onCancelPressed;

  /// A callback which will be invoked when the `Open Settings` button is
  /// clicked.
  final VoidCallback onOpenPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: Theme.of(context).textTheme.headline5),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancelPressed,
          child: Text(StringLocalizations.of(context).cancelButtonLabel,
              style: Theme.of(context).textTheme.button),
        ),
        TextButton(
          onPressed: onOpenPressed,
          child: Text(StringLocalizations.of(context).openSettingsLabel,
              style: Theme.of(context).textTheme.button),
        ),
      ],
    );
  }
}

/// Helper class to create standardized [OpenSettingsAlertDialog]s and also
/// enable opening different pages according to different requirements.
class OpenSettingsAlert {
  /// Shows an [OpenSettingsAlertDialog] about missing permissions.
  static Future<void> showRequestingPermissionsDialog(
      {@required BuildContext context,
      @required String title,
      @required String content}) async {
    // Require dialog to be explicitly dismissed by clicking the "Cancel"
    // button. This is because the dialog will trigger a navigation away from
    // this page. It can be jarring to users if the dialog is accidentally
    // dismissed.
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return OpenSettingsAlertDialog(
          title: title,
          content: content,
          onCancelPressed: () => Navigator.of(context).pop(),
          onOpenPressed: () =>
              Provider.of<ConnectionManager>(context, listen: false)
                ..openApplicationDetailsSettings(),
        );
      },
    );
  }

  /// Shows an [OpenSettingsAlertDialog] about unset passcode.
  static Future<void> showPasscodeAlert(
      {@required BuildContext context,
      @required VoidCallback onCancelPressed}) async {
    final strings = StringLocalizations.of(context);

    // Require dialog to be explicitly dismissed by clicking the "Cancel"
    // button. This is because the dialog will trigger a navigation away from
    // this page. It can be jarring to users if the dialog is accidentally
    // dismissed.
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return OpenSettingsAlertDialog(
            title: strings.passcodeAlertDialogTitle,
            content: strings.passcodeAlertDialogContent,
            onCancelPressed: onCancelPressed,
            onOpenPressed: () {
              Provider.of<TrustedDeviceManager>(context, listen: false)
                ..openSecuritySettings();
              Navigator.of(context).pop();
            });
      },
    );
  }
}
