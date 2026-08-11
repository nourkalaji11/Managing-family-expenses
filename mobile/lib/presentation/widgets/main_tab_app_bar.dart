import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/widgets/profile_avatar.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The top bar shared by the main tabs: 64px, translucent white, hairline
/// bottom border, avatar and bell leading, title centred.
///
/// The designs draw a third element — a `menu`/`menu_open` button — which is
/// deliberately not rendered: this app has no drawer, and a control that does
/// nothing is worse than an absent one.
///
/// `TransactionsAppBar` predates this widget and is the same bar with its title
/// hard-coded. Folding it into this one is a separate cleanup: the transactions
/// feature is finished, and rewriting it is not this feature's job.
class MainTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Translation key of the tab's title, e.g. `tabs.budgets`.
  final String titleKey;

  final VoidCallback? onNotificationsPressed;

  const MainTabAppBar({
    super.key,
    required this.titleKey,
    this.onNotificationsPressed,
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
          // 32px, matching the design's `w-8 h-8`.
          const ProfileAvatar(size: 32),
          IconButton(
            onPressed: onNotificationsPressed,
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
          SizedBox(width: 32.r),
        ],
      ),
    );
  }
}
