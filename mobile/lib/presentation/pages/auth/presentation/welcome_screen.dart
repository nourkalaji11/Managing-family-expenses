import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/main.dart';
import 'package:family_expense_management/presentation/pages/auth/bloc/auth_bloc.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/login_with_password.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/signup.dart';
import 'package:family_expense_management/presentation/widgets/main_button.dart';
import 'package:family_expense_management/style/decorations.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';
import 'package:family_expense_management/utils/apple_sign_controller.dart';
import 'package:family_expense_management/utils/google_sign_controller.dart';
import 'package:family_expense_management/utils/service_locator.dart';

class WelcomeScreen extends StatelessWidget {
  final String? referralCode;
  const WelcomeScreen({super.key, this.referralCode});

  @override
  Widget build(BuildContext context) {
    final authBloc = getIt<AuthBloc>();
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsetsApp.symmetricV20H20,
        child: MultiBlocProvider(
          providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
          child: BlocListener<AuthBloc, AuthState>(
            bloc: authBloc,
            listener: (context, state) {
              if (state is AuthLoading) {
                EasyLoading.show();
              } else if (state is AuthFailure) {
                EasyLoading.dismiss();
                EasyLoading.showError(state.error.message);
              } else if (state is SocialSignUpSuccess) {
                EasyLoading.dismiss();
                MyApp.restartApp(context);
              }
            },
            child: Column(
              children: [
                Spaces.height40,
                SizedBox(
                  height: 0.2.sh,
                  child: Center(
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 0.16.sh,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  "welcome_screen_message".tr(),
                  style: TextStyleApp.grey14500,
                ),
                Spaces.height20,
                buildBtn(
                  "assets/icons/google.svg",
                  "continue_google".tr(),
                  () async {
                    var token = await GoogleSignController.handleSignIn();
                    if (token != null) {
                      authBloc.add(
                        OnSocial(
                          provider: LoginProvider.google,
                          token: token,
                          fullName: null,
                          secretToken: null,
                          referralCode: referralCode,
                        ),
                      );
                    }
                  },
                ),
                Spaces.height10,
                if (Platform.isIOS) ...[
                  buildBtn(
                    "assets/icons/apple.svg",
                    "continue_apple".tr(),
                    () async {
                      var auth = await AppleSignController.handleSignIn();
                      if (auth != null) {
                        authBloc.add(
                          OnSocial(
                            provider: LoginProvider.apple,
                            token: auth.identityToken!,
                            secretToken: null,
                            fullName: auth.givenName,
                            referralCode: referralCode,
                          ),
                        );
                      }
                    },
                  ),
                  Spaces.height10,
                ],

                Spaces.height30,
                GestureDetector(
                  child: Container(
                    padding: EdgeInsetsApp.symmetricV10H20,
                    decoration: Decorations.borderRed,
                    child: Center(
                      child: Text("signup".tr(), style: TextStyleApp.red14500),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Signup(referralCode: referralCode),
                      ),
                    );
                  },
                ),
                Spaces.height16,
                MainButton(
                  text: "login".tr(),
                  onClick: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginWithPassword(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  buildBtn(String icon, String text, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsApp.symmetricV14H20,
        decoration: Decorations.borderGrey200,
        child: Row(
          children: [
            SvgPicture.asset(icon),
            Expanded(
              child: Center(child: Text(text, style: TextStyleApp.black14700)),
            ),
          ],
        ),
      ),
    );
  }
}
