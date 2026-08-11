// To parse this JSON data, do
//
//     final account = accountFromJson(jsonString);

import 'dart:convert';

Account accountFromJson(String str) => Account.fromJson(json.decode(str));

/// Mirrors the `accounts` table.
///
/// Schema (branch `origin/souad-backend`,
/// `database/migrations/2026_06_05_224008_create_accounts_table.php`):
///
///     accounts (id, name, balance DECIMAL(15,2), user_id, created_at, updated_at)
///
/// `balance` is a SQL `DECIMAL`, which Laravel serialises as a JSON string
/// ("1250.00"), so [_toNum] accepts both a string and a number.
///
/// TODO(backend): the dashboard design shows a masked family account number
/// ("**** 4421"). No such column exists — `accounts` has only `id`, `name` and
/// `balance`. Rendering it for real needs a schema change (e.g. an
/// `accounts.number` column), not just a new endpoint.
class Account {
  final int? id;
  final String? name;
  final num? balance;
  final int? userId;

  const Account({this.id, this.name, this.balance, this.userId});

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json["id"],
    name: json["name"],
    balance: _toNum(json["balance"]),
    userId: json["user_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "balance": balance,
    "user_id": userId,
  };
}

/// Laravel returns `DECIMAL` columns as strings; the mock returns real numbers.
num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
