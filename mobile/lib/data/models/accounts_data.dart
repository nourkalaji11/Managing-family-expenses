import 'package:family_expense_management/data/models/account.dart';

/// Everything the accounts feature loads in one call.
///
/// [transactionCounts] is derived, not a column. The design's account rows carry
/// a subtitle under the name ("مصرف الراجحي - الجاري"), but `accounts` has only
/// `(id, name, balance, user_id)` — there is no description, no bank, no account
/// type and no masked number. Rather than render invented copy, the subtitle
/// reports how many transactions the account carries, which is true and is the
/// same substitution the categories screen makes.
///
/// TODO(backend): counting client-side means downloading every transaction just
/// to render a subtitle. A `withCount('transactions')` on `AccountController::index`
/// would replace this entirely.
class AccountsData {
  /// Newest first, mirroring `AccountController::index`'s `latest()`.
  final List<Account> accounts;

  /// Number of transactions booked against each account, keyed by account id.
  /// An account with no transactions is absent rather than mapped to zero.
  final Map<int, int> transactionCounts;

  const AccountsData({
    required this.accounts,
    this.transactionCounts = const <int, int>{},
  });

  /// Σ `accounts.balance` — the figure the design's hero card shows as
  /// "إجمالي الأرصدة".
  ///
  /// Can go negative when a credit-card account carries a debt, which the
  /// design itself draws (a red "-4,800.00" row). The widget decides how to
  /// colour it; the figure stays truthful.
  num get totalBalance {
    num total = 0;
    for (final a in accounts) {
      total += a.balance ?? 0;
    }
    return total;
  }

  /// Transactions booked against [accountId], or 0 when there are none.
  int countFor(int? accountId) {
    if (accountId == null) return 0;
    return transactionCounts[accountId] ?? 0;
  }
}

/// The editable half of an account: exactly the fields the add/edit form owns.
///
/// Mirrors what `AccountController::store` and `update` validate:
///
///     'name'    => 'required|string|max:100',
///     'balance' => 'required|numeric',
///
/// `id` and `user_id` are absent on purpose: the form never edits them, the
/// server reads the owner from the bearer token on create, and preserves it on
/// update.
///
/// The design's "نوع الحساب" selector (جاري / ادخار / بطاقة ائتمانية / نقد) is
/// deliberately **not** modelled. There is no `accounts.type` column, so a
/// choice made there could not survive a reload — it would be a control that
/// silently forgets. See `AccountVisuals`, which derives the row icon from the
/// name instead.
class AccountDraft {
  final String name;

  /// `accounts.balance` is `DECIMAL(15,2)` and, unlike a transaction amount, is
  /// **not** constrained to be positive: an overdrawn card is a real balance.
  final num balance;

  const AccountDraft({required this.name, required this.balance});

  /// The exact JSON body the backend's validator accepts.
  Map<String, dynamic> toRequestJson() => {'name': name, 'balance': balance};
}
