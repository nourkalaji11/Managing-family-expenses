import 'package:family_expense_management/data/mock/dashboard_mock_source.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/category.dart';

/// SEED DATA ONLY — the starting state of the fake budgets.
///
/// ---------------------------------------------------------------------------
/// THIS FILE IS THROW-AWAY, exactly like [DashboardMockSource]. It exists only
/// because `BudgetController` implements just `index` and `store`, and `store`
/// cannot succeed against the real schema — see `BudgetsRepo` for the details.
///
/// It is **immutable seed data, not the runtime collection**. Exactly one
/// consumer reads it: `MockStore`, which copies it once at construction and owns
/// every mutation from then on.
///
///     BudgetsMockSource  ->  MockStore  ->  BudgetsRepo
///
/// To run against the real API: build with `--dart-define=USE_MOCK=false` and
/// an `API_BASE_URL`. Nothing here has to be deleted for that.
/// ---------------------------------------------------------------------------
///
/// Two things are deliberately **not** declared here:
///
///   * **Categories.** They are looked up from
///     [DashboardMockSource.categories] by id, so a budget can never name a
///     category the transactions do not also use — which is what makes the
///     derived spending on the budgets screen agree with the dashboard's
///     breakdown.
///   * **Ownership.** `user_id` is left unset. `MockStore` stamps the seeded
///     rows with the one session-wide `currentUserId` it already derives from
///     the transaction seed, so budgets and transactions can never disagree
///     about who owns them and no second literal id enters the mock layer.
///
/// Amounts are chosen so the seeded transactions land the cards across the four
/// states the design draws (early stage / on track / near limit / exceeded)
/// without hard-coding any spent figure: `BudgetsRepo` derives every "صرفت"
/// value from the transactions inside each budget's own period.
class BudgetsMockSource {
  const BudgetsMockSource._();

  /// Budgets for the current calendar month.
  ///
  /// The period is the month the app is run in, so the list screen's month
  /// selector opens on a month that actually has data — the same reasoning
  /// behind [DashboardMockSource.transactions] using relative dates.
  static List<BudgetModel> budgets() {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, 1);
    // Day 0 of next month is the last day of this one, which keeps this correct
    // for 28-, 29-, 30- and 31-day months without a lookup table.
    final DateTime end = DateTime(now.year, now.month + 1, 0);

    return [
      _budget(id: 1, categoryId: 1, limit: 2000, start: start, end: end),
      _budget(id: 2, categoryId: 2, limit: 1500, start: start, end: end),
      _budget(id: 3, categoryId: 3, limit: 1000, start: start, end: end),
      _budget(id: 4, categoryId: 4, limit: 500, start: start, end: end),
    ];
  }

  static BudgetModel _budget({
    required int id,
    required int categoryId,
    required num limit,
    required DateTime start,
    required DateTime end,
  }) => BudgetModel(
    id: id,
    limitAmount: limit,
    // The column's own default. `BudgetsRepo` replaces this with the value
    // derived from the transactions in the period, because nothing on the
    // backend maintains the column — see `BudgetModel.currentSpending`.
    currentSpending: 0,
    startDate: start,
    endDate: end,
    // `userId` is deliberately absent — see the class doc.
    categoryId: categoryId,
    // Ordered a minute apart so `latest()`-style sorting is deterministic
    // instead of depending on list position.
    createdAt: start.add(Duration(minutes: id)),
    category: _categoryById(categoryId),
  );

  /// A plain loop rather than `firstWhereOrNull`, which lives in
  /// `package:collection` and is not a direct dependency of this project.
  static Category? _categoryById(int id) {
    for (final c in DashboardMockSource.categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
