import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/widgets/account_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One account row: tinted icon tile, name, subtitle, and the balance with its
/// currency underneath.
///
/// Tapping it opens Edit. The design draws no other affordance on the row, and
/// the whole surface is a larger target than a trailing icon would be — the
/// same reasoning as `BudgetCard`.
class AccountCard extends StatelessWidget {
  final Account account;

  /// How many transactions this account carries. Rendered as the subtitle,
  /// because the column the design puts there does not exist — see
  /// `AccountsData`.
  final int transactionCount;

  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.transactionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(20.r);
    final num? balance = account.balance;
    final bool isNegative = (balance ?? 0) < 0;

    return Material(
      color: ColorsApp.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: isNegative
                  // The design tints the overdrawn card's own border red.
                  ? ColorsApp.errorRed.withValues(alpha: 0.2)
                  : ColorsApp.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Row(
              children: [
                _IconTile(name: account.name, balance: balance),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // An account with no name cannot happen server-side
                        // (`required`), so this only covers a malformed payload.
                        account.name?.trim().isNotEmpty == true
                            ? account.name!.trim()
                            : 'accounts.untitled'.tr(),
                        style: TextStyleApp.transactionsRowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'accounts.transactions_count'.plural(transactionCount),
                        style: TextStyleApp.transactionsRowSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                _Balance(balance: balance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 48px rounded tile carrying the derived glyph.
class _IconTile extends StatelessWidget {
  final String? name;
  final num? balance;

  const _IconTile({required this.name, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        color: AccountVisuals.tintFor(balance),
        borderRadius: BorderRadius.circular(14.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        AccountVisuals.iconFor(name),
        size: 22.r,
        color: AccountVisuals.inkFor(balance),
      ),
    );
  }
}

/// The figure over its currency, right-aligned in the reading direction.
class _Balance extends StatelessWidget {
  final num? balance;

  const _Balance({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          // The sign is written before the digits and the whole string wrapped
          // in an LTR isolate, so "-4,800.00" is not reordered inside the RTL
          // paragraph — the same construction as `DashboardFormatter`.
          DashboardFormatter.isolatedAmount(balance),
          style: TextStyleApp.dashboardStatValue.copyWith(
            color: AccountVisuals.amountColorFor(balance),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2.h),
        Text(
          'dashboard.currency_sar'.tr(),
          style: TextStyleApp.dashboardCaption,
        ),
      ],
    );
  }
}
