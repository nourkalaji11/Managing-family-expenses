import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_status_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One budget in the list: category tile, status line, ceiling, progress bar and
/// the spent/remaining footer.
///
/// Tapping it opens Edit — the design draws no other affordance on the card, and
/// the whole surface is a larger target than a trailing icon would be.
class BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onTap;

  const BudgetCard({super.key, required this.budget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(24.r);
    final BudgetStatus status = budget.status;
    final Color statusColor = BudgetStatusVisuals.colorFor(status);
    final bool isOver = status == BudgetStatus.exceeded;

    return Material(
      color: ColorsApp.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            // The design tints the over-budget card's own border red.
            border: Border.all(
              color: isOver
                  ? ColorsApp.errorRed.withValues(alpha: 0.2)
                  : ColorsApp.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  budget: budget,
                  statusColor: statusColor,
                  isOver: isOver,
                ),
                SizedBox(height: 16.h),
                BudgetProgressBar(
                  value: budget.progress,
                  color: statusColor,
                ),
                SizedBox(height: 12.h),
                _Footer(budget: budget, isOver: isOver),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon tile + title + status on one side, the ceiling on the other.
class _Header extends StatelessWidget {
  final BudgetModel budget;
  final Color statusColor;
  final bool isOver;

  const _Header({
    required this.budget,
    required this.statusColor,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // The over-budget tile drops its border for a red wash, exactly as
            // the design draws it.
            color: isOver
                ? ColorsApp.errorRed.withValues(alpha: 0.1)
                : ColorsApp.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.r),
            border: isOver
                ? null
                : Border.all(
                    color: ColorsApp.outlineVariant.withValues(alpha: 0.5),
                  ),
          ),
          child: Icon(
            CategoryVisuals.iconFor(budget.categoryId ?? budget.category?.id),
            size: 20.r,
            color: isOver ? ColorsApp.errorRed : ColorsApp.onSurface,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                budget.title ?? 'budgets.untitled'.tr(),
                style: TextStyleApp.budgetsCardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                BudgetStatusVisuals.labelFor(budget),
                style: TextStyleApp.budgetsCardStatus.copyWith(
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'budgets.limit'.tr(),
              style: TextStyleApp.budgetsCardCaption,
              maxLines: 1,
            ),
            SizedBox(height: 2.h),
            Text(
              '${DashboardFormatter.compactAmount(budget.limit)} '
              '${'dashboard.currency_sar'.tr()}',
              style: TextStyleApp.budgetsCardLimit,
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }
}

/// "المتبقي: 1,100 ر.س" and "صرفت: 900 ر.س", or the overshoot when the ceiling
/// has been passed.
class _Footer extends StatelessWidget {
  final BudgetModel budget;
  final bool isOver;

  const _Footer({required this.budget, required this.isOver});

  @override
  Widget build(BuildContext context) {
    final String currency = 'dashboard.currency_sar'.tr();

    return Row(
      children: [
        Expanded(
          child: isOver
              ? Text(
                  '${'budgets.over_by'.tr()}: '
                  '${DashboardFormatter.compactAmount(budget.overBy)} '
                  '$currency',
                  style: TextStyleApp.budgetsCardFooterOver,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : _LabelledAmount(
                  label: 'budgets.footer_remaining'.tr(),
                  value:
                      '${DashboardFormatter.compactAmount(budget.remaining)} '
                      '$currency',
                ),
        ),
        SizedBox(width: 12.w),
        _LabelledAmount(
          label: 'budgets.footer_spent'.tr(),
          value:
              '${DashboardFormatter.compactAmount(budget.spent)} $currency',
        ),
      ],
    );
  }
}

/// "صرفت: " in muted ink followed by the figure in dark ink, as one line that
/// can ellipsise as a whole.
class _LabelledAmount extends StatelessWidget {
  final String label;
  final String value;

  const _LabelledAmount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyleApp.budgetsCardFooterLabel,
        children: <InlineSpan>[
          TextSpan(text: '$label: '),
          TextSpan(text: value, style: TextStyleApp.budgetsCardFooterValue),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
