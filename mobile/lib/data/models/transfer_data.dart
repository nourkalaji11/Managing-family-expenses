import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';

/// Everything the transfer form needs in one call.
///
/// A transfer needs at least two accounts to exist at all, and one category —
/// `transactions.category_id` is NOT NULL, so even an internal move has to be
/// filed under something.
class TransferFormData {
  final List<Account> accounts;
  final List<Category> categories;

  const TransferFormData({required this.accounts, required this.categories});

  /// A transfer needs somewhere to come from and somewhere to go.
  bool get hasEnoughAccounts => accounts.length >= 2;
}

/// One completed transfer, as `GET /transfers` returns it.
///
/// The endpoint groups the two underlying transaction rows back into a single
/// object, so this is not a `TransactionModel`: it has two accounts, not one.
class TransferModel {
  /// The `transfer_group_id` shared by both legs. This — not a transaction id —
  /// is what `DELETE /transfers/{group}` takes.
  final String? groupId;

  final num? amount;
  final String? description;
  final DateTime? date;
  final Account? fromAccount;
  final Account? toAccount;
  final DateTime? createdAt;

  const TransferModel({
    this.groupId,
    this.amount,
    this.description,
    this.date,
    this.fromAccount,
    this.toAccount,
    this.createdAt,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) => TransferModel(
    groupId: json["transfer_group_id"],
    amount: _toNum(json["amount"]),
    description: json["description"],
    date: _toDate(json["date"]),
    fromAccount: json["from_account"] == null
        ? null
        : Account.fromJson(json["from_account"]),
    toAccount: json["to_account"] == null
        ? null
        : Account.fromJson(json["to_account"]),
    createdAt: _toDate(json["created_at"]),
  );
}

/// The editable half of a transfer: exactly the fields the form owns.
///
/// Mirrors what `TransferController::store` validates:
///
///     'from_account_id' => 'required|exists:accounts,id|different:to_account_id',
///     'to_account_id'   => 'required|exists:accounts,id',
///     'amount'          => 'required|numeric|min:0.01',
///     'category_id'     => 'required|exists:categories,id',
///     'description'     => 'nullable|string|max:255',
///     'date'            => 'required|date',
///
/// `user_id` is absent: the server reads the owner from the bearer token.
class TransferDraft {
  final int fromAccountId;
  final int toAccountId;
  final num amount;
  final int categoryId;
  final String? description;
  final DateTime date;

  const TransferDraft({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
  });

  /// The exact JSON body the backend's validator accepts.
  Map<String, dynamic> toRequestJson() => {
    'from_account_id': fromAccountId,
    'to_account_id': toAccountId,
    'amount': amount,
    'category_id': categoryId,
    'description': description,
    // The column is SQL `DATE`, so only the calendar day goes on the wire.
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
  };
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
