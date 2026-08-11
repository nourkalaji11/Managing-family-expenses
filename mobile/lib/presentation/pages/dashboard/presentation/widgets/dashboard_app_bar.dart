import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/widgets/profile_avatar.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The fixed top bar: avatar + title on the leading side, bell on the trailing
/// side. 64px tall, translucent white with a hairline bottom border.
///
/// The design has no greeting line — just the app name.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationsPressed;

  const DashboardAppBar({super.key, this.onNotificationsPressed});

  @override
  Size get preferredSize => Size.fromHeight(64.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.h,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: ColorsApp.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Was a private `_ProfileAvatar` here; extracted to
          // `presentation/widgets/profile_avatar.dart` once the transactions
          // app bar needed the identical widget. Renders exactly as before.
          const ProfileAvatar(),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'dashboard.title'.tr(),
              style: TextStyleApp.dashboardAppBarTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onNotificationsPressed,
            iconSize: 24.r,
            color: ColorsApp.onSurface,
            icon: const Icon(Icons.notifications_none),
            tooltip: 'notifications'.tr(),
          ),
        ],
      ),
    );
  }
}
