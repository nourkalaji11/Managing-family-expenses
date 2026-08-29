import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/blocs/password_cubit.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_text_field.dart';
import 'package:family_expense_management/style/colors.dart';

/// [AuthTextField] with a visibility toggle.
///
/// Each instance owns a private [PasswordCubit] created through `BlocProvider`,
/// so login and register can host several password fields without their toggles
/// interfering with each other. `BlocProvider.create` also closes the cubit for
/// us when the field leaves the tree.
class AuthPasswordField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? labelTrailing;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Key? fieldKey;
  final Key? toggleKey;

  const AuthPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.icon = Icons.lock_outline,
    this.hint,
    this.validator,
    this.labelTrailing,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.fieldKey,
    this.toggleKey,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PasswordCubit>(
      create: (_) => PasswordCubit(),
      child: BlocBuilder<PasswordCubit, bool>(
        builder: (context, isVisible) {
          return AuthTextField(
            fieldKey: fieldKey,
            label: label,
            hint: hint,
            icon: icon,
            controller: controller,
            validator: validator,
            labelTrailing: labelTrailing,
            obscureText: !isVisible,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            suffix: IconButton(
              key: toggleKey,
              onPressed: () =>
                  context.read<PasswordCubit>().togglePasswordVisibility(),
              splashRadius: 20.r,
              icon: Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20.r,
                color: ColorsApp.greyText,
              ),
            ),
          );
        },
      ),
    );
  }
}
