import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The two-up "تم صرفه" / "المتبقي" tiles under the month header.
///
/// Both figures are sums over the budgets currently on screen, so they describe
/// the selected month rather than every budget ever created.
class BudgetSummaryGrid extends StatelessWidget {
  final num totalSpent;
  final num totalRemaining;

  const BudgetSummaryGrid({
    super.key,
    required this.totalSpent,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final String currency = 'dashboard.currency_sar'.tr();

    // `IntrinsicHeight` is what makes `CrossAxisAlignment.stretch` legal here.
    // Without it the Row sits directly inside the screen's `ListView`, which
    // hands its children an unbounded height; `stretch` then forwards
    // `h=Infinity` as a *tight* constraint and layout asserts with
    // "BoxConstraints forces an infinite height", leaving the whole tab blank.
    //
    // The stretch itself is kept rather than dropped: the two tiles must match
    // heights, and the second one is a filled surface whose tint would
    // obviously stop short of the first if it sized to its own text.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              label: 'budgets.spent'.tr(),
              value:
                  '${DashboardFormatter.compactAmount(totalSpent)} $currency',
              // The design tints only the spent figure.
              valueColor: ColorsApp.primaryGreenPressed,
              filled: false,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _Tile(
              label: 'budgets.remaining'.tr(),
              value:
                  '${DashboardFormatter.compactAmount(totalRemaining)} $currency',
              // Overspending across the month turns the remaining figure red;
              // `totalRemaining` is deliberately allowed to go negative rather
              // than being floored at zero.
              valueColor: totalRemaining < 0
                  ? ColorsApp.errorRed
                  : ColorsApp.onSurface,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  /// The design draws the second tile as a tinted, borderless surface.
  final bool filled;

  const _Tile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: filled ? ColorsApp.surfaceContainerLow : ColorsApp.white,
        borderRadius: BorderRadius.circular(24.r),
        border: filled
            ? null
            : Border.all(
                color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyleApp.budgetsSummaryLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyleApp.budgetsSummaryValue.copyWith(
                color: valueColor,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
