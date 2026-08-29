import 'package:flutter/material.dart';
import 'package:family_expense_management/style/colors.dart';

/// Icon and tint for a financial account.
///
/// ---------------------------------------------------------------------------
/// TODO(backend): this exists only because the `accounts` table is
/// `(id, name, balance, user_id)` — there is no `type`, `icon` or `color`
/// column. The design draws four distinct account kinds (نقد، بنكي، بطاقة
/// ائتمانية، ادخار) with their own glyphs, and a `type` column is what would
/// make that real. Until then the glyph is inferred from the name, which is a
/// best guess: renaming an account can change its icon, and an account whose
/// name matches none of these keywords falls back to a generic wallet.
///
/// The add/edit form deliberately offers **no** type selector for the same
/// reason — see `AccountDraft`.
/// ---------------------------------------------------------------------------
///
/// Keyed by keyword rather than by id, unlike `CategoryVisuals`: accounts are
/// created freely by each family, so there is no stable id-to-meaning map to
/// write down.
class AccountVisuals {
  const AccountVisuals._();

  /// Keyword groups, most specific first. Order matters: the card group must be
  /// tested before the cash group, or an account named "بطاقة نقدية" would
  /// match cash.
  static const List<(List<String>, IconData)> _rules = [
    (['بطاق', 'ائتمان', 'credit', 'card', 'visa', 'master'], Icons.credit_card),
    (['ادخار', 'توفير', 'saving'], Icons.savings_outlined),
    (
      ['بنك', 'مصرف', 'راجحي', 'أهلي', 'اهلي', 'bank'],
      Icons.account_balance_outlined,
    ),
    (
      ['نقد', 'كاش', 'محفظة', 'cash', 'wallet'],
      Icons.account_balance_wallet_outlined,
    ),
  ];

  /// The glyph for an account, inferred from its [name].
  ///
  /// Falls back to a wallet, which is the neutral reading of "money lives here"
  /// rather than a claim about what kind of account it is.
  static IconData iconFor(String? name) {
    final String needle = (name ?? '').toLowerCase();
    if (needle.isEmpty) return Icons.account_balance_wallet_outlined;

    for (final (keywords, icon) in _rules) {
      for (final keyword in keywords) {
        if (needle.contains(keyword)) return icon;
      }
    }
    return Icons.account_balance_wallet_outlined;
  }

  /// Tint for the icon tile behind [iconFor].
  ///
  /// Driven by the balance, not the name: the design tints the overdrawn credit
  /// card's tile red and every other tile green. That reads as a status, so it
  /// follows the number rather than the label.
  static Color tintFor(num? balance) => (balance ?? 0) < 0
      ? ColorsApp.errorRed.withValues(alpha: 0.1)
      : ColorsApp.surfaceContainerLow;

  /// Ink for the glyph itself, matching [tintFor].
  static Color inkFor(num? balance) =>
      (balance ?? 0) < 0 ? ColorsApp.errorRed : ColorsApp.primaryGreenPressed;

  /// Colour of the balance figure on a row.
  ///
  /// Negative balances are red, mirroring the design's "-4,800.00" row. Zero or
  /// positive uses the normal ink — deliberately not green, because green in
  /// this app means "income", and a positive balance is not income.
  static Color amountColorFor(num? balance) =>
      (balance ?? 0) < 0 ? ColorsApp.errorRed : ColorsApp.onSurface;
}
