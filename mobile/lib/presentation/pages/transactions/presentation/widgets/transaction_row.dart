import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One `m3-card` row in the transactions list.
///
/// Deliberately not `TransactionItem` from the dashboard, which the design
/// draws differently: this row has a type-tinted icon tile, a
/// "account • time" subtitle rather than a relative date, a 16px radius rather
/// than 24px, and an amount that carries the currency. The two share
/// `CategoryVisuals` and `DashboardFormatter`, which is where the real logic
/// lives; only the layout differs.
class TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionRow({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(16.r);
    final bool isExpense = transaction.isExpense;

    return Material(
      color: ColorsApp.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: ColorsApp.progressTrack),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                _IconTile(
                  categoryId: transaction.categoryId,
                  isExpense: isExpense,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        // `title` prefers `description` and falls back to the
                        // category name; both are nullable in the schema, so a
                        // localised default is the last resort.
                        transaction.title ?? 'dashboard.untitled'.tr(),
                        style: TextStyleApp.transactionsRowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _subtitle(),
                        style: TextStyleApp.transactionsRowSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Flexible so a very large amount ellipsises rather than
                // overflowing on a narrow screen.
                Flexible(
                  child: Text(
                    '${DashboardFormatter.signedAmount(transaction.amount, isExpense: isExpense)} '
                    '${'dashboard.currency_sar'.tr()}',
                    style: isExpense
                        ? TextStyleApp.dashboardAmountNegative
                        : TextStyleApp.dashboardAmountPositive,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "حساب البيت • 14:30". Either half is dropped when its data is missing, so
  /// a row never renders a stray bullet.
  String _subtitle() {
    final String? accountName = transaction.account?.name?.trim();
    final String time = DashboardFormatter.timeOfDay(transaction.createdAt);

    final List<String> parts = <String>[];
    if (accountName != null && accountName.isNotEmpty) parts.add(accountName);
    if (time.isNotEmpty) parts.add(time);
    return parts.join(' • ');
  }
}

/// 44px rounded tile, tinted by transaction type.
///
/// The design shows three tints (red, green, neutral) with no rule in the data
/// distinguishing the red expenses from the neutral ones, so this uses the one
/// rule the schema can actually support: income is green, expense is red.
class _IconTile extends StatelessWidget {
  final int? categoryId;
  final bool isExpense;

  const _IconTile({required this.categoryId, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    final Color tint = isExpense
        ? ColorsApp.errorRed
        : ColorsApp.primaryGreenPressed;

    return Container(
      width: 44.r,
      height: 44.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: tint.withValues(alpha: 0.08)),
      ),
      child: Icon(
        CategoryVisuals.iconFor(categoryId),
        size: 22.r,
        color: tint,
      ),
    );
  }
}
