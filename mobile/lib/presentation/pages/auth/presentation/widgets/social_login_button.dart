import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Outlined social provider button.
///
/// This widget is presentation only. No social SDK is wired to it: the project
/// has `GoogleSignController` / `AppleSignController`, but the Google client id
/// and the backend `social` contract are not configured, so the auth screens
/// pass a handler that shows an informational message instead.
class SocialLoginButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  /// Google has no Material brand glyph, so the design's coloured "G" is drawn
  /// with text rather than pulling in a brand asset.
  factory SocialLoginButton.google({
    Key? key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SocialLoginButton(
      key: key,
      label: label,
      onPressed: onPressed,
      icon: Text(
        'G',
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: ColorsApp.googleBlue,
        ),
      ),
    );
  }

  factory SocialLoginButton.facebook({
    Key? key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SocialLoginButton(
      key: key,
      label: label,
      onPressed: onPressed,
      icon: Icon(Icons.facebook, size: 20.r, color: ColorsApp.facebookBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorsApp.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 48.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorsApp.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              Spaces.width8,
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleApp.authSocial,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
