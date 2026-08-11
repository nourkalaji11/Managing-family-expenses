// `TextDirection` is hidden because easy_localization re-exports `intl`, whose
// own `TextDirection` would otherwise shadow the `dart:ui` enum that
// `Directionality.of` returns.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The month stepper and the total ceiling for that month.
///
/// The two chevrons move the whole list a calendar month at a time; the budgets
/// shown are the ones whose `start_date`/`end_date` period overlaps it, so this
/// is a real filter over real columns rather than a decorative control.
class BudgetMonthHeader extends StatelessWidget {
  final DateTime month;
  final num totalLimit;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const BudgetMonthHeader({
    super.key,
    required this.month,
    required this.totalLimit,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Material's chevrons do not mirror themselves, so the arrow that means
    // "back" is chosen from the ambient direction: in Arabic the timeline runs
    // right to left, and "previous" points to the right.
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorsApp.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          _StepButton(
            key: const Key('budgets_previous_month'),
            icon: isRtl ? Icons.chevron_right : Icons.chevron_left,
            tooltip: 'budgets.previous_month'.tr(),
            onPressed: onPreviousMonth,
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                DashboardFormatter.monthYear(month),
                style: TextStyleApp.budgetsMonthLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _StepButton(
            key: const Key('budgets_next_month'),
            icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
            tooltip: 'budgets.next_month'.tr(),
            onPressed: onNextMonth,
          ),
          const Spacer(),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'budgets.total_limit'.tr(),
                  style: TextStyleApp.budgetsSummaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${DashboardFormatter.compactAmount(totalLimit)} '
                  '${'dashboard.currency_sar'.tr()}',
                  style: TextStyleApp.budgetsSummaryValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _StepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 22.r,
      color: ColorsApp.onSurface,
      tooltip: tooltip,
      // The design's buttons are compact; the default 48px box would push the
      // month label into the total.
      constraints: BoxConstraints(minWidth: 32.r, minHeight: 32.r),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
