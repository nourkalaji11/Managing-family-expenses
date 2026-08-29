import 'package:flutter/material.dart';
import 'package:family_expense_management/style/colors.dart';

class Themes {
  static final theme = ThemeData(
    scaffoldBackgroundColor: ColorsApp.offwhite,
    brightness: Brightness.light,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    fontFamily: "Poppins",
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: ColorsApp.red,
      onPrimary: ColorsApp.white,
      secondary: ColorsApp.grey200,
      onSecondary: ColorsApp.black,
      error: ColorsApp.red,
      onError: ColorsApp.white,
      surface: ColorsApp.white,
      onSurface: ColorsApp.grey,
      onPrimaryFixed: ColorsApp.yellow,
    ),
  );
}
