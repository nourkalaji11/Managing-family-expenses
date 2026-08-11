import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Branded header shared by the login and register screens: a rounded green
/// logo tile followed by a title and a subtitle.
class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double boxSize;
  final double iconSize;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.boxSize = 60,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: boxSize.r,
          width: boxSize.r,
          decoration: BoxDecoration(
            color: ColorsApp.primaryGreen,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2600805E),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: ColorsApp.white, size: iconSize.r),
        ),
        Spaces.height16,
        Text(
          title,
          style: TextStyleApp.authTitle,
          textAlign: TextAlign.center,
        ),
        Spaces.height4,
        Text(
          subtitle,
          style: TextStyleApp.authSubtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
