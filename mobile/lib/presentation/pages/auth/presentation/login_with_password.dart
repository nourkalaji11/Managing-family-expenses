import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:family_expense_management/blocs/local_user_cubit.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/main.dart';
import 'package:family_expense_management/presentation/pages/auth/bloc/auth_bloc.dart';
import 'package:family_expense_management/presentation/widgets/custom_app_bar.dart';
import 'package:family_expense_management/presentation/widgets/main_button.dart';
import 'package:family_expense_management/presentation/widgets/password_field.dart';
import 'package:family_expense_management/presentation/widgets/text_field.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';
import 'package:family_expense_management/utils/service_locator.dart';

class LoginWithPassword extends StatefulWidget {
  const LoginWithPassword({super.key});

  @override
  State<LoginWithPassword> createState() => _LoginState();
}

class _LoginState extends State<LoginWithPassword> {
  final authBloc = getIt<AuthBloc>();
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
      child: Scaffold(
        appBar: CustomAppBar(title: "login".tr()),
        body: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            padding: EdgeInsetsApp.symmetricV20H20,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 0.3.sh,
                    child: Center(
                      child: SvgPicture.asset("assets/images/login.svg"),
                    ),
                  ),
                  Spaces.height10,
                  Text(
                    "enter_username_password".tr(),
                    style: TextStyleApp.grey14500,
                  ),
                  Spaces.height20,
                  CustomTextField(
                    hintText: "username".tr(),
                    textInputType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null) {
                        return value.isEmpty ? "required".tr() : null;
                      }
                      return null;
                    },
                    prefix: SvgPicture.asset(
                      "assets/icons/user.svg",
                      colorFilter: const ColorFilter.mode(
                        ColorsApp.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                    controller: username,
                  ),
                  Spaces.height10,
                  PasswordField(
                    hintText: "password".tr(),
                    validator: (value) {
                      if (value != null) {
                        return value.isEmpty ? "required".tr() : null;
                      }
                      return null;
                    },
                    controller: password,
                  ),
                  Spaces.height20,
                  BlocListener<AuthBloc, AuthState>(
                    bloc: authBloc,
                    listener: (context, state) {
                      if (state is AuthLoading) {
                        EasyLoading.show();
                      } else if (state is AuthFailure) {
                        EasyLoading.dismiss();
                        EasyLoading.showError(state.error.message);
                      } else if (state is LoginSuccess) {
                        EasyLoading.dismiss();
                        context.read<LocalUserCubit>().updateUser(
                          LocalsApp.user,
                        );
                        MyApp.restartApp(context);
                      }
                    },
                    child: MainButton(
                      text: "login".tr(),
                      onClick: () {
                        if (formKey.currentState!.validate()) {
                          authBloc.add(
                            OnLogin(
                              email: username.text,
                              password: password.text,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Spaces.height10,
                  Text("or".tr(), style: TextStyleApp.black12500),
                  Spaces.height30,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
