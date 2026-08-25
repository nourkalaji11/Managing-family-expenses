import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/blocs/local_user_cubit.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/presentation/pages/auth/bloc/auth_bloc.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_card.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_checkbox.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_divider.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_header.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_password_field.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_primary_button.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_text_field.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/social_login_button.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';
import 'package:family_expense_management/utils/service_locator.dart';
import 'package:family_expense_management/utils/validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthBloc _authBloc = getIt<AuthBloc>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  /// TODO(session): UI-only for now. Nothing reads this value yet — the token
  /// is always persisted by `AuthBloc` via `LocalStorage().saveUser(...)`
  /// regardless of the checkbox. Wiring it up requires a decision about session
  /// persistence (e.g. clearing the stored token on app close when unchecked),
  /// which is deliberately out of scope for this feature.
  bool _rememberMe = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _authBloc.close();
    super.dispose();
  }

  void _submit() {
    // Validation runs first, so an invalid form never reaches the API.
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _authBloc.add(
      OnLogin(email: _email.text.trim(), password: _password.text),
    );
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "auth.error_email_required".tr();
    if (!Validator.isEmail(v)) return "auth.error_email_invalid".tr();
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return "auth.error_password_required".tr();
    // TODO(backend): mirror the real Laravel rule once it is confirmed.
    // `Validator.isAcceptedPassword` is the project's existing 8-char rule.
    if (!Validator.isAcceptedPassword(v)) {
      return "auth.error_password_short".tr();
    }
    return null;
  }

  void _showSoon(String message) {
    EasyLoading.showToast(
      message,
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthFailure) {
      EasyLoading.showError(state.error.message);
    } else if (state is LoginSuccess) {
      EasyLoading.dismiss();
      // `LocalsApp.user` is populated by AuthBloc before this state is emitted.
      getIt<LocalUserCubit>().updateUser(LocalsApp.user);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.authBackground,
      // Lets the scroll view shrink when the keyboard opens instead of
      // overflowing.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          bloc: _authBloc,
          listener: _onStateChanged,
          builder: (context, state) {
            final bool isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: EdgeInsetsApp.symmetricV20H20,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Spaces.height24,
                    AuthHeader(
                      icon: Icons.account_balance,
                      title: "auth.login_title".tr(),
                      subtitle: "auth.login_subtitle".tr(),
                      boxSize: 64,
                      iconSize: 34,
                    ),
                    Spaces.height36,
                    AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthTextField(
                            fieldKey: const Key('auth_email_field'),
                            label: "auth.email".tr(),
                            hint: "auth.email_hint".tr(),
                            icon: Icons.mail_outline,
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            // Emails read left-to-right even in an RTL layout.
                            fieldDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            validator: _validateEmail,
                          ),
                          Spaces.height16,
                          AuthPasswordField(
                            fieldKey: const Key('auth_password_field'),
                            toggleKey: const Key('auth_password_toggle'),
                            label: "auth.password".tr(),
                            hint: "auth.password_hint".tr(),
                            controller: _password,
                            validator: _validatePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            labelTrailing: GestureDetector(
                              key: const Key('auth_forgot_password'),
                              onTap: () => _showSoon(
                                "auth.forgot_password_soon".tr(),
                              ),
                              child: Text(
                                "auth.forgot_password".tr(),
                                style: TextStyleApp.authLink,
                              ),
                            ),
                          ),
                          Spaces.height16,
                          AuthCheckbox(
                            key: const Key('auth_remember_me'),
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v),
                            label: Text(
                              "auth.remember_me".tr(),
                              style: TextStyleApp.authSmall,
                            ),
                          ),
                          Spaces.height20,
                          AuthPrimaryButton(
                            key: const Key('auth_login_button'),
                            text: "auth.login_button".tr(),
                            isLoading: isLoading,
                            onPressed: _submit,
                          ),
                          Spaces.height24,
                          AuthDivider(text: "auth.or_continue_with".tr()),
                          Spaces.height16,
                          Row(
                            children: [
                              Expanded(
                                child: SocialLoginButton.google(
                                  label: "auth.google".tr(),
                                  onPressed: () => _showSoon(
                                    "auth.social_not_available".tr(),
                                  ),
                                ),
                              ),
                              Spaces.width12,
                              Expanded(
                                child: SocialLoginButton.facebook(
                                  label: "auth.facebook".tr(),
                                  onPressed: () => _showSoon(
                                    "auth.social_not_available".tr(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Spaces.height24,
                    _RegisterPrompt(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.register),
                    ),
                    Spaces.height36,
                    const _LoginFooter(),
                    Spaces.height20,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const _RegisterPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('auth_register_link'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          text: "auth.no_account".tr(),
          style: TextStyleApp.authBody,
          children: [
            TextSpan(
              text: "auth.register_now".tr(),
              style: TextStyleApp.authLinkBody,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "${"auth.rights_reserved".tr()} 2026",
          style: TextStyleApp.authFooter,
          textAlign: TextAlign.center,
        ),
        Spaces.height4,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 12.r,
              color: ColorsApp.navy50,
            ),
            Spaces.width6,
            Flexible(
              child: Text(
                "auth.bank_grade_encryption".tr(),
                style: TextStyleApp.authFooter,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
