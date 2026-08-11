import 'dart:io';

import 'package:flutter/material.dart';

class DefaultSettings {
  static const int buildNumber = 1;
  static const String versionName = "1.0.0";

  static num uploadLimit = 20;
  static const int perPage = 10;

  static GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey(
    debugLabel: "Main Navigator",
  );

  static GlobalKey<ScaffoldState> scaffoldDashboardKey = GlobalKey();

  //TODO
  static String linkApp = Platform.isAndroid ? "" : "";

  //TODO
  static const String oneSignalAppId = "";

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];
}
