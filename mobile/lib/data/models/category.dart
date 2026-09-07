// To parse this JSON data, do
//
//     final category = categoryFromJson(jsonString);

import 'dart:convert';

Category categoryFromJson(String str) => Category.fromJson(json.decode(str));

/// Mirrors the `categories` table.
///
/// Schema (branch `origin/souad-backend`):
///
///     categories (id, name, type, parent_id, icon, created_at, updated_at)
///
/// It was `(id, name)` alone until the tree landed, which is why the colour is
/// still derived client-side from the id — see `CategoryVisuals`. The icon is
/// no longer: the server names one, and the lookup is only a fallback for rows
/// that predate the column.
class Category {
  final int? id;
  final String? name;

  /// Which tab the category belongs to: `income`, `expense` or `debt`.
  ///
  /// Defaults to expense on a payload that omits it, matching the column's own
  /// default and what every row was before the type existed.
  final String type;

  /// The group this sits under, or null when it *is* a group.
  ///
  /// The tree is only one level deep — a group and its children — which is what
  /// the reference app shows and what the screen draws.
  final int? parentId;

  /// Icon name chosen by the server, e.g. `restaurant`. A name rather than a
  /// code point so the server is not tied to one icon set.
  final String? icon;

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
    this.type = typeExpense,
    this.parentId,
    this.icon,
    this.transactionsCount,
    this.budgetsCount,
  });

  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
  static const String typeDebt = 'debt';

  /// Tab order, matching the reference app: الدخل، المصروف، الديون.
  static const List<String> types = [typeIncome, typeExpense, typeDebt];

  /// True for a row that heads a group rather than sitting inside one.
  bool get isGroup => parentId == null;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    name: json["name"],
    // A row from before the column, or a payload that omits it, is an expense —
    // the column's default, and what those rows already were.
    type: json["type"] as String? ?? typeExpense,
    parentId: json["parent_id"],
    icon: json["icon"] as String?,
    transactionsCount: json["transactions_count"],
    budgetsCount: json["budgets_count"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type,
    "parent_id": parentId,
    "icon": icon,
  };
}
