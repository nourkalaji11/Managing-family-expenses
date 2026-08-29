import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One row of the form card: icon tile, label, value, trailing chevron.
///
/// Used for the account, category and date rows, which are identical apart from
/// their icons and what tapping them opens.
class FormSelectorTile extends StatelessWidget {
  final IconData leadingIcon;
  final IconData trailingIcon;

  /// Small caption above the value — "الحساب", "الفئة", "التاريخ".
  final String label;

  /// The chosen value, or null when nothing is selected yet.
  final String? value;

  /// Shown in place of [value] when it is null.
  final String placeholder;

  /// Validation message key. Rendered under the row when non-null.
  final String? errorKey;

  final VoidCallback onTap;

  const FormSelectorTile({
    super.key,
    required this.leadingIcon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.trailingIcon = Icons.expand_more,
    this.errorKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ColorsApp.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: 20.r,
                    color: ColorsApp.onSurface,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyleApp.transactionsFieldLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        hasValue ? value! : placeholder,
                        style: hasValue
                            ? TextStyleApp.transactionsFieldValue
                            : TextStyleApp.transactionsFieldValue.copyWith(
                                color: ColorsApp.outline,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(trailingIcon, size: 20.r, color: ColorsApp.outline),
              ],
            ),
            if (errorKey != null) ...[
              SizedBox(height: 6.h),
              Text(errorKey!.tr(), style: TextStyleApp.transactionsFieldError),
            ],
          ],
        ),
      ),
    );
  }
}
