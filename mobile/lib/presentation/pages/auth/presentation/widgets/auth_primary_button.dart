import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Full-width green call-to-action used by login and register.
///
/// While [isLoading] is true the button is inert, which is what prevents the
/// double submissions the auth Bloc would otherwise receive.
class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon = Icons.arrow_forward,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: Material(
        color: enabled ? ColorsApp.primaryGreen : ColorsApp.greyText,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 22.r,
                    width: 22.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorsApp.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(text, style: TextStyleApp.authButton),
                      if (trailingIcon != null) ...[
                        Spaces.width8,
                        // `textDirection: ltr` stops Flutter from mirroring the
                        // arrow in RTL; the design keeps it pointing right.
                        Icon(
                          trailingIcon,
                          textDirection: TextDirection.ltr,
                          color: ColorsApp.white,
                          size: 20.r,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
