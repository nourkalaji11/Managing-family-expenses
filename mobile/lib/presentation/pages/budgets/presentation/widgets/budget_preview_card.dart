import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The form's live preview of what is being set.
///
/// It shows the ceiling, the period and the category — the three things the form
/// actually owns. The bar is drawn **empty**: a brand-new budget has consumed
/// nothing, and `current_spending` is derived from transactions the form does
/// not touch, so filling it here would be inventing a figure. The design's
/// two-thirds-full bar is a mockup flourish with no data behind it.
class BudgetPreviewCard extends StatelessWidget {
  /// Null until a valid amount has been typed.
  final num? limitAmount;

  /// Null until a category has been picked.
  final String? categoryName;

  final DateTime startDate;
  final DateTime endDate;

  const BudgetPreviewCard({
    super.key,
    required this.limitAmount,
    required this.categoryName,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComplete = limitAmount != null && categoryName != null;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: ColorsApp.progressTrack,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: ColorsApp.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  'budgets.preview'.tr(),
                  style: TextStyleApp.budgetsPreviewBadge,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${DashboardFormatter.compactAmount(limitAmount)} '
                  '${'dashboard.currency_sar'.tr()}',
                  style: TextStyleApp.budgetsPreviewValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          const BudgetProgressBar(
            value: 0,
            color: ColorsApp.primaryGreenPressed,
            height: 8,
          ),
          SizedBox(height: 12.h),
          Text(
            isComplete
                ? 'budgets.preview_caption'.tr(
                    namedArgs: <String, String>{
                      'category': categoryName!,
                      'start': DashboardFormatter.plainDate(startDate),
                      'end': DashboardFormatter.plainDate(endDate),
                    },
                  )
                : 'budgets.preview_placeholder'.tr(),
            style: TextStyleApp.budgetsPreviewCaption,
          ),
        ],
      ),
    );
  }
}
