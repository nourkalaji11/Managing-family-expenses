import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Shown when the categories grid has nothing to render.
///
/// In practice only the filtered case reaches this: with no categories at all
/// the grid still renders its "فئة جديدة" tile, which is a better empty state
/// than a message, because it is also the action. Follows the same composition
/// as `AccountsEmptyState` and `BudgetsEmptyState`.
class CategoriesEmptyState extends StatelessWidget {
  /// True when categories exist but none matches the search query.
  final bool isFiltered;

  /// Offered only in the filtered case, to clear the query.
  final VoidCallback? onClearSearch;

  const CategoriesEmptyState({
    super.key,
    required this.isFiltered,
    this.onClearSearch,
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
              isFiltered ? Icons.search_off_outlined : Icons.grid_view_outlined,
              size: 40.r,
              color: ColorsApp.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              isFiltered
                  ? 'categories.empty_search_title'.tr()
                  : 'categories.empty_title'.tr(),
              style: TextStyleApp.transactionsEmptyTitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              isFiltered
                  ? 'categories.empty_search_body'.tr()
                  : 'categories.empty_body'.tr(),
              style: TextStyleApp.dashboardStatLabel,
              textAlign: TextAlign.center,
            ),
            if (isFiltered && onClearSearch != null) ...[
              SizedBox(height: 12.h),
              TextButton(
                key: const Key('categories_clear_search'),
                onPressed: onClearSearch,
                child: Text(
                  'transactions.clear_search'.tr(),
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
