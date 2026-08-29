import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The five-tab bottom bar from the design: 80px tall, translucent white, a
/// hairline top border, and a filled-icon + green-label active state.
///
/// Replaces the old `widgets/bottom_bar/` pill bar, which came from the
/// template's chat application. Those files are intentionally left in the tree
/// (unused) until the cleanup step agreed after on-device testing.
class MainBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<MainTabs> onTabChange;

  /// Haptic tick on selection, matching the old bar's behaviour.
  final bool haptic;

  const MainBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    this.haptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsApp.white.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(
            color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80.h,
          child: Row(
            children: [
              for (final tab in MainTabs.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab.index == selectedIndex,
                    onTap: () {
                      if (haptic) HapticFeedback.selectionClick();
                      onTabChange(tab);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final MainTabs tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? ColorsApp.primaryGreenPressed
        : ColorsApp.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: tab.text.tr(),
      child: InkWell(
        onTap: onTap,
        // Transparent splashes keep the flat design intact.
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? tab.activeIcon : tab.iconData,
              size: 24.r,
              color: color,
            ),
            SizedBox(height: 4.h),
            // Padding + ellipsis so a long English label cannot overflow one
            // fifth of a narrow screen.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Text(
                tab.text.tr(),
                style: TextStyleApp.dashboardNavLabel.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
