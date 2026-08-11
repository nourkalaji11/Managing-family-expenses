import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/summary_stat_card.dart';
import 'package:family_expense_management/style/colors.dart';

/// الدخل / المصاريف / المتبقي.
///
/// Horizontally scrollable by design — the third card is deliberately clipped
/// at the viewport edge in the reference PNG, and scrolling is also what keeps
/// this row safe on narrow screens.
class FinancialSummaryStrip extends StatelessWidget {
  final DashboardSummary summary;

  /// Horizontal page padding, re-applied inside the scroll view so the first
  /// card starts flush with the rest of the content while still being able to
  /// scroll edge to edge.
  final double horizontalPadding;

  const FinancialSummaryStrip({
    super.key,
    required this.summary,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsetsDirectional.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          SummaryStatCard(
            label: 'dashboard.income'.tr(),
            value: summary.income,
            icon: Icons.arrow_downward,
            accent: ColorsApp.primaryGreenPressed,
          ),
          SizedBox(width: 16.w),
          SummaryStatCard(
            label: 'dashboard.expenses'.tr(),
            value: summary.expenses,
            icon: Icons.arrow_upward,
            accent: ColorsApp.errorRed,
          ),
          SizedBox(width: 16.w),
          SummaryStatCard(
            label: 'dashboard.remaining'.tr(),
            value: summary.remaining,
            icon: Icons.query_stats,
            accent: ColorsApp.dashboardBlue,
          ),
        ],
      ),
    );
  }
}
