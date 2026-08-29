import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One selectable row in a [PickerSheet].
class PickerOption<T> {
  final T value;
  final String label;

  /// Secondary line, e.g. an account's balance. Optional.
  final String? subtitle;

  final IconData icon;

  const PickerOption({
    required this.value,
    required this.label,
    required this.icon,
    this.subtitle,
  });
}

/// The bottom sheet behind the account and category rows.
///
/// The design marks both rows with a chevron but does not draw what they open.
/// A modal sheet is the lightest thing that matches the rest of the app's
/// visual language and works with any number of options.
class PickerSheet<T> extends StatelessWidget {
  final String title;
  final List<PickerOption<T>> options;
  final T? selected;

  const PickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
  });

  /// Opens the sheet and resolves to the chosen value, or null if dismissed.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<PickerOption<T>> options,
    required T? selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      // A long category list must not push the sheet off screen.
      isScrollControlled: true,
      builder: (_) =>
          PickerSheet<T>(title: title, options: options, selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: ColorsApp.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            // Grabber.
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorsApp.outlineVariant,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyleApp.transactionsSheetTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 20.w,
                  endIndent: 20.w,
                  color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (context, index) {
                  final PickerOption<T> option = options[index];
                  final bool isSelected = option.value == selected;

                  return ListTile(
                    onTap: () => Navigator.of(context).pop(option.value),
                    contentPadding: EdgeInsetsDirectional.symmetric(
                      horizontal: 20.w,
                    ),
                    leading: Container(
                      width: 40.r,
                      height: 40.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ColorsApp.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        option.icon,
                        size: 20.r,
                        color: ColorsApp.onSurface,
                      ),
                    ),
                    title: Text(
                      option.label,
                      style: TextStyleApp.transactionsSheetOption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: option.subtitle == null
                        ? null
                        : Text(
                            option.subtitle!,
                            style: TextStyleApp.transactionsRowSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            size: 20.r,
                            color: ColorsApp.primaryGreenPressed,
                          )
                        : null,
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
