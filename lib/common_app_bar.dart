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
import 'string_localizations.dart';

/// Creates an [AppBar] that provides consistent styling across this
/// application.
///
/// The returned `AppBar` handles the all common styling and text as dictated
/// by the given [context].
///
/// The [onBackPressed] will be invoked when the back button is pressed. If no
/// callback is passed here, then the generated `AppBar` will attempt to
/// navigate back to the previous page
///
/// An optional [title] can also be passed to the `AppBar`. If none is provided,
/// there will be default text.
///
/// Lastly, an affordance for common [actions] is exposed.
AppBar commonAppBar(BuildContext context,
    {String title, VoidCallback onBackPressed, List<Widget> actions}) {
  return AppBar(
    // Title is only centered if there is text provided.
    centerTitle: title != null,
    titleSpacing: 0.0,
    elevation: 0.0,
    backgroundColor: Theme.of(context).backgroundColor,
    leading: BackButton(
      color: Theme.of(context).colorScheme.onBackground,
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
    ),
    title: Text(
      title ?? StringLocalizations.of(context).appBarBackLabel,
      style: Theme.of(context)
          .textTheme
          .headline6
          .copyWith(color: Theme.of(context).colorScheme.onBackground),
    ),
    actions: actions,
  );
}
