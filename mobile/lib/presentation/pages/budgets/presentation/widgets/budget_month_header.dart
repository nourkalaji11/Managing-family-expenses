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
      // Two flexible groups and no `Spacer`.
      //
      // The previous layout put a `Spacer` between them. A `Spacer` is
      // `Expanded(flex: 1)`, so it competed with the two `Flexible` children
      // for the free space and took roughly a third of it — which was enough to
      // ellipsise both "أغسطس ٢٠٢٦" and the total on a 1080px screen ("August…"
      // and "1,950 …"). A truncated figure is worse than a tight one on a
      // screen whose whole job is reporting numbers.
      //
      // The 5:4 split gives the month cluster slightly more, because it carries
      // two 32px buttons as well as its label.
      child: Row(
        children: [
          Flexible(
            flex: 5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                    // Scales down rather than ellipsising, for the same reason
                    // as the total: "August 2…" hides the year, and the year is
                    // half of what a month stepper is for. A longer month name
                    // ("September 2026") shrinks a step instead of losing its
                    // tail.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DashboardFormatter.monthYear(month),
                        style: TextStyleApp.budgetsMonthLabel,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                _StepButton(
                  key: const Key('budgets_next_month'),
                  icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
                  tooltip: 'budgets.next_month'.tr(),
                  onPressed: onNextMonth,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            flex: 4,
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
                // `FittedBox` shrinks the figure rather than clipping it: a
                // seven-digit total on a narrow screen must stay readable, and
                // "1,234,567 …" tells the user nothing.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    '${DashboardFormatter.compactAmount(totalLimit)} '
                    '${'dashboard.currency_sar'.tr()}',
                    style: TextStyleApp.budgetsSummaryValue,
                    maxLines: 1,
                  ),
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
