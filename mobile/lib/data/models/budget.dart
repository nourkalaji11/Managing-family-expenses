// To parse this JSON data, do
//
//     final budget = budgetFromJson(jsonString);

import 'dart:convert';

import 'package:family_expense_management/data/models/category.dart';

BudgetModel budgetFromJson(String str) =>
    BudgetModel.fromJson(json.decode(str));

/// How much of a budget has been consumed, as a bucket the UI can style.
///
/// The four buckets are exactly the four states the design draws
/// (`docs/stitch_family_finance_tracker/budgets_list_screen_minimal_redesign`):
/// "بداية جيدة (10%)", "تم استهلاك 45%", "اقتربت من الحد (82%)" and
/// "تجاوزت الميزانية بـ 150 ر.س". The thresholds live on [BudgetModel] so the
/// bucket is decided once, in the model, and never re-derived inside a widget.
///
/// TODO(backend/business-rule): the thresholds are read off the design, not off
/// the backend — nothing on `origin/souad-backend` defines a warning level, and
/// the `budgets` table has no threshold or alert column. If the product owns a
/// different number (the design's own "تنبيه عند 80%" copy is the only hint),
/// it belongs server-side rather than in these constants.
enum BudgetStatus { earlyStage, onTrack, nearLimit, exceeded }

/// Mirrors the `budgets` table.
///
/// Schema (branch `origin/souad-backend`,
/// `database/migrations/2026_06_05_224409_create_budgets_table.php`):
///
///     budgets (id, limit_amount DECIMAL(15,2),
///              current_spending DECIMAL(15,2) DEFAULT 0.00,
///              start_date DATE, end_date DATE,
///              user_id, category_id, created_at, updated_at)
///
/// The migration declares no unique index and no composite key, so nothing in
/// the schema constrains how many budgets a category may have.
///
/// `BudgetController::index` eager-loads `category`, so that relation is parsed
/// when present. There is no `account` relation on this table.
///
/// Named `BudgetModel` rather than `Budget` for the same reason as
/// `TransactionModel`: the suffix keeps call sites unambiguous next to the
/// feature's blocs and widgets.
class BudgetModel {
  final int? id;

  /// The `limit_amount` column — the ceiling the user set ("الحد الأقصى").
  final num? limitAmount;

  /// The `current_spending` column.
  ///
  /// TODO(backend): nothing ever writes this. `BudgetController::store` passes
  /// only `limit_amount` to `updateOrCreate`, and no observer, trigger or job on
  /// `origin/souad-backend` recomputes it when a transaction is created,
  /// updated or deleted — so on the real API it stays at its `0.00` default
  /// forever. Until the backend maintains it, `BudgetsRepo` derives the value
  /// from the transactions that fall inside the budget's own period, which is
  /// what the column is supposed to hold.
  final num? currentSpending;

  /// The `start_date` column. **Date-only** — the SQL type is `DATE`.
  final DateTime? startDate;

  /// The `end_date` column. **Date-only**, same as [startDate].
  final DateTime? endDate;

  final int? userId;
  final int? categoryId;

  /// The `created_at` timestamp. `BudgetController::index` orders by it
  /// (`latest()`), which is why the repository keeps it.
  final DateTime? createdAt;

  final Category? category;

