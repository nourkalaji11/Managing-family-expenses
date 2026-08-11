import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';

class CustomEasyLoading {
  void configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.threeBounce
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = ColorsApp.white
      ..backgroundColor = ColorsApp.black
      ..indicatorColor = ColorsApp.white
      ..textColor = ColorsApp.white
      ..maskColor = ColorsApp.grey200.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false
      ..contentPadding = EdgeInsetsApp.symmetricV10H20
      ..loadingStyle = EasyLoadingStyle.custom
      ..maskType = EasyLoadingMaskType.custom
      ..userInteractions = false
      ..textStyle = const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: ColorsApp.white,
        fontWeight: FontWeight.w300,
      );
  }
}
