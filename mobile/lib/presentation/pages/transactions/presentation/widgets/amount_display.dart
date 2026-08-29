import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/text_style.dart';

/// "المبلغ الإجمالي" + the large running amount + "ر.س".
///
/// Renders the raw keypad buffer, not a formatted number: while the user is
/// typing, "240." and "240.5" must show exactly as entered. Formatting would
/// fight the input.
class AmountDisplay extends StatelessWidget {
  /// The raw buffer from `TransactionFormState.amountInput`.
  final String amountInput;

  /// Validation message key, shown under the figure once the user has tried to
  /// save. Null when valid or not yet submitted.
  final String? errorKey;

  const AmountDisplay({super.key, required this.amountInput, this.errorKey});

  @override
  Widget build(BuildContext context) {
    // An empty buffer reads "0", matching the design's initial state.
    final String shown = amountInput.isEmpty ? '0' : amountInput;

    return Column(
      children: [
        Text(
          'transactions.total_amount'.tr(),
          style: TextStyleApp.transactionsAmountCaption,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                // LTR isolate: a decimal number must not be reordered inside
                // the RTL page.
                '\u2066$shown\u2069',
                style: TextStyleApp.transactionsAmountHero,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'dashboard.currency_sar'.tr(),
              style: TextStyleApp.transactionsAmountCurrency,
            ),
          ],
        ),
        if (errorKey != null) ...[
          SizedBox(height: 6.h),
          Text(
            errorKey!.tr(),
            style: TextStyleApp.transactionsFieldError,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
