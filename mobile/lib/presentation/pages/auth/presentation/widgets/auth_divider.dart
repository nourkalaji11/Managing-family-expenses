import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Horizontal rule with a centred caption, e.g. "أو عبر".
class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: ColorsApp.lightBorder),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(text, style: TextStyleApp.authDivider),
        ),
        line,
      ],
    );
  }
}
