// To parse this JSON data, do
//
//     final transaction = transactionFromJson(jsonString);

import 'dart:convert';

import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';

TransactionModel transactionFromJson(String str) =>
    TransactionModel.fromJson(json.decode(str));

/// Mirrors the `transactions` table.
///
/// Schema (branch `origin/souad-backend`,
/// `database/migrations/2026_06_05_224702_create_transactions_table.php`):
///
///     transactions (id, amount DECIMAL(15,2), type ENUM('income','expense'),
///                   description NULLABLE, date DATE,
///                   user_id, account_id, category_id, created_at, updated_at)
///
/// `TransactionController::index` eager-loads `account` and `category`, so both
/// relations are parsed when present.
///
/// Named `TransactionModel` rather than `Transaction` because several symbols
/// named `Transaction` exist in the wider Flutter ecosystem; the suffix keeps
/// call sites unambiguous.
class TransactionModel {
  final int? id;
  final num? amount;
  final TransactionType type;
  final String? description;

  /// The `date` column. **Date-only** — the SQL type is `DATE`, so this never
  /// carries a time-of-day.
  final DateTime? date;

  /// The `created_at` timestamp. This is the only field that carries a
  /// time-of-day, which is why the UI falls back to it when rendering the
  /// "اليوم، 10:30 ص" subtitle from the design.
  final DateTime? createdAt;

  final int? userId;
  final int? accountId;
  final int? categoryId;

  final Account? account;
  final Category? category;

  const TransactionModel({
    this.id,
    this.amount,
    this.type = TransactionType.expense,
    this.description,
    this.date,
    this.createdAt,
    this.userId,
    this.accountId,
    this.categoryId,
    this.account,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json["id"],
        amount: _toNum(json["amount"]),

        // `tryFrom` comes from `TransactionTypeHelper` in
        // data/constant/enums.dart, which follows the same pattern as the
        // pre-existing `UserRoleHelper`. It maps the API values "income" and
        // "expense" and falls back to `expense` for anything unrecognised, so a
        // malformed payload can never throw here.
        type: TransactionType.values.tryFrom(json["type"]),

        description: json["description"],
        date: _toDate(json["date"]),
        createdAt: _toDate(json["created_at"]),
        userId: json["user_id"],
        accountId: json["account_id"],
        categoryId: json["category_id"],
        account: json["account"] == null
            ? null
            : Account.fromJson(json["account"]),
        category: json["category"] == null
            ? null
            : Category.fromJson(json["category"]),
      );

  /// Sentinel for [copyWith], so that `description: null` can mean "clear this"
  /// rather than "leave it alone". Every other field is non-clearable through
  /// [copyWith], which is why they use plain `??`.
  static const Object _unset = Object();

  /// Returns a copy with the given fields replaced.
  ///
  /// Used by the edit flow, which must preserve `id`, `createdAt` and `userId`
  /// while replacing only what the form actually owns. Passing
  /// `description: null` explicitly clears the note; omitting it keeps the
  /// current value.
  TransactionModel copyWith({
    int? id,
    num? amount,
    TransactionType? type,
    Object? description = _unset,
    DateTime? date,
    DateTime? createdAt,
    int? userId,
    int? accountId,
    int? categoryId,
    Account? account,
    Category? category,
  }) => TransactionModel(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    description: identical(description, _unset)
        ? this.description
        : description as String?,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
    userId: userId ?? this.userId,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    account: account ?? this.account,
    category: category ?? this.category,
  );

  /// True when this row reduces the balance.
  bool get isExpense => type == TransactionType.expense;

  /// The timestamp to display. Prefers [createdAt] because [date] is date-only.
  DateTime? get displayedAt => createdAt ?? date;

  /// The row title. The design shows a merchant name ("ستاربكس"); the closest
  /// column is `description`, which is nullable — so the category name is the
  /// fallback, and the caller supplies a final default.
  String? get title {
    final d = description?.trim();
    if (d != null && d.isNotEmpty) return d;
    final c = category?.name?.trim();
    if (c != null && c.isNotEmpty) return c;
    return null;
  }
}

/// Laravel returns `DECIMAL` columns as strings; the mock returns real numbers.
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
