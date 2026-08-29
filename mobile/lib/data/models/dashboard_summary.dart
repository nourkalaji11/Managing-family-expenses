import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/user.dart';

/// One slice of the "توزيع المصاريف" donut.
///
/// [categoryId] is null for the aggregated "أخرى" slice, which the server
/// synthesises from everything below the top three and which has no row in the
/// `categories` table.
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

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdown(
        categoryId: json['category_id'],
        categoryName: json['category'],
        total: _toNum(json['total']) ?? 0,
        fraction: (_toNum(json['fraction']) ?? 0).toDouble(),
        // A null `category_id` is the same signal, but the server states it
        // outright rather than making the client infer it.
        isOther: json['is_other'] == true || json['category_id'] == null,
      );
}

/// Everything the dashboard home tab renders.
///
/// ---------------------------------------------------------------------------
/// This used to be a **client-side aggregate**: the app downloaded every
/// account and every transaction the family had ever recorded, then summed
/// them on the device to produce three numbers and a donut.
///
/// `GET /dashboard` now returns the whole thing computed in SQL. Two things
/// improve, not one: it is a single request instead of two, and the figures
/// cover every row rather than whatever the client happened to hold — which
/// stopped being the same thing once `/transactions` became scoped by role and
/// could be paginated.
///
/// [from] is kept for the mock path, which has no server to compute anything.
/// ---------------------------------------------------------------------------
class DashboardSummary {
  /// Σ `accounts.balance` across the family. Accounts are shared, so this is
  /// the same figure for a parent and a member.
  final num totalBalance;

  /// Σ `transactions.amount` where `type = 'income'`, transfers excluded.
  final num income;

  /// Σ `transactions.amount` where `type = 'expense'`, transfers excluded.
  final num expenses;

  /// Expense slices: the top three categories plus an aggregated "other".
  final List<CategoryBreakdown> breakdown;

  /// Account used to fill the "رقم الحساب العائلي" row.
  ///
  /// TODO(backend): a **display fallback only** — the server returns the newest
  /// account, which is not the same thing as the family's primary one. The
  /// schema has no way to identify one: no `accounts.is_primary`, no account
  /// number, no `families` table. The masked number rendered beside it is mock
  /// data until that changes.
  final Account? primaryAccount;

  /// The signed-in member's ceiling, or null for a parent — a parent is not
  /// capped, and the server omits these three fields for them entirely.
  final num? spendingLimit;
  final num? spentOfLimit;
  final num? remainingLimit;

  const DashboardSummary({
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.breakdown,
    this.primaryAccount,
    this.spendingLimit,
    this.spentOfLimit,
    this.remainingLimit,
  });

  /// "المتبقي" — income minus expenses.
  ///
  /// Can go negative when the family overspent, which is the truthful figure;
  /// the widget decides how to colour it.
  num get remaining => income - expenses;

  /// True when the signed-in user is a capped member, so the screen can show
  /// their allowance instead of family-wide figures.
  bool get hasSpendingLimit => spendingLimit != null;

  /// How many slices the donut draws before grouping the rest into "أخرى".
  ///
  /// Mirrors `DashboardController::TOP_CATEGORIES`. Kept here because the mock
  /// path still aggregates locally.
  static const int topCategoryCount = 3;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalBalance: _toNum(json['total_balance']) ?? 0,
        income: _toNum(json['income']) ?? 0,
        expenses: _toNum(json['expenses']) ?? 0,
        breakdown: [
          for (final slice in (json['breakdown'] as List? ?? const []))
            if (slice is Map<String, dynamic>)
              CategoryBreakdown.fromJson(slice),
        ],
        primaryAccount: json['primary_account'] is Map<String, dynamic>
            ? Account.fromJson(json['primary_account'])
            : null,
        // Absent for a parent, which reads correctly as "not capped".
        spendingLimit: _toNum(json['spending_limit']),
        spentOfLimit: _toNum(json['spent_of_limit']),
        remainingLimit: _toNum(json['remaining_limit']),
      );

  /// Aggregates raw rows into the shape the UI needs.
  ///
  /// **Mock path only.** The remote path parses the server's own summary — see
  /// [DashboardSummary.fromJson]. This stays because `MockStore` has no server,
  /// and because it is the reference the SQL version was checked against: both
  /// produce the same totals and the same four slices on the seeded data.
  factory DashboardSummary.from({
    required List<Account> accounts,
    required List<TransactionModel> transactions,
    num? spendingLimit,
    num? spentOfLimit,
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
      // Transfer legs are skipped entirely: moving money between two of the
      // family's accounts writes a real expense row and a real income row —
      // which is what keeps both balances right — but counting them would add
      // the same amount to "الدخل" and "المصاريف" without a riyal entering or
      // leaving, and would put the transfer's filler category into the donut.
      if (t.isTransfer) continue;

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
      primaryAccount: accounts.isEmpty ? null : accounts.first,
      spendingLimit: spendingLimit,
      spentOfLimit: spendingLimit == null ? null : (spentOfLimit ?? 0),
      // Floored at zero, like `DashboardController`: a member who has already
      // overshot has nothing left, not a negative allowance.
      remainingLimit: spendingLimit == null
          ? null
          : _atLeastZero(spendingLimit - (spentOfLimit ?? 0)),
    );
  }

  static num _atLeastZero(num value) => value < 0 ? 0 : value;

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

/// The two things the dashboard loads together.
class DashboardData {
  final DashboardSummary summary;

  /// The family, each with what they have spent against their allowance.
  ///
  /// From `GET /users`, not from the dashboard payload: that endpoint already
  /// computes `spent` and `remaining` per member, and a second source for the
  /// same numbers is a second thing to keep agreeing.
  ///
  /// Empty for a member, who is only ever given themselves — so the home card
  /// that draws this simply does not appear on a child's screen.
  final List<User> members;

  /// Newest-first, already truncated to what "آخر المعاملات" shows. The server
  /// applies the limit, so the client never receives rows it will not draw.
  final List<TransactionModel> recentTransactions;

  const DashboardData({
    required this.summary,
    required this.recentTransactions,
    this.members = const <User>[],
  });

  /// Members who carry an allowance — the ones the family card is about.
  ///
  /// A parent has no ceiling, so listing them would put a row with nothing to
  /// report between the rows that have something to report.
  List<User> get children => [
    for (final m in members)
      if (!m.isParent) m,
  ];

  /// True when there is a family worth drawing a card for.
  bool get hasFamily => children.isNotEmpty;
}

/// Laravel returns `DECIMAL` columns as strings, and drops a zero fraction on
/// computed floats, so both a string and a number have to be accepted.
num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
