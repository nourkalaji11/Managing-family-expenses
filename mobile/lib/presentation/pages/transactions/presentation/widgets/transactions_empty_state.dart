import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Shown when the list has nothing to render.
///
/// Two distinct messages, because "you have no transactions yet" and "nothing
/// matched your filters" call for different next actions from the user. The
/// design does not specify an empty state, so this follows the existing
/// `_FailureView` composition (icon, title, body) rather
/// than inventing a new visual language.
class TransactionsEmptyState extends StatelessWidget {
  /// True when rows exist but the search or filters excluded all of them.
  final bool isFiltered;

  /// Offered only in the filtered case, to clear back to "الكل".
  final VoidCallback? onClearFilters;

  const TransactionsEmptyState({
    super.key,
    required this.isFiltered,
    this.onClearFilters,
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
              isFiltered
                  ? Icons.search_off_outlined
                  : Icons.receipt_long_outlined,
              size: 40.r,
              color: ColorsApp.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              isFiltered
                  ? 'transactions.empty_filtered_title'.tr()
                  : 'transactions.empty_title'.tr(),
              style: TextStyleApp.transactionsEmptyTitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              isFiltered
                  ? 'transactions.empty_filtered_body'.tr()
                  : 'transactions.empty_body'.tr(),
              style: TextStyleApp.dashboardStatLabel,
              textAlign: TextAlign.center,
            ),
            if (isFiltered && onClearFilters != null) ...[
              SizedBox(height: 12.h),
              TextButton(
                key: const Key('transactions_clear_filters'),
                onPressed: onClearFilters,
                child: Text(
                  'transactions.clear_filters'.tr(),
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
