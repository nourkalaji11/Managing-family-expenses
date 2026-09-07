import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// "المبلغ الإجمالي" + the amount, typed on the device's own keyboard.
///
/// ---------------------------------------------------------------------------
/// This used to be a read-only figure driven by a custom on-screen keypad drawn
/// below the form. It is a plain text field now, so tapping the amount raises
/// the numeric keyboard the user already knows — with selection, paste and
/// backspace — instead of a fixed grid of buttons that took up a third of the
/// screen and had to be scrolled to.
///
/// The figure still renders the raw text rather than a formatted number: while
/// someone is typing, "240." and "240.5" must show exactly as entered, and
/// grouping separators inserted mid-edit fight the caret.
/// ---------------------------------------------------------------------------
class AmountDisplay extends StatefulWidget {
  /// The raw buffer from `TransactionFormState.amountInput`.
  final String amountInput;

  /// Validation message key, shown under the figure once the user has tried to
  /// save. Null when valid or not yet submitted.
  final String? errorKey;

  final ValueChanged<String> onChanged;

  /// Whether to raise the keyboard as the screen opens. True when adding, where
  /// the amount is the first thing to enter; false when editing, so arriving at
  /// an existing transaction does not immediately cover it with a keyboard.
  final bool autofocus;

  const AmountDisplay({
    super.key,
    required this.amountInput,
    required this.onChanged,
    this.errorKey,
    this.autofocus = false,
  });

  @override
  State<AmountDisplay> createState() => _AmountDisplayState();
}

class _AmountDisplayState extends State<AmountDisplay> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.amountInput);

    // `autofocus: true` alone proved unreliable here: the form rebuilds as soon
    // as the bloc finishes loading its account and category options, and on
    // some devices the keyboard never came up. Requesting focus after the first
    // frame asks once, when there is definitely a render tree to attach to.
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AmountDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The bloc is the source of truth, and it may hand back something shorter
    // than what was typed — a third decimal, a second dot. Only write when the
    // two actually disagree, otherwise every keystroke would reset the caret to
    // the end of the line.
    if (widget.amountInput != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.amountInput,
        selection: TextSelection.collapsed(offset: widget.amountInput.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'transactions.total_amount'.tr(),
          style: TextStyleApp.transactionsAmountCaption,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        // The whole figure — including the currency beside it and the padding
        // around both — raises the keyboard. A bare centred TextField showing
        // "0" is a tap target a couple of characters wide, which is why tapping
        // the amount appeared to do nothing.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focus.requestFocus,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: TextField(
                    key: const Key('transaction_amount_field'),
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: widget.onChanged,
                    // LTR whatever the page direction: a decimal number typed into
                    // an RTL field has its digits and point reordered on screen.
                    // `ui.` qualified: easy_localization re-exports `intl`, whose
                    // own `TextDirection` would shadow Flutter's here.
                    textDirection: ui.TextDirection.ltr,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      // Arabic-Indic digits are accepted here and folded to ASCII
                      // by the bloc; a keyboard set to Arabic emits them.
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,]')),
                    ],
                    style: TextStyleApp.transactionsAmountHero,
                    cursorColor: ColorsApp.primaryGreenPressed,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      // The zero the figure used to show when nothing was typed —
                      // now a hint, so it disappears the moment a digit lands.
                      hintText: '0',
                      hintStyle: TextStyleApp.transactionsAmountHero.copyWith(
                        color: ColorsApp.grey200,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'dashboard.currency'.tr(),
                  style: TextStyleApp.transactionsAmountCurrency,
                ),
              ],
            ),
          ),
        ),
        if (widget.errorKey != null) ...[
          SizedBox(height: 6.h),
          Text(
            widget.errorKey!.tr(),
            style: TextStyleApp.transactionsFieldError,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
