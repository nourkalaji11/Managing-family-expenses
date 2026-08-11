import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/transaction.dart';

/// One slice of the "توزيع المصاريف" donut.
///
/// [categoryId] is null for the aggregated "أخرى" slice, which is synthesised
/// client-side and has no row in the `categories` table.
class CategoryBreakdown {
  final int? categoryId;
  final String? categoryName;
  final num total;

  /// Share of the expense total, 0..1.
  final double fraction;

  /// True for the synthetic "other" slice.
  final bool isOther;

  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.fraction,
    this.isOther = false,
  });
}

/// Everything the dashboard home tab renders, in one immutable value.
///
/// This is a **client-side aggregate**, not a server DTO — there is no
/// `/dashboard/summary` endpoint. See [DashboardSummary.from].
class DashboardSummary {
  /// Σ `accounts.balance`.
  final num totalBalance;

  /// Σ `transactions.amount` where `type = 'income'` within the period.
  final num income;

  /// Σ `transactions.amount` where `type = 'expense'` within the period.
  final num expenses;

  /// Expense slices: the top N categories plus an aggregated "other".
  final List<CategoryBreakdown> breakdown;

  /// Account used to fill the "رقم الحساب العائلي" row.
  ///
  /// TODO(backend): this is a **temporary display fallback only** — it is
  /// currently just the first account in the list, which is NOT the same thing
  /// as the family's primary account. The schema has no way to identify one:
  /// there is no `accounts.is_primary` flag, no account number column, and no
  /// `families` table linking members to a shared account. Replace this once the
  /// backend defines how the primary family account is identified; until then
  /// the masked number rendered next to it is mock data, not real.
  final Account? primaryAccount;

  const DashboardSummary({
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.breakdown,
    this.primaryAccount,
  });

  /// "المتبقي" — the design shows 8,500 − 3,250 = 5,250.
  num get remaining => income - expenses;

  /// How many slices the donut draws before grouping the rest into "أخرى".
  /// The design shows three categories.
  static const int topCategoryCount = 3;

  /// Aggregates raw rows into the shape the UI needs.
  ///
  /// Kept here rather than in the repository so that the *same* arithmetic runs
  /// whether the rows came from the mock source or, later, from the API.
  ///
  /// TODO(backend): aggregating on-device means downloading every transaction.
  /// Verified against `TransactionController::index` on branch
  /// `origin/souad-backend` (commit c93db70), whose body is
  /// `Transaction::with(['account','category'])->latest()->get()` — no
  /// `paginate()` and no `where('user_id', ...)`; `routes/api.php` applies no
  /// middleware and `bootstrap/app.php`'s `withMiddleware` closure is empty. So
  /// that endpoint returns every user's rows, unpaginated, and will not scale.
  /// A server-side summary endpoint should replace this once the backend
  /// contract is agreed — deliberately not invented here.
  factory DashboardSummary.from({
    required List<Account> accounts,
    required List<TransactionModel> transactions,
  }) {
    num totalBalance = 0;
    for (final a in accounts) {
      totalBalance += a.balance ?? 0;
    }

    num income = 0;
    num expenses = 0;
    // Keyed by category id; `null` collects rows with no category relation.
    final Map<int?, num> perCategory = {};
    final Map<int?, String?> categoryNames = {};

    for (final t in transactions) {
      final amount = t.amount ?? 0;
      if (t.type == TransactionType.income) {
        income += amount;
      } else {
        expenses += amount;
        final key = t.categoryId ?? t.category?.id;
        perCategory[key] = (perCategory[key] ?? 0) + amount;
        categoryNames[key] ??= t.category?.name;
      }
    }

    return DashboardSummary(
      totalBalance: totalBalance,
      income: income,
      expenses: expenses,
      breakdown: _buildBreakdown(perCategory, categoryNames, expenses),

      // See the `primaryAccount` field doc: placeholder ordering, not a real
      // "primary account" concept.
      primaryAccount: accounts.isEmpty ? null : accounts.first,
    );
  }

  /// Top [topCategoryCount] categories by spend, with the remainder folded into
  /// a single "other" slice so the ring always closes to 100%.
  static List<CategoryBreakdown> _buildBreakdown(
    Map<int?, num> perCategory,
    Map<int?, String?> categoryNames,
    num expenses,
  ) {
    if (perCategory.isEmpty || expenses <= 0) return const [];

    final entries = perCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = entries.take(topCategoryCount).toList();
    final rest = entries.skip(topCategoryCount).toList();

    final slices = <CategoryBreakdown>[
      for (final e in top)
        CategoryBreakdown(
          categoryId: e.key,
          categoryName: categoryNames[e.key],
          total: e.value,
          fraction: e.value / expenses,
        ),
    ];

    if (rest.isNotEmpty) {
      num otherTotal = 0;
      for (final e in rest) {
        otherTotal += e.value;
      }
      slices.add(
        CategoryBreakdown(
          categoryId: null,
          categoryName: null, // the UI substitutes the localised "أخرى"
          total: otherTotal,
          fraction: otherTotal / expenses,
          isOther: true,
        ),
      );
    }

    return slices;
  }
}

/// The two lists the dashboard loads together.
class DashboardData {
  final DashboardSummary summary;

  /// Newest-first, already truncated to what "آخر المعاملات" shows.
  final List<TransactionModel> recentTransactions;

  const DashboardData({
    required this.summary,
    required this.recentTransactions,
  });
}
