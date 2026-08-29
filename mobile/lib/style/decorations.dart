import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/radius.dart';

class Decorations {
  static BoxDecoration whiteBorderTop = BoxDecoration(
    color: ColorsApp.white,
    border: Border.fromBorderSide(BorderSide(color: ColorsApp.grey200)),
    borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
  );

  static BoxDecoration borderGrey200 = BoxDecoration(
    borderRadius: BorderRadiusApp.radius32,
    border: Border.all(color: ColorsApp.grey200),
  );

  static BoxDecoration whiteBorderGrey200 = BoxDecoration(
    color: ColorsApp.white,
    borderRadius: BorderRadiusApp.radius32,
    border: Border.all(color: ColorsApp.grey200),
  );

  static BoxDecoration white = BoxDecoration(
    color: ColorsApp.white,
    borderRadius: BorderRadiusApp.radius32,
  );

  static BoxDecoration borderRed = BoxDecoration(
    borderRadius: BorderRadiusApp.radius32,
    border: Border.all(color: ColorsApp.red),
  );

  static BoxDecoration borderYellow = BoxDecoration(
    borderRadius: BorderRadiusApp.radius32,
    border: Border.all(color: ColorsApp.yellow, width: 1.w),
  );

  static BoxDecoration lightYellowBorderYellow = BoxDecoration(
    color: ColorsApp.lightYellow,
    borderRadius: BorderRadiusApp.radius32,
    border: Border.all(color: ColorsApp.yellow, width: 1.w),
  );

  static BoxDecoration borderLightYellow = BoxDecoration(
    borderRadius: BorderRadiusApp.radius32,
    border: Border.all(color: ColorsApp.yellow.withOpacity(0.5), width: 1.w),
  );

  static BoxDecoration lightYellow = BoxDecoration(
    color: ColorsApp.lightYellow,
    borderRadius: BorderRadiusApp.radius32,
  );

  static BoxDecoration red = BoxDecoration(
    color: ColorsApp.red,
    borderRadius: BorderRadiusApp.radius32,
  );

  static BoxDecoration grey200 = BoxDecoration(
    color: ColorsApp.grey200,
    borderRadius: BorderRadiusApp.radius32,
  );
}
