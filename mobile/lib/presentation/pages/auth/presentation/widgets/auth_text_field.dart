import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Filled input used across the auth screens.
///
/// The label sits *above* the field and the hint sits *inside* it, so the two
/// can never overlap (unlike the floating-label markup in the design preview).
/// In RTL the [icon] is rendered on the right because `prefixIcon` follows the
/// ambient [Directionality].
class AuthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;

  /// Optional widget pinned to the far side of the label row
  /// (used for "نسيت كلمة المرور؟").
  final Widget? labelTrailing;

  /// Forces the typed text direction. Emails are entered LTR.
  final TextDirection? fieldDirection;
  final TextAlign textAlign;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Key? fieldKey;

  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.labelTrailing,
    this.fieldDirection,
    this.textAlign = TextAlign.start,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.fieldKey,
  });

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.r),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyleApp.authFieldLabel),
            if (labelTrailing != null) ...[const Spacer(), labelTrailing!],
          ],
        ),
        Spaces.height6,
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          obscuringCharacter: '•',
          textDirection: fieldDirection,
          textAlign: textAlign,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: TextStyleApp.authInput,
          cursorColor: ColorsApp.primaryGreen,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            filled: true,
            fillColor: ColorsApp.inputBackground,
            isDense: true,
            hintText: hint,
            hintStyle: TextStyleApp.authHint,
            errorStyle: TextStyleApp.authError,
            errorMaxLines: 2,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 16.h,
            ),
            prefixIcon: Icon(icon, size: 20.r, color: ColorsApp.greyText),
            prefixIconConstraints: BoxConstraints(minWidth: 44.w),
            suffixIcon: suffix,
            suffixIconConstraints: BoxConstraints(minWidth: 44.w),
            border: _border(Colors.transparent, 1),
            enabledBorder: _border(Colors.transparent, 1),
            focusedBorder: _border(ColorsApp.primaryGreen, 1.5),
            errorBorder: _border(ColorsApp.red, 1),
            focusedErrorBorder: _border(ColorsApp.red, 1.5),
          ),
        ),
      ],
    );
  }
}
