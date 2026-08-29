import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';

/// Square checkbox plus an arbitrary label widget, so callers can pass either
/// plain text ("تذكرني على هذا الجهاز") or rich text with tappable links
/// (the terms row on the register screen).
class AuthCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;
  final CrossAxisAlignment alignment;

  const AuthCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: alignment,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 18.r,
            width: 18.r,
            decoration: BoxDecoration(
              color: value ? ColorsApp.primaryGreen : ColorsApp.white,
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(
                color: value ? ColorsApp.primaryGreen : ColorsApp.lightBorder,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check, size: 13.r, color: ColorsApp.white)
                : null,
          ),
        ),
        Spaces.width8,
        Expanded(child: label),
      ],
    );
  }
}
