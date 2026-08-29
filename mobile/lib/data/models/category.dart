// To parse this JSON data, do
//
//     final category = categoryFromJson(jsonString);

import 'dart:convert';

Category categoryFromJson(String str) => Category.fromJson(json.decode(str));

/// Mirrors the `categories` table.
///
/// Schema (branch `origin/souad-backend`,
/// `database/migrations/2026_06_05_223700_create_categories_table.php`):
///
///     categories (id, name, created_at, updated_at)
///
/// There is deliberately no `color` or `icon` field here: those columns do not
/// exist. The dashboard derives both client-side — see `CategoryVisuals`.
/// TODO(backend): add `color` and `icon` columns so the palette and the row
/// icons become server-driven instead of a local lookup table.
class Category {
  final int? id;
  final String? name;

  /// `transactions_count`, added by `CategoryController::index` with a
  /// `withCount`. Null on payloads that do not carry it.
  ///
  /// Transfer legs are excluded server-side: a transfer's category is filler
  /// the form had to pick because `transactions.category_id` is NOT NULL, so
  /// counting it would inflate an unrelated tile.
  final int? transactionsCount;

  /// `budgets_count`. Not rendered anywhere — it exists so the form can warn
  /// before a delete the server would refuse, since `destroy` answers 409 when
  /// either count is non-zero.
  final int? budgetsCount;

  const Category({
    this.id,
    this.name,
    this.transactionsCount,
    this.budgetsCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    name: json["name"],
    transactionsCount: json["transactions_count"],
    budgetsCount: json["budgets_count"],
  );

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}
