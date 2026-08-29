import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/presentation/widgets/profile_avatar.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The transactions top bar: 64px, translucent white, hairline bottom border.
///
/// The design lays out [bell + avatar] on the leading side and the title
/// centred. Its third element, a `menu_open` button, is deliberately not
/// rendered: this app has no drawer, and a control that does nothing is worse
/// than an absent one.
class TransactionsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Overrides the bell's default navigation. Left for tests and for any caller
  /// that needs to intercept; the tab passes nothing.
  final VoidCallback? onNotificationsPressed;

  /// Overrides the avatar's default navigation, for the same reason.
  final VoidCallback? onProfilePressed;

  const TransactionsAppBar({
    super.key,
    this.onNotificationsPressed,
    this.onProfilePressed,
  });

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
          // 32px here, against the dashboard's 40px — the design draws this
          // avatar smaller (`w-8 h-8`).
          InkWell(
            onTap: onProfilePressed ??
                () => Navigator.of(context).pushNamed(AppRoutes.profile),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(6.r),
              child: const ProfileAvatar(size: 32),
            ),
          ),
          IconButton(
            onPressed: onNotificationsPressed ??
                () => Navigator.of(context).pushNamed(AppRoutes.notifications),
            iconSize: 22.r,
            color: ColorsApp.onSurfaceVariant,
            icon: const Icon(Icons.notifications_none),
            tooltip: 'notifications'.tr(),
          ),
          // Centres the title in the remaining space. `Expanded` + centre
          // alignment rather than a Stack, so a long title ellipsises instead
          // of colliding with the avatar.
          Expanded(
            child: Text(
              'tabs.transactions'.tr(),
              style: TextStyleApp.dashboardAppBarTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Balances the leading cluster so the title sits optically centred.
          SizedBox(width: 32.r),
        ],
      ),
    );
  }
}
