import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// "بحث عن معاملة..." — 48px, rounded, leading magnifier.
///
/// Deliberately not the shared `CustomTextField`: that widget is built for the
/// auth forms (32px pill radius, yellow focus ring, 35px top content padding)
/// and none of it matches this design. Reusing it would mean overriding every
/// visual property it sets.
///
/// Stateful only to own its `TextEditingController`. The query itself lives in
/// the owning bloc; this widget just reports changes upward.
///
/// Also used by the accounts and categories screens, which draw the same field.
/// It keeps its name and its location for now: renaming it and moving it into
/// `presentation/widgets/` is a cleanup of its own, and the transactions feature
/// is finished — the same reasoning already recorded on `MainTabAppBar`.
class TransactionSearchField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  /// Translation key of the placeholder. Defaults to the transactions wording,
  /// so the original call site is unchanged; the other two screens pass their
  /// own, because "بحث عن معاملة..." over a list of accounts is simply wrong.
  final String hintKey;

  const TransactionSearchField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hintKey = 'transactions.search_hint',
  });

  @override
  State<TransactionSearchField> createState() => _TransactionSearchFieldState();
}

class _TransactionSearchFieldState extends State<TransactionSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged(value);
          // Local rebuild only, so the clear button appears/disappears as the
          // field goes from empty to non-empty. The query itself is owned by
          // the bloc.
          setState(() {});
        },
        style: TextStyleApp.transactionsSearchInput,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.search,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: ColorsApp.white,
          hintText: widget.hintKey.tr(),
          hintStyle: TextStyleApp.transactionsSearchHint,
          // `prefixIcon` rather than a positioned child, so the glyph flips to
          // the correct side automatically in LTR.
          prefixIcon: Icon(
            Icons.search,
            size: 20.r,
            color: ColorsApp.outline,
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 44.w),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18.r,
                    color: ColorsApp.outline,
                  ),
                  tooltip: 'transactions.clear_search'.tr(),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                ),
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          enabledBorder: _border(ColorsApp.outlineVariant),
          border: _border(ColorsApp.outlineVariant),
          focusedBorder: _border(ColorsApp.primaryGreenPressed),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.r),
    borderSide: BorderSide(color: color),
  );
}
