import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/presentation/pages/auth/bloc/auth_bloc.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/account_type_selector.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_card.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_checkbox.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_header.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_password_field.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_primary_button.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_text_field.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';
import 'package:family_expense_management/utils/service_locator.dart';
import 'package:family_expense_management/utils/validator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthBloc _authBloc = getIt<AuthBloc>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  /// Matches the design: "ولي أمر" is preselected.
  AccountRole _role = AccountRole.parent;
  bool _acceptedTerms = false;
  bool _termsError = false;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _showSoon("auth.terms_page_soon".tr());
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _showSoon("auth.terms_page_soon".tr());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _authBloc.close();
    super.dispose();
  }

  void _showSoon(String message) {
    EasyLoading.showToast(
      message,
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }

  void _submit() {
    final bool formValid = _formKey.currentState!.validate();
    // Surfaces the terms error alongside the field errors rather than after.
    setState(() => _termsError = !_acceptedTerms);
    if (!formValid || !_acceptedTerms) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _authBloc.add(
      OnRegister(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirmPassword.text,
        role: _role,
      ),
    );
  }

  String? _validateName(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return "auth.error_name_required".tr();
    }
    return null;
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
    if (!Validator.isAcceptedPassword(v)) {
      return "auth.error_password_short".tr();
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return "auth.error_password_confirm_required".tr();
    if (v != _password.text) return "auth.error_passwords_not_match".tr();
    return null;
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthFailure) {
      EasyLoading.showError(state.error.message);
    } else if (state is RegisterSuccess) {
      EasyLoading.dismiss();
      EasyLoading.showSuccess("auth.register_success".tr());

      // The registration contract is unconfirmed, so we do NOT assume the
      // response authenticated the user: `LocalUserCubit` is left untouched and
      // the user is sent to the login screen to sign in explicitly.
      //
      // TODO(backend): once the Laravel endpoint exists and is confirmed to
      // return a valid token in the `authorization` header together with a
      // complete user object, this can optionally become an automatic login —
      // update `LocalUserCubit` with `LocalsApp.user` and route to
      // `AppRoutes.dashboard` instead.
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.authBackground,
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
                    Spaces.height16,
                    AuthHeader(
                      icon: Icons.family_restroom,
                      title: "auth.register_title".tr(),
                      subtitle: "auth.register_subtitle".tr(),
                      boxSize: 56,
                      iconSize: 30,
                    ),
                    Spaces.height30,
                    AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "auth.register_heading".tr(),
                            style: TextStyleApp.authCardTitle,
                          ),
                          Spaces.height24,
                          AuthTextField(
                            fieldKey: const Key('auth_name_field'),
                            label: "auth.full_name".tr(),
                            hint: "auth.full_name_hint".tr(),
                            icon: Icons.person_outline,
                            controller: _name,
                            keyboardType: TextInputType.name,
                            validator: _validateName,
                          ),
                          Spaces.height16,
                          AuthTextField(
                            fieldKey: const Key('auth_email_field'),
                            label: "auth.email".tr(),
                            hint: "auth.email_hint".tr(),
                            icon: Icons.mail_outline,
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            fieldDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            validator: _validateEmail,
                          ),
                          Spaces.height16,
                          AccountTypeSelector(
                            value: _role,
                            onChanged: (role) => setState(() => _role = role),
                          ),
                          Spaces.height16,
                          AuthPasswordField(
                            fieldKey: const Key('auth_password_field'),
                            toggleKey: const Key('auth_password_toggle'),
                            label: "auth.password".tr(),
                            hint: "auth.password_hint".tr(),
                            controller: _password,
                            validator: _validatePassword,
                          ),
                          Spaces.height16,
                          AuthPasswordField(
                            fieldKey: const Key('auth_confirm_password_field'),
                            toggleKey: const Key(
                              'auth_confirm_password_toggle',
                            ),
                            label: "auth.confirm_password".tr(),
                            hint: "auth.password_hint".tr(),
                            icon: Icons.vpn_key_outlined,
                            controller: _confirmPassword,
                            validator: _validateConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          Spaces.height20,
                          _TermsRow(
                            accepted: _acceptedTerms,
                            showError: _termsError,
                            termsRecognizer: _termsRecognizer,
                            privacyRecognizer: _privacyRecognizer,
                            onChanged: (v) => setState(() {
                              _acceptedTerms = v;
                              if (v) _termsError = false;
                            }),
                          ),
                          Spaces.height20,
                          AuthPrimaryButton(
                            key: const Key('auth_register_button'),
                            text: "auth.create_account".tr(),
                            isLoading: isLoading,
                            onPressed: _submit,
                          ),
                          Spaces.height20,
                          _LoginPrompt(
                            onTap: () => Navigator.of(context).canPop()
                                ? Navigator.of(context).pop()
                                : Navigator.of(
                                    context,
                                  ).pushReplacementNamed(AppRoutes.login),
                          ),
                        ],
                      ),
                    ),
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

class _TermsRow extends StatelessWidget {
  final bool accepted;
  final bool showError;
  final ValueChanged<bool> onChanged;
  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;

  const _TermsRow({
    required this.accepted,
    required this.showError,
    required this.onChanged,
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthCheckbox(
          key: const Key('auth_terms_checkbox'),
          value: accepted,
          onChanged: onChanged,
          alignment: CrossAxisAlignment.start,
          label: Text.rich(
            TextSpan(
              text: "auth.accept_terms_prefix".tr(),
              style: TextStyleApp.authSmall,
              children: [
                TextSpan(
                  text: "auth.terms_of_use".tr(),
                  style: TextStyleApp.authLink,
                  recognizer: termsRecognizer,
                ),
                TextSpan(text: "auth.accept_terms_separator".tr()),
                TextSpan(
                  text: "auth.privacy_policy".tr(),
                  style: TextStyleApp.authLink,
                  recognizer: privacyRecognizer,
                ),
                TextSpan(text: "auth.accept_terms_suffix".tr()),
              ],
            ),
          ),
        ),
        if (showError) ...[
          Spaces.height6,
          Text(
            "auth.error_terms_required".tr(),
            style: TextStyleApp.authError,
          ),
        ],
      ],
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('auth_login_link'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Text.rich(
          TextSpan(
            text: "auth.already_have_account".tr(),
            style: TextStyleApp.authBody,
            children: [
              TextSpan(
                text: "auth.login_now".tr(),
                style: TextStyleApp.authLinkBody,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
