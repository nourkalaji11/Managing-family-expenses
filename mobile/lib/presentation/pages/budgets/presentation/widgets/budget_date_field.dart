import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One of the form's two date fields: "تاريخ البدء" and "تاريخ الانتهاء".
///
/// Tapping it opens the platform date picker; the design's native `input
/// type="date"` has no Flutter equivalent, and `showDatePicker` is what the
/// transaction form already uses.
class BudgetDateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final IconData icon;
  final VoidCallback onTap;

  /// Validation message key, rendered under the field when non-null.
  final String? errorKey;

  const BudgetDateField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorKey,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(16.r);
    final bool hasError = errorKey != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyleApp.transactionsFieldLabel),
        SizedBox(height: 6.h),
        Material(
          color: ColorsApp.white,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: hasError
                      ? ColorsApp.errorRed
                      : ColorsApp.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DashboardFormatter.plainDate(value),
                        style: TextStyleApp.budgetsDateValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      icon,
                      size: 18.r,
                      color: ColorsApp.primaryGreenPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(errorKey!.tr(), style: TextStyleApp.transactionsFieldError),
        ],
      ],
    );
  }
}
