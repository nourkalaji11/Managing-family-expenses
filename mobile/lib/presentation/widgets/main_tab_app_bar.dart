import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/presentation/widgets/profile_avatar.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The top bar shared by the main tabs: 64px, translucent white, hairline
/// bottom border, avatar and bell leading, title centred.
///
/// Both leading controls now navigate. They used to be inert — the avatar had
/// no gesture at all and the bell raised a "coming soon" toast — because
/// neither destination existed. The navigation lives here rather than in each
/// tab so all five behave identically and a new tab gets it for free.
///
/// The designs draw a third element, a `menu`/`menu_open` button, which is
/// deliberately not rendered: this app has no drawer, and a control that does
/// nothing is worse than an absent one.
class MainTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Translation key of the tab's title, e.g. `tabs.budgets`.
  final String titleKey;

  /// Overrides the bell's default behaviour. Left for tests and for any caller
  /// that needs to intercept; production tabs pass nothing.
  final VoidCallback? onNotificationsPressed;

  /// Overrides the avatar's default behaviour, for the same reason.
  final VoidCallback? onProfilePressed;

  const MainTabAppBar({
    super.key,
    required this.titleKey,
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
          // 32px, matching the design's `w-8 h-8`. Wrapped so the whole avatar
          // is the target rather than a hairline around it — 44px is the
          // minimum comfortable touch size, and the avatar itself is 32.
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
              titleKey.tr(),
              style: TextStyleApp.dashboardAppBarTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Balances the leading cluster so the title sits optically centred.
          // Widened to match the avatar's new padding.
          SizedBox(width: 44.r),
        ],
      ),
    );
  }
}
