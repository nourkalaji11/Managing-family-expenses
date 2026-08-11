import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:family_expense_management/blocs/toggle_cubit.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/presentation/pages/auth/bloc/auth_bloc.dart';
import 'package:family_expense_management/presentation/widgets/custom_app_bar.dart';
import 'package:family_expense_management/presentation/widgets/main_button.dart';
import 'package:family_expense_management/presentation/widgets/password_field.dart';
import 'package:family_expense_management/presentation/widgets/text_field.dart';
import 'package:family_expense_management/presentation/widgets/text_phone_field.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/radius.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';
import 'package:family_expense_management/utils/service_locator.dart';
import 'package:family_expense_management/utils/validator.dart';

class Signup extends StatefulWidget {
  final String? referralCode;
  const Signup({super.key, this.referralCode});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool useEmail = true;
  final authBloc = getIt<AuthBloc>();
  final toggleBloc = getIt<ToggleCubit>();
  PhoneNumber? phone;

  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController email = TextEditingController();
  final TextEditingController fullName = TextEditingController();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  late final TextEditingController referralCode;

  @override
  void initState() {
    referralCode = TextEditingController(text: widget.referralCode);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ToggleCubit>.value(value: toggleBloc),
      ],
      child: Scaffold(
        appBar: CustomAppBar(title: "signup".tr()),
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
                      child: SvgPicture.asset("assets/images/signup.svg"),
                    ),
                  ),
                  Spaces.height20,
                  Text("fill_info".tr(), style: TextStyleApp.grey14500),
                  Spaces.height30,
                  CustomTextField(
                    hintText: "full_name".tr(),
                    textInputType: TextInputType.text,
                    validate: true,
                    prefix: SvgPicture.asset(
                      "assets/icons/user.svg",
                      colorFilter: const ColorFilter.mode(
                        ColorsApp.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                    controller: fullName,
                  ),
                  Spaces.height10,
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
                    controller: password,
                    hintText: "password".tr(),
                    validator: (value) {
                      if (value != null) {
                        return value.isNotEmpty &&
                                Validator.isAcceptedPassword(value)
                            ? value != confirmPassword.text
                                  ? "passwords_not_match".tr()
                                  : null
                            : "invalid_password".tr();
                      }
                      return null;
                    },
                  ),
                  Spaces.height10,
                  PasswordField(
                    controller: confirmPassword,
                    hintText: "confirm_password".tr(),
                    validator: (value) {
                      if (value != null) {
                        return value.isNotEmpty &&
                                Validator.isAcceptedPassword(value)
                            ? value != password.text
                                  ? "passwords_not_match".tr()
                                  : null
                            : "invalid_password".tr();
                      }
                      return null;
                    },
                  ),
                  Spaces.height10,
                  CustomTextField(
                    hintText: "referral_code".tr(),
                    textInputType: TextInputType.emailAddress,
                    prefix: SvgPicture.asset(
                      "assets/icons/override.svg",
                      colorFilter: const ColorFilter.mode(
                        ColorsApp.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                    controller: referralCode,
                  ),
                  Spaces.height10,
                  if (useEmail)
                    CustomTextField(
                      hintText: "email".tr(),
                      textInputType: TextInputType.emailAddress,
                      validator: (value) {
                        if (useEmail) {
                          if (value != null) {
                            return value.isEmpty
                                ? "required".tr()
                                : value.isNotEmpty && Validator.isEmail(value)
                                ? null
                                : "invalid_email".tr();
                          }
                        }
                        return null;
                      },
                      prefix: SvgPicture.asset(
                        "assets/icons/email.svg",
                        colorFilter: const ColorFilter.mode(
                          ColorsApp.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      controller: email,
                    ),
                  if (!useEmail)
                    PhoneField(
                      controller: phoneController,
                      invalidNumberMessage: "invalid_format".tr(),
                      dropdownIconPosition: IconPosition.trailing,
                      textAlign: TextAlign.start,
                      style: TextStyleApp.grey14500,
                      dropdownTextStyle: TextStyleApp.grey14500,
                      pickerDialogStyle: PickerDialogStyle(
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        countryNameStyle: TextStyleApp.grey14500,
                        countryCodeStyle: TextStyleApp.grey14500,
                      ),
                      showCountryFlag: true,
                      decoration: InputDecoration(hintText: "phone".tr()),
                      initialCountryCode: 'AE',
                      onSaved: (newValue) {
                        phone = newValue!;
                      },
                      onSubmitted: (term) {
                        FocusScope.of(context).unfocus();
                      },
                      onChanged: (newValue) {
                        phone = newValue;
                      },
                    ),
                  Spaces.height30,
                  InkWell(
                    onTap: () {
                      if (useEmail) {
                        setState(() {
                          useEmail = false;
                          email.clear();
                        });
                      } else {
                        setState(() {
                          useEmail = true;
                          phone = null;
                          phoneController.clear();
                        });
                      }
                    },
                    borderRadius: BorderRadiusApp.radius32,
                    child: Text(
                      useEmail
                          ? "use_phone_instead".tr()
                          : "use_email_instead".tr(),
                      style: TextStyleApp.red12500UnderLine,
                    ),
                  ),
                  Spaces.height30,
                  BlocBuilder<ToggleCubit, bool>(
                    bloc: toggleBloc,
                    builder: (context, state) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  toggleBloc.toggle();
                                },
                                child: Container(
                                  height: 18.r,
                                  width: 18.r,
                                  decoration: BoxDecoration(
                                    border: state
                                        ? null
                                        : Border.all(
                                            color: ColorsApp.grey,
                                            width: 1.r,
                                          ),
                                    borderRadius: BorderRadiusApp.radius32,
                                    color: state
                                        ? ColorsApp.red
                                        : Colors.transparent,
                                  ),
                                  child: state
                                      ? Icon(
                                          Icons.check,
                                          size: 18.r,
                                          color: ColorsApp.white,
                                        )
                                      : null,
                                ),
                              ),
                              Spaces.width10,
                              Text.rich(
                                TextSpan(
                                  text: "i_agree".tr(),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: "terms".tr(),
                                      style: TextStyleApp.red12300,
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // Navigator.push(
                                          //     context,
                                          //     MaterialPageRoute(
                                          //       builder: (context) =>
                                          //           const Terms(),
                                          //     ));
                                        },
                                    ),
                                  ],
                                ),
                                style: TextStyleApp.grey12300,
                              ),
                            ],
                          ),
                          Spaces.height16,
                          BlocListener<AuthBloc, AuthState>(
                            bloc: authBloc,
                            listener: (context, state) {
                              if (state is AuthLoading) {
                                EasyLoading.show();
                              } else if (state is AuthFailure) {
                                EasyLoading.dismiss();
                                EasyLoading.showError(state.error.message);
                              } else if (state is RegisterSuccess) {
                                EasyLoading.dismiss();
                                // Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) => OTP(
                                //         isFromLogin: false,
                                //         email: email.text,
                                //         phone: phone,
                                //         provider: useEmail
                                //             ? LoginProvider.email
                                //             : LoginProvider.phone,
                                //       ),
                                //     )).then(
                                //   (value) {
                                //     Navigator.pop(context);
                                //   },
                                // );
                              }
                            },
                            child: MainButton(
                              text: "create_account".tr(),
                              onClick: toggleBloc.state
                                  ? () {
                                      if (formKey.currentState!.validate()) {
                                        authBloc.add(
                                          OnRegister(
                                            name: fullName.text,
                                            email: email.text,
                                            password: password.text,
                                            passwordConfirmation:
                                                confirmPassword.text,
                                            // Legacy screen has no role picker,
                                            // so it registers the default role.
                                            role: AccountRole.parent,
                                            username: username.text,
                                            phone: phone?.completeNumber,
                                            referralCode: referralCode.text,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
