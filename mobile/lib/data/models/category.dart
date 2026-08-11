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

  const Category({this.id, this.name});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json["id"], name: json["name"]);

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}
