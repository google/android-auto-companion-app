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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'calendar_sync_service.dart';
import 'connection_manager.dart';
import 'messaging_channel_handler.dart';
import 'trusted_device_manager.dart';
import 'screens/car_details_page.dart';
import 'screens/welcome_page.dart';
import 'string_localizations.dart';

const _primaryColor = Color(0xFF8AB4F8);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final connectionManager = ConnectionManager();
  final associatedCars = await connectionManager.fetchAssociatedCars();

  Widget defaultHome = associatedCars.isEmpty
      ? WelcomePage()
      : CarDetailsPage(currentCar: associatedCars.first);

  final backgroundColor = Colors.grey[900];
  final mainTextColor = Colors.grey[50];
  final secondaryTextColor = Color(0xFF9AA0A6);

  final colorScheme = ColorScheme.dark().copyWith(
    primary: _primaryColor,
    primaryVariant: Color(0xff8ab4f8),
    background: backgroundColor,
    surface: Color(0xff282a2d),
    onPrimary: backgroundColor,
    onBackground: mainTextColor,
    onSecondary: secondaryTextColor,
    onSurface: mainTextColor,
    onError: backgroundColor,
  );

  final themeDataBase = ThemeData.from(
      colorScheme: colorScheme,
      textTheme: Typography.material2018().white.apply(
            displayColor: mainTextColor,
            bodyColor: secondaryTextColor,
          ));

  final app = MaterialApp(
    routes: {
      '/': (_) => defaultHome,
    },
    title: 'Companion App',
    localizationsDelegates: [
      IntlStringLocalizations.delegate,
      // Necessary to enable L10N for Material widgets.
      GlobalMaterialLocalizations.delegate,
      // Necessary to enable RTL support.
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('en', 'US'),
    ],
    theme: themeDataBase.copyWith(
      // If brightness is dark, ThemeData chooses the surface color for primary
      // and indicator color. Override this behavior.
      primaryColor: colorScheme.primary,
      indicatorColor: colorScheme.onPrimary,
      dividerColor: Color(0x1FFFFFFF),
      canvasColor: Color(0xff2B2C2F),
      toggleableActiveColor: _primaryColor,
      buttonTheme: themeDataBase.buttonTheme.copyWith(
        buttonColor: colorScheme.primary,
      ),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ConnectionManager>(create: (_) => ConnectionManager()),
        Provider<TrustedDeviceManager>(create: (_) => TrustedDeviceManager()),
        Provider<CalendarSyncService>(create: (_) => CalendarSyncService()),
        Provider<MessagingMethodChannelHandler>(
            create: (_) => MessagingMethodChannelHandler()),
      ],
      child: app,
    ),
  );
}