  const BudgetModel({
    this.id,
    this.limitAmount,
    this.currentSpending,
    this.startDate,
    this.endDate,
    this.userId,
    this.categoryId,
    this.createdAt,
    this.category,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id: json["id"],
    limitAmount: _toNum(json["limit_amount"]),
    currentSpending: _toNum(json["current_spending"]),
    startDate: _toDate(json["start_date"]),
    endDate: _toDate(json["end_date"]),
    userId: json["user_id"],
    categoryId: json["category_id"],
    createdAt: _toDate(json["created_at"]),
    category: json["category"] == null
        ? null
        : Category.fromJson(json["category"]),
  );

  /// Returns a copy with the given fields replaced.
  ///
  /// Used by the edit flow, which must preserve `id`, `createdAt` and `userId`
  /// while replacing only what the form owns, and by the repository when it
  /// fills in the derived [currentSpending].
  BudgetModel copyWith({
    int? id,
    num? limitAmount,
    num? currentSpending,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    int? categoryId,
    DateTime? createdAt,
    Category? category,
  }) => BudgetModel(
    id: id ?? this.id,
    limitAmount: limitAmount ?? this.limitAmount,
    currentSpending: currentSpending ?? this.currentSpending,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    userId: userId ?? this.userId,
    categoryId: categoryId ?? this.categoryId,
    createdAt: createdAt ?? this.createdAt,
    category: category ?? this.category,
  );

  // ---------------------------------------------------------------------------
  // Derived values. Every one of these is computed here rather than in a widget,
  // so the list card, the summary strip and the form preview can never disagree
  // about what "spent" or "remaining" means.
  // ---------------------------------------------------------------------------

  /// Both columns are nullable in Dart because the JSON may omit them; the SQL
  /// columns are NOT NULL, so zero is the honest stand-in rather than a guess.
  num get limit => limitAmount ?? 0;

  num get spent => currentSpending ?? 0;

  /// What is left of the ceiling. **Negative when overspent** — the card renders
  /// the overshoot from [overBy] instead, but the raw figure stays truthful.
  num get remaining => limit - spent;

  bool get isOverBudget => spent > limit;

  /// How far past the ceiling, never negative.
  num get overBy => isOverBudget ? spent - limit : 0;

  /// Consumed fraction, clamped to 0..1 — this is what the progress bar draws.
  ///
  /// A zero or missing limit cannot produce a meaningful ratio, so it reads as
  /// full whenever anything at all was spent, and empty otherwise.
  double get progress {
    if (limit <= 0) return spent > 0 ? 1 : 0;
    final double ratio = spent / limit;
    if (ratio.isNaN) return 0;
    return ratio.clamp(0.0, 1.0).toDouble();
  }

  /// Unclamped consumed fraction — what the "45%" / "82%" label reports. Can
  /// exceed 1, which is exactly the case [BudgetStatus.exceeded] covers.
  double get rawProgress {
    if (limit <= 0) return spent > 0 ? 1 : 0;
    final double ratio = spent / limit;
    return ratio.isNaN ? 0 : ratio;
  }

  /// Under this, the design says "بداية جيدة".
  static const double earlyStageThreshold = 0.25;

  /// At or above this (but not over the limit), "اقتربت من الحد".
  static const double nearLimitThreshold = 0.8;

  BudgetStatus get status {
    if (isOverBudget) return BudgetStatus.exceeded;
    final double ratio = rawProgress;
    if (ratio >= nearLimitThreshold) return BudgetStatus.nearLimit;
    if (ratio < earlyStageThreshold) return BudgetStatus.earlyStage;
    return BudgetStatus.onTrack;
  }

  /// The card title. The closest column is the category's name, which is
  /// nullable, so the caller supplies a final default.
  String? get title {
    final String? name = category?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  /// True when [day] falls inside this budget's period.
  ///
  /// A missing bound is treated as open-ended rather than as "no match": the
  /// columns are NOT NULL server-side, so a null here can only come from a
  /// malformed payload, and dropping the row would hide real data.
  bool containsDay(DateTime day) {
    final DateTime d = DateTime(day.year, day.month, day.day);
    final DateTime? from = startDate;
    final DateTime? to = endDate;
    if (from != null && d.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null && d.isAfter(DateTime(to.year, to.month, to.day))) {
      return false;
    }
    return true;
  }

  /// True when this budget's period overlaps the range [from]..[to] at all.
  ///
  /// A plain date-range utility, and nothing more: it exists because the list
  /// screen's month selector has to decide which budgets belong to the month
  /// being viewed. A null bound on either side is treated as open-ended, for the
  /// same reason as in [containsDay].
  ///
  /// It deliberately encodes **no** rule about which budgets may coexist.
  /// TODO(backend/business-rule): whether two budgets may share a category —
  /// overlapping in time or at all — is undecided. The migration adds no unique
  /// index, `BudgetController` runs no such validation, and the two places that
  /// hint at an answer contradict each other: `store()` uses
  /// `updateOrCreate(['category_id' => ...])`, i.e. one budget per category
  /// forever, while `Category::budgets()` is documented as "عدة ميزانيات عبر
  /// الزمن". Until that is settled server-side, this app enforces nothing.
  bool overlapsRange(DateTime? from, DateTime? to) {
    final DateTime? start = startDate;
    final DateTime? end = endDate;
    if (end != null && from != null && end.isBefore(from)) return false;
    if (start != null && to != null && start.isAfter(to)) return false;
    return true;
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
