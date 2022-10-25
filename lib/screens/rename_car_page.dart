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
import 'package:provider/provider.dart';

import '../car.dart';
import '../common_app_bar.dart';
import '../connection_manager.dart';
import '../string_localizations.dart';

const _bodyPadding = 16.0;
const _topPadding = 52.0;

/// Car rename page, user can edit and save the current car name in this page.
class RenameCarPage extends StatefulWidget {
  final Car car;
  RenameCarPage({Key key, @required this.car}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _RenameCarPageState();
}

class _RenameCarPageState extends State<RenameCarPage> {
  ConnectionManager _connectionManager;
  final _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    _textFieldController.text = widget.car.name;
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = StringLocalizations.of(context);
    return Scaffold(
      appBar: commonAppBar(
        context,
        title: strings.renamePageTitle,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () async {
              var success = await _connectionManager.renameCar(
                  widget.car.id, _textFieldController.text);
              if (success) {
                Navigator.pop(context);
              }
            },
            child: Text(strings.saveButtonLabel),
          )
        ],
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.only(
            top: _topPadding,
            left: _bodyPadding,
            right: _bodyPadding,
          ),
          child: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).primaryColorDark,
              suffixIcon: IconButton(
                onPressed: () => WidgetsBinding.instance
                    .addPostFrameCallback((_) => _textFieldController.clear()),
                icon: Icon(Icons.clear),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
