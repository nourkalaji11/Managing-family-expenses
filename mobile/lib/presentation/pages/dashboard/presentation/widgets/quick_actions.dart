import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The two-button row under the balance card: a filled "إضافة معاملة" and an
/// outlined "تحويل". In RTL the filled button sits on the right, matching the
/// design, because it is the first child.
class QuickActions extends StatelessWidget {
  final VoidCallback? onAddTransaction;
  final VoidCallback? onTransfer;

  const QuickActions({super.key, this.onAddTransaction, this.onTransfer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            key: const Key('dashboard_add_transaction'),
            label: 'dashboard.add_transaction'.tr(),
            icon: Icons.add_circle_outline,
            filled: true,
            onPressed: onAddTransaction,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _ActionButton(
            key: const Key('dashboard_transfer'),
            label: 'dashboard.transfer'.tr(),
            icon: Icons.swap_horiz,
            filled: false,
            onPressed: onTransfer,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  const _ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);

    return Material(
      color: filled ? ColorsApp.primaryGreenPressed : ColorsApp.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: filled
                ? null
                : Border.all(
                    color: ColorsApp.outlineVariant.withValues(alpha: 0.5),
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20.r,
                  color: filled
                      ? ColorsApp.white
                      : ColorsApp.primaryGreenPressed,
                ),
                SizedBox(width: 8.w),
                // The column is a fixed half-width, and "Add transaction" is
                // wider than the Arabic label the size was picked for. Scaling
                // down keeps the whole label readable; ellipsising it hid the
                // verb the button is named after.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: filled
                          ? TextStyleApp.dashboardActionLabel
                          : TextStyleApp.dashboardActionLabelDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
