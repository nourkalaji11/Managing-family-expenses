import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The 3x4 numeric pad from the design.
///
/// Digits are Western ("1", "2", "3"), not the Arabic-Indic glyphs the mockup
/// shows. The list rows, the dashboard and the amount readout all use Western
/// numerals, and a keypad that disagreed with the figure it produces would be
/// the one inconsistent surface in the app.
class AmountKeypad extends StatelessWidget {
  /// Receives "0".."9" and ".".
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  /// Row-major, matching the design: 1-2-3 / 4-5-6 / 7-8-9 / .-0-backspace.
  static const List<String> _keys = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    '0',
    _backspaceKey,
  ];

  static const String _backspaceKey = 'backspace';

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Sits inside the form's scroll view, so it must not scroll itself.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _keys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        // 56px tall keys at the design's width. An aspect ratio rather than a
        // fixed extent keeps the pad proportional on small screens.
        mainAxisExtent: 56.h,
      ),
      itemBuilder: (context, index) {
        final String key = _keys[index];
        if (key == _backspaceKey) {
          return _Key(
            keyValue: const Key('keypad_backspace'),
            onTap: onBackspace,
            semanticLabel: 'transactions.backspace'.tr(),
            child: Icon(
              Icons.backspace_outlined,
              size: 20.r,
              color: ColorsApp.errorRed,
            ),
          );
        }

        return _Key(
          keyValue: Key('keypad_$key'),
          onTap: () => onDigit(key),
          semanticLabel: key,
          child: Text(key, style: TextStyleApp.transactionsKeypadDigit),
        );
      },
    );
  }
}

class _Key extends StatelessWidget {
  final Key keyValue;
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  const _Key({
    required this.keyValue,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(16.r);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        key: keyValue,
        color: ColorsApp.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
