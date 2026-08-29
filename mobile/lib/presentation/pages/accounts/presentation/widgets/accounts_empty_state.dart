import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Shown when the accounts list has nothing to render.
///
/// Two distinct messages, because "you have no accounts yet" and "nothing
/// matches what you typed" call for different next actions. The design does not
/// specify an empty state, so this follows the existing `BudgetsEmptyState`
/// composition (icon, title, body, optional action) rather than inventing a new
/// visual language.
class AccountsEmptyState extends StatelessWidget {
  /// True when accounts exist but none matches the search query.
  final bool isFiltered;

  /// Offered only in the filtered case, to clear the query.
  final VoidCallback? onClearSearch;

  const AccountsEmptyState({
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
              isFiltered
                  ? Icons.search_off_outlined
                  : Icons.account_balance_outlined,
              size: 40.r,
              color: ColorsApp.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              isFiltered
                  ? 'accounts.empty_search_title'.tr()
                  : 'accounts.empty_title'.tr(),
              style: TextStyleApp.transactionsEmptyTitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              isFiltered
                  ? 'accounts.empty_search_body'.tr()
                  : 'accounts.empty_body'.tr(),
              style: TextStyleApp.dashboardStatLabel,
              textAlign: TextAlign.center,
            ),
            if (isFiltered && onClearSearch != null) ...[
              SizedBox(height: 12.h),
              TextButton(
                key: const Key('accounts_clear_search'),
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
