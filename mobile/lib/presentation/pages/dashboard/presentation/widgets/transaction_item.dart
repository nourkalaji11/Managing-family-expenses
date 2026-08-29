import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// A single row in "آخر المعاملات".
class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItem({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);
    final isExpense = transaction.isExpense;

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
              color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                _IconTile(categoryId: transaction.categoryId),
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
                        style: TextStyleApp.dashboardTransactionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        DashboardFormatter.relativeDateTime(
                          transaction.displayedAt,
                        ),
                        style: TextStyleApp.dashboardTransactionSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  DashboardFormatter.signedAmount(
                    transaction.amount,
                    isExpense: isExpense,
                  ),
                  style: isExpense
                      ? TextStyleApp.dashboardAmountNegative
                      : TextStyleApp.dashboardAmountPositive,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 40px rounded tile with the category glyph.
class _IconTile extends StatelessWidget {
  final int? categoryId;

  const _IconTile({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.r,
      height: 40.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorsApp.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(
        CategoryVisuals.iconFor(categoryId),
        size: 20.r,
        color: ColorsApp.onSurface,
      ),
    );
  }
}
