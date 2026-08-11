import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/transaction_item.dart';
import 'package:family_expense_management/style/text_style.dart';

/// "آخر المعاملات" — the section header plus the transaction rows.
class RecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback? onViewAll;
  final void Function(TransactionModel)? onTransactionTap;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    this.onViewAll,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'dashboard.recent_transactions'.tr(),
                style: TextStyleApp.dashboardSectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: const Key('dashboard_view_all'),
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'dashboard.view_all'.tr(),
                style: TextStyleApp.dashboardSectionAction,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Center(
              child: Text(
                'dashboard.no_transactions'.tr(),
                style: TextStyleApp.dashboardStatLabel,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (int i = 0; i < transactions.length; i++) ...[
            if (i > 0) SizedBox(height: 8.h),
            TransactionItem(
              transaction: transactions[i],
              onTap: onTransactionTap == null
                  ? null
                  : () => onTransactionTap!(transactions[i]),
            ),
          ],
      ],
    );
  }
}
