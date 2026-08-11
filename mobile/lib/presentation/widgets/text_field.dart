import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/text_style.dart';
import 'package:family_expense_management/utils/system_func.dart';

class CustomTextField extends StatelessWidget {
  final bool validate;
  final TextEditingController? controller;
  final TextInputType textInputType;
  final bool multiLine;
  final int? lineCount;
  final String hintText;
  final void Function(String)? onChange;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final bool? showPassword;
  final Color? borderColor;
  final Widget? suffix;
  final bool enabled;
  final bool filled;
  final FocusNode? focusNode;
  const CustomTextField({
    super.key,
    this.controller,
    required this.textInputType,
    required this.hintText,
    this.multiLine = false,
    this.lineCount,
    this.validate = false,
    this.onChange,
    this.validator,
    this.prefix,
    this.showPassword,
    this.borderColor,
    this.suffix,
    this.enabled = true,
    this.filled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator:
          validator ??
          (validate
              ? (value) {
                  if (textInputType == TextInputType.number) {
                    if (value!.isEmpty || value == '') {
                      return "required".tr();
                    }
                  } else if (value!.isEmpty || value == '') {
                    return "required".tr();
                  }
                  return null;
                }
              : null),
      autovalidateMode: AutovalidateMode.disabled,
      controller: controller,
      style: TextStyleApp.grey14500,
      maxLines: multiLine ? null : 1,
      minLines: multiLine ? lineCount : null,
      keyboardType: textInputType,
      obscuringCharacter: "*",
      obscureText: showPassword != null ? !showPassword! : false,
      expands: false,
      scrollController: ScrollController(),
      textDirection: textInputType == TextInputType.emailAddress
          ? TextDirection.ltr
          : Directionality.of(context),
      textAlign: TextAlign.start,
      focusNode: focusNode,
      decoration: InputDecoration(
        enabled: enabled,
        filled: filled,
        fillColor: enabled
            ? ColorsApp.white
            : ColorsApp.grey200.withOpacity(0.5),
        contentPadding: EdgeInsets.fromLTRB(20.w, 35.h, 20.w, -10.h),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        errorStyle: TextStyleApp.errorStyle,
        errorMaxLines: 2,
        isDense: true,
        hintText: hintText,
        hintStyle: TextStyleApp.grey20014500,
        suffixIcon: suffix != null
            ? Container(
                margin: EdgeInsetsApp.symmetricH12,
                padding: EdgeInsetsApp.symmetricV4,
                child: suffix,
              )
            : null,
        prefixIcon: prefix != null
            ? Container(
                margin: EdgeInsetsApp.symmetricH20,
                padding: EdgeInsetsApp.symmetricV4,
                child: prefix,
              )
            : null,
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.r),
          borderSide: const BorderSide(color: ColorsApp.red),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.r),
          borderSide: const BorderSide(color: ColorsApp.red),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.r),
          borderSide: const BorderSide(color: ColorsApp.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.r),
          borderSide: const BorderSide(color: ColorsApp.grey200),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.r),
          borderSide: const BorderSide(color: ColorsApp.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.r),
          borderSide: const BorderSide(color: ColorsApp.yellow),
        ),
      ),
      onFieldSubmitted: (term) {
        SystemFunc.dismissKeyboard();
      },
      onChanged: (value) {
        if (onChange != null) {
          onChange!(value);
        }
      },
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }
}
