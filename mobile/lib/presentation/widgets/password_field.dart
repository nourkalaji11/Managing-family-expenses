import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:family_expense_management/blocs/password_cubit.dart';
import 'package:family_expense_management/presentation/widgets/text_field.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/radius.dart';
import 'package:family_expense_management/utils/service_locator.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final String? title;
  final bool isDarkTheme;
  const PasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.title,
    this.isDarkTheme = true,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  final bloc = getIt<PasswordCubit>();
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<PasswordCubit, bool>(
        builder: (context, state) {
          return CustomTextField(
            validator: widget.validator,
            validate: true,
            controller: widget.controller,
            textInputType: TextInputType.visiblePassword,
            hintText: widget.hintText,
            showPassword: state,
            prefix: SvgPicture.asset(
              "assets/icons/password.svg",
              colorFilter: const ColorFilter.mode(
                ColorsApp.grey,
                BlendMode.srcIn,
              ),
            ),
            suffix: InkWell(
              onTap: () {
                bloc.togglePasswordVisibility();
              },
              borderRadius: BorderRadiusApp.radius32,
              child: SvgPicture.asset(
                state
                    ? "assets/icons/visible.svg"
                    : "assets/icons/unvisible.svg",
                width: 12.w,
                height: 12.w,
                colorFilter: const ColorFilter.mode(
                  ColorsApp.grey,
                  BlendMode.srcIn,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
