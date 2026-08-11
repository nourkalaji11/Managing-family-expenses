import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/transactions/bloc/transactions_bloc.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The horizontally scrolling chip row.
///
/// Visually this is the design's single row of four pills. Semantically it is
/// two independent controls, which is the one place the implementation departs
/// from the prototype: the mockup's script made all four chips a single radio
/// group, so choosing "هذا الشهر" would clear "المصاريف". Type and period are
/// unrelated axes, so they compose here instead.
class TransactionFilterChips extends StatelessWidget {
  final TransactionTypeFilter typeFilter;
  final TransactionPeriodFilter periodFilter;
  final ValueChanged<TransactionTypeFilter> onTypeChanged;
  final ValueChanged<TransactionPeriodFilter> onPeriodChanged;

  /// Horizontal page margin, applied inside the scroll view so the chips can
  /// scroll edge to edge.
  final double horizontalPadding;

  const TransactionFilterChips({
    super.key,
    required this.typeFilter,
    required this.periodFilter,
    required this.onTypeChanged,
    required this.onPeriodChanged,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsetsDirectional.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          _Chip(
            key: const Key('transactions_filter_all'),
            label: 'transactions.filter_all'.tr(),
            selected: typeFilter == TransactionTypeFilter.all,
            onTap: () => onTypeChanged(TransactionTypeFilter.all),
          ),
          SizedBox(width: 12.w),
          _Chip(
            key: const Key('transactions_filter_income'),
            label: 'dashboard.income'.tr(),
            icon: Icons.trending_up,
            selected: typeFilter == TransactionTypeFilter.income,
            onTap: () => onTypeChanged(TransactionTypeFilter.income),
          ),
          SizedBox(width: 12.w),
          _Chip(
            key: const Key('transactions_filter_expense'),
            label: 'dashboard.expenses'.tr(),
            icon: Icons.trending_down,
            selected: typeFilter == TransactionTypeFilter.expense,
            onTap: () => onTypeChanged(TransactionTypeFilter.expense),
          ),
          SizedBox(width: 12.w),
          _Chip(
            key: const Key('transactions_filter_month'),
            label: 'transactions.filter_this_month'.tr(),
            icon: Icons.calendar_today_outlined,
            selected: periodFilter == TransactionPeriodFilter.thisMonth,
            // A toggle, not a radio: tapping the active chip clears it.
            onTap: () => onPeriodChanged(
              periodFilter == TransactionPeriodFilter.thisMonth
                  ? TransactionPeriodFilter.all
                  : TransactionPeriodFilter.thisMonth,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(999.r);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? ColorsApp.primaryGreenPressed : ColorsApp.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: selected
                  ? null
                  : Border.all(color: ColorsApp.outlineVariant),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 9.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16.r,
                      color: selected
                          ? ColorsApp.white
                          : ColorsApp.onSurfaceVariant,
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Text(
                    label,
                    style: selected
                        ? TextStyleApp.transactionsChipSelected
                        : TextStyleApp.transactionsChipUnselected,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
