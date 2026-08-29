import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// A labelled text field: label above the input, error message below it.
///
/// Lives in the shared widget folder because both the accounts and the
/// categories forms use it. It is deliberately not feature-local: the two forms
/// need an identical field, and a second copy would drift.
///
/// Deliberately not the shared `CustomTextField`: that widget is built for the
/// auth screens (32px pill radius, yellow focus ring, 35px top content padding)
/// and reusing it would mean overriding every visual property it sets — the
/// same reasoning that produced `TransactionSearchField`.
///
/// Stateful only to own its `TextEditingController`. The value itself lives in
/// the form bloc; this widget just reports changes upward.
class LabelledTextField extends StatefulWidget {
  /// Rendered above the input, always visible. Never a placeholder-only label:
  /// once the user types, a placeholder label is gone exactly when it is needed.
  final String label;

  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;

  /// Localisation key of the current error, or null when the field is valid.
  /// Supplied only once the form has been submitted once.
  final String? errorKey;

  /// Trailing glyph inside the field, matching the design's field icons.
  final IconData? icon;

  /// Suffix rendered before [icon] — the currency on the balance field.
  final String? suffixText;

  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  /// Hard cap fed to the field itself, mirroring the backend's `max:` rule so
  /// an over-long value cannot even be typed.
  final int? maxLength;

  /// Masks the input and suppresses autocorrect/suggestions.
  ///
  /// When true the trailing [icon] is replaced by a reveal toggle, so the
  /// caller does not have to supply one — a password field with no way to check
  /// what was typed is how typos become lockouts.
  final bool obscureText;

  const LabelledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.errorKey,
    this.icon,
    this.suffixText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const <TextInputFormatter>[],
    this.maxLength,
    this.obscureText = false,
  });

  @override
  State<LabelledTextField> createState() => _LabelledTextFieldState();
}

class _LabelledTextFieldState extends State<LabelledTextField> {
  late final TextEditingController _controller;

  /// Only meaningful when `obscureText` is set. Starts hidden.
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant LabelledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only fires when the bloc reseeds the field. Both Edit forms send their
    // `...FormStarted` event from `didChangeDependencies`, which runs one frame
    // *after* the first build — so without this the controller keeps the empty
    // string it was constructed with and the field renders blank over an
    // already-populated preview.
    //
    // Guarded on both sides so an ordinary keystroke never moves the caret:
    // the value must have actually changed, and must differ from what is
    // already typed. Same construction as `BudgetLimitField`.
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
    final String? errorKey = widget.errorKey;
    final bool hasError = errorKey != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyleApp.transactionsFieldLabel),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          obscureText: widget.obscureText && !_revealed,
          // A masked field must not feed the keyboard's suggestion strip, which
          // would put the password in the OS's learned-words store.
          enableSuggestions: !widget.obscureText,
          autocorrect: !widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          style: TextStyleApp.transactionsFieldInput,
          textInputAction: TextInputAction.done,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: ColorsApp.inputBackground,
            hintText: widget.hint,
            hintStyle: TextStyleApp.transactionsFieldHint,
            // The built-in counter is suppressed: `maxLength` is here to stop
            // the input, not to invite the user to count characters.
            counterText: '',
            suffixIcon: _buildSuffix(hasError),
            suffixIconConstraints: BoxConstraints(minWidth: 44.w),
            contentPadding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 16.w,
            ),
            enabledBorder: _border(
              hasError ? ColorsApp.errorRed : ColorsApp.outlineVariant,
            ),
            border: _border(ColorsApp.outlineVariant),
            focusedBorder: _border(
              hasError ? ColorsApp.errorRed : ColorsApp.primaryGreenPressed,
            ),
          ),
        ),
        // The message sits below the field it belongs to, never collected at
        // the top of the form.
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(errorKey.tr(), style: TextStyleApp.transactionsFieldError),
        ],
      ],
    );
  }

  Widget? _buildSuffix(bool hasError) {
    // The reveal toggle owns the suffix slot on a masked field: showing both it
    // and a decorative glyph would crowd a 44px target against another.
    if (widget.obscureText) {
      return IconButton(
        onPressed: () => setState(() => _revealed = !_revealed),
        iconSize: 20.r,
        color: hasError ? ColorsApp.errorRed : ColorsApp.outline,
        tooltip: _revealed
            ? 'profile.hide_password'.tr()
            : 'profile.show_password'.tr(),
        icon: Icon(
          _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      );
    }

    final IconData? icon = widget.icon;
    final String? suffixText = widget.suffixText;
    if (icon == null && suffixText == null) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (suffixText != null)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8.w),
            child: Text(
              suffixText,
              style: TextStyleApp.transactionsFieldLabel,
            ),
          ),
        if (icon != null)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 14.w),
            child: Icon(
              icon,
              size: 20.r,
              color: hasError ? ColorsApp.errorRed : ColorsApp.outline,
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14.r),
    borderSide: BorderSide(color: color),
  );
}
