import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The segmented "مصروف / دخل" control.
///
/// Expense is first so that, in RTL, it sits on the right — matching the
/// design, where the sliding indicator starts under "مصروف". In LTR the same
/// child order puts it on the left, which is the correct mirroring.
///
/// The selected half is a white card sliding over a tinted track. The design
/// animates it; `AnimatedAlign` reproduces that without a Stack of measured
/// offsets, so it stays correct at any width and in either direction.
class TransactionTypeToggle extends StatelessWidget {
  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  const TransactionTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isExpense = value == TransactionType.expense;

    return Container(
      height: 44.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: ColorsApp.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            // `-1` is the start side, which Flutter resolves per text
            // direction, so this needs no RTL special-casing.
            alignment: isExpense
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorsApp.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Half(
                  key: const Key('transaction_type_expense'),
                  label: 'transactions.type_expense'.tr(),
                  selected: isExpense,
                  onTap: () => onChanged(TransactionType.expense),
                ),
              ),
              Expanded(
                child: _Half(
                  key: const Key('transaction_type_income'),
                  label: 'transactions.type_income'.tr(),
                  selected: !isExpense,
                  onTap: () => onChanged(TransactionType.income),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Half extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Half({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        // Transparent rather than null, so the whole half is tappable and not
        // just the glyphs.
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            label,
            style: selected
                ? TextStyleApp.transactionsToggleActive
                : TextStyleApp.transactionsToggleInactive,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
