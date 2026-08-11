import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/radius.dart';
import 'package:family_expense_management/style/text_style.dart';

class MainButton extends StatelessWidget {
  final String text;
  final void Function()? onClick;
  final String? icon;
  final Color? background;
  final Color? iconColor;
  final TextStyle? textStyle;
  const MainButton({
    super.key,
    required this.text,
    required this.onClick,
    this.icon,
    this.background = ColorsApp.yellow,
    this.textStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick != null
          ? () {
              // SystemFunc.dismissKeyboard();
              onClick!();
            }
          : null,
      child: Container(
        height: 44.h,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: onClick != null ? background : ColorsApp.grey,
          borderRadius: BorderRadiusApp.radius32,
        ),
        padding: EdgeInsetsApp.symmetricV10H20,
        child: Center(
          child: Text(text, style: textStyle ?? TextStyleApp.white14500),
        ),
      ),
    );
  }
}
