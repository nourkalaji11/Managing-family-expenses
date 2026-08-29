import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One row in the profile screen's action list: tinted glyph, label, optional
/// subtitle, trailing chevron.
///
/// The chevron is a plain `chevron_right`, which Flutter mirrors automatically
/// under an RTL directionality — the same reason the form screens rely on the
/// default `AppBar` leading rather than drawing their own arrow.
class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Renders the row in the error colour, for actions that end a session or
  /// destroy something.
  final bool destructive;

  /// Replaces the chevron with a spinner while the action runs.
  final bool busy;

  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.destructive = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(18.r);
    final Color ink = destructive
        ? ColorsApp.errorRed
        : ColorsApp.primaryGreenPressed;

    return Material(
      color: ColorsApp.white,
      borderRadius: radius,
      child: InkWell(
        // Disabled while busy, so a second tap cannot fire the action twice.
        onTap: busy ? null : onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20.r, color: ink),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyleApp.transactionsRowTitle.copyWith(
                          color: destructive
                              ? ColorsApp.errorRed
                              : ColorsApp.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle!,
                          style: TextStyleApp.transactionsRowSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                if (busy)
                  SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: CircularProgressIndicator(
                      color: ink,
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    size: 22.r,
                    color: ColorsApp.outline,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
