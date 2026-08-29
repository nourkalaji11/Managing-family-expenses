// `TextDirection` is hidden because easy_localization re-exports `intl`, whose
// own `TextDirection` would otherwise shadow the `dart:ui` enum the field's
// `textDirection` argument expects.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/budgets/bloc/budget_form_bloc.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The "الحد الأقصى للميزانية" field.
///
/// A typed field rather than the transaction form's keypad, because that is what
/// the budget design draws (`input type="number"` under a floating label). The
/// keypad suits an amount entered dozens of times a day; a ceiling is set once
/// and then rarely touched.
///
/// Stateful only to own its controller; the value lives in the bloc.
class BudgetLimitField extends StatefulWidget {
  /// The bloc's current buffer. Seeded into the controller once.
  final String initialValue;

  /// Validation message key, shown under the field once the user has tried to
  /// save. Null when valid or not yet submitted.
  final String? errorKey;

  final ValueChanged<String> onChanged;

  const BudgetLimitField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.errorKey,
  });

  @override
  State<BudgetLimitField> createState() => _BudgetLimitFieldState();
}

class _BudgetLimitFieldState extends State<BudgetLimitField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant BudgetLimitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only fires when the bloc reseeds the field — the Edit form's
    // `OnBudgetFormStarted` arrives one frame after the first build. Guarded so
    // an ordinary keystroke never moves the caret.
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorKey != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'budgets.limit_label'.tr()} (${'dashboard.currency_sar'.tr()})',
          style: TextStyleApp.budgetsAmountLabel,
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: ColorsApp.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            // The design underlines the field rather than boxing it, and turns
            // that rule green on focus / red on error.
            border: Border(
              bottom: BorderSide(
                color: hasError
                    ? ColorsApp.errorRed
                    : ColorsApp.outlineVariant,
                width: 2,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: TextField(
            key: const Key('budget_form_limit'),
            controller: _controller,
            onChanged: widget.onChanged,
            style: TextStyleApp.budgetsAmountInput,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            // Western digits in an LTR field, matching every other amount in
            // the app, while the label above it stays in the page direction.
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            inputFormatters: <TextInputFormatter>[
              // The schema's shape, enforced keystroke by keystroke: at most 13
              // digits, an optional point, at most 2 decimals. Rejecting the new
              // value keeps the old one, so a stray character simply does
              // nothing. See `BudgetFormBloc.limitInputPattern`.
              TextInputFormatter.withFunction(
                (oldValue, newValue) =>
                    BudgetFormBloc.limitInputPattern.hasMatch(newValue.text)
                    ? newValue
                    : oldValue,
              ),
            ],
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'budgets.limit_hint'.tr(),
              hintStyle: TextStyleApp.budgetsAmountInput.copyWith(
                color: ColorsApp.outline.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(
            widget.errorKey!.tr(),
            style: TextStyleApp.transactionsFieldError,
          ),
        ],
      ],
    );
  }
}
