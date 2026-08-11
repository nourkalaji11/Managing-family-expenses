import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignController {
  static Future<AuthorizationCredentialAppleID?> handleSignIn() async {
    try {
      AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      print(credential.givenName);
      print(credential.familyName);
      return credential;
    } on SignInWithAppleAuthorizationException catch (e) {
      print(e.code);
      if (e.code == AuthorizationErrorCode.unknown) {
        return null;
      } else {
        EasyLoading.showError("errorglobal".tr());
        return null;
      }
    } catch (err) {
      print(err);
      EasyLoading.showError("errorglobal".tr());
      return null;
    }
  }
}
