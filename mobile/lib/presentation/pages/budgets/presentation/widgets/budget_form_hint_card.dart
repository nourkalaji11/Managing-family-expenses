import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The instructional card at the top of the budget form — "حدد ميزانيتك بحكمة".
///
/// Purely explanatory: it holds no data and no control, which is why it is a
/// leaf widget with no parameters.
class BudgetFormHintCard extends StatelessWidget {
  const BudgetFormHintCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorsApp.primaryGreenPressed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 22.r,
              color: ColorsApp.primaryGreenPressed,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'budgets.hint_title'.tr(),
                  style: TextStyleApp.budgetsHintTitle,
                ),
                SizedBox(height: 4.h),
                Text(
                  'budgets.hint_body'.tr(),
                  style: TextStyleApp.budgetsHintBody,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
