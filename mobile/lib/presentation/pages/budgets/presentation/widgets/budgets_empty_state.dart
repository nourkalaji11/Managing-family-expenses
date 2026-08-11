import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Shown when the list has nothing to render.
///
/// Two distinct messages, because "you have no budgets yet" and "no budget
/// covers the month you are looking at" call for different next actions. The
/// design does not specify an empty state, so this follows the existing
/// `TransactionsEmptyState` composition (icon, title, body, optional action)
/// rather than inventing a new visual language.
class BudgetsEmptyState extends StatelessWidget {
  /// True when budgets exist but none overlaps the selected month.
  final bool isMonthFiltered;

  /// Offered only in the filtered case, to jump back to the current month.
  final VoidCallback? onGoToCurrentMonth;

  const BudgetsEmptyState({
    super.key,
    required this.isMonthFiltered,
    this.onGoToCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMonthFiltered
                  ? Icons.event_busy_outlined
                  : Icons.query_stats_outlined,
              size: 40.r,
              color: ColorsApp.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              isMonthFiltered
                  ? 'budgets.empty_month_title'.tr()
                  : 'budgets.empty_title'.tr(),
              style: TextStyleApp.transactionsEmptyTitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              isMonthFiltered
                  ? 'budgets.empty_month_body'.tr()
                  : 'budgets.empty_body'.tr(),
              style: TextStyleApp.dashboardStatLabel,
              textAlign: TextAlign.center,
            ),
            if (isMonthFiltered && onGoToCurrentMonth != null) ...[
              SizedBox(height: 12.h),
              TextButton(
                key: const Key('budgets_go_to_current_month'),
                onPressed: onGoToCurrentMonth,
                child: Text(
                  'budgets.go_to_current_month'.tr(),
                  style: TextStyleApp.dashboardSectionAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
