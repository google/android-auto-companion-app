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
import 'package:automotive_companion/values/dimensions.dart' as dimensions;
import 'package:flutter/material.dart';

const _verticalPadding = 25.0;
const _horizontalPadding = 16.0;

/// A widget that displays a row explaining a feature to the user.
///
/// When tapped, the [onTap] callback that is passed to this item will be
/// triggered. The widget will display the given [subtitle] that should
/// explain what the feature does. If [enabled] is `true`, then the row will
/// instead display an indicator that it has been turned on.
class FeatureItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: _verticalPadding,
            horizontal: _horizontalPadding,
          ),
          child: Container(child: _contentRow(context)),
        ),
      ),
    );
  }

  /// The actual contents of the row that displays the icon, title, subtitle and
  /// text indicating if the row is enabled or not.
  Widget _contentRow(BuildContext context) {
    final baseSubtitleStyle = Theme.of(context).textTheme.bodyText2;
    final subtitleStyle = enabled
        ? baseSubtitleStyle?.apply(color: Colors.green[300])
        : baseSubtitleStyle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: dimensions.smallIconPadding),
          child: icon,
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .apply(color: Theme.of(context).colorScheme.onBackground),
              ),
              Text(
                enabled ? StringLocalizations.of(context).featureOn : subtitle,
                style: subtitleStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
