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

const _bigButtonHorizontalMargin = 40.0;
const _bigButtonVerticalMargin = 8.0;
const _bigButtonPadding = 16.0;

/// A [RaisedButton] with a margin that has on and off states.
///
/// Similar to a [Checkbox] the onChanged callback is passed the value that
/// should then be passed back to the constructor as [value].  The parent
/// [StatefulWidget] state should be updated by calling [State.setState].
class OnOffButton extends StatelessWidget {
  final String text;
  final ValueChanged<bool>? onChanged;
  final bool value;

  const OnOffButton(this.text, {Key? key, this.onChanged, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: _bigButtonHorizontalMargin,
          vertical: _bigButtonVerticalMargin),
      child: RaisedButton(
        padding: EdgeInsets.all(_bigButtonPadding),
        onPressed: (onChanged == null) ? null : () => onChanged?.call(!value),
        color: (value || onChanged == null)
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).primaryColor,
        textColor: (value || onChanged == null)
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onPrimary,
        child: Text(text),
      ),
    );
  }
}
