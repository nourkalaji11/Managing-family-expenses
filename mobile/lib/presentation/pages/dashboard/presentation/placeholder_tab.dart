import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Stand-in for the four tabs that are not built yet (المعاملات، الميزانية،
/// الحسابات، الفئات).
///
/// Exists so the shell's `PageView` has a real child per tab: an empty tab list
/// is what currently makes the dashboard route render nothing at all. Each of
/// these is replaced by its own feature screen as that feature is implemented.
class PlaceholderTab extends StatelessWidget {
  /// Translation key of the tab this stands in for, e.g. `tabs.transactions`.
  final String titleKey;

  const PlaceholderTab({super.key, required this.titleKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.dashboardBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_outlined,
                  size: 40.r,
                  color: ColorsApp.onSurfaceVariant,
                ),
                SizedBox(height: 12.h),
                Text(
                  titleKey.tr(),
                  style: TextStyleApp.dashboardSectionTitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  'dashboard.coming_soon'.tr(),
                  style: TextStyleApp.dashboardStatLabel,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
