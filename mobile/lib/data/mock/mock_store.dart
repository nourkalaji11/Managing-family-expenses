import 'package:family_expense_management/data/mock/budgets_mock_source.dart';
import 'package:family_expense_management/data/mock/dashboard_mock_source.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';

/// The one mutable in-memory dataset for the running session.
///
/// Runtime flow:
///
///   DashboardMockSource / BudgetsMockSource  (seed data, immutable literals)
///     -> seeded exactly once ->
///   MockStore            (the single mutable collection)
///     -> read by ->
///   DashboardRepo,  TransactionsRepo  and  BudgetsRepo
///
/// The seed sources are seed data ONLY. After [instance] is first read, nothing
/// calls `DashboardMockSource.transactions()` or `BudgetsMockSource.budgets()`
/// again. If a repository did, every add and edit made during the session would
/// silently vanish the next time that screen loaded.
///
/// Because every repository reads this one object, a transaction added on the
/// Transactions tab immediately affects the dashboard's income, expenses,
/// remaining, category breakdown and recent-transactions list — and the spent,
/// remaining and progress figures on the Budgets tab, which `BudgetsRepo`
/// derives from these same rows.
///
/// THIS FILE IS THROW-AWAY, exactly like the seed sources: it disappears with
/// `lib/data/mock/` when `kUseMockData` flips to `false`.
class MockStore {
  MockStore._() {
    // The one and only read of the seed. `transactions()` builds a fresh list of
    // fresh objects, so mutating `_transactions` can never write through to the
    // seed constants.
    _transactions = DashboardMockSource.transactions();

    // `DashboardMockSource.accounts` and `.categories` are `const` lists, which
    // are unmodifiable at runtime. Copying into growable lists keeps this class
    // uniform, and means a future "add account" flow does not have to special
    // case them.
    _accounts = List<Account>.of(DashboardMockSource.accounts);
    _categories = List<Category>.of(DashboardMockSource.categories);

    _seededUserId = _findSeededUserId();
    _nextId = _highestSeededId() + 1;

    // Budgets are seeded without an owner on purpose, then stamped with the one
    // id derived above, so there is a single ownership rule in the mock layer
    // rather than one per feature. See `BudgetsMockSource`.
    _budgets = [
      for (final b in BudgetsMockSource.budgets())
        b.copyWith(userId: _seededUserId),
    ];
    _nextBudgetId = _highestSeededBudgetId() + 1;
  }

  static MockStore? _instance;

  /// Lazily created, then reused for the rest of the session.
  static MockStore get instance => _instance ??= MockStore._();

  late final List<TransactionModel> _transactions;
  late final List<Account> _accounts;
  late final List<Category> _categories;
  late final List<BudgetModel> _budgets;

  /// Monotonic id allocator. See [allocateId] for the collision guarantee.
  late int _nextId;

  /// Budgets live in their own table with their own primary key, so they get
  /// their own allocator rather than sharing the transaction sequence.
  late int _nextBudgetId;

  late final int? _seededUserId;

  /// The user the seeded rows belong to, or null if the seed carries none.
  ///
  /// Derived from the seed data rather than hard-coded: there is deliberately no
  /// fallback to a literal id, because inventing an owner would be exactly the
  /// kind of fabricated backend behaviour this mock layer exists to avoid.
  /// Callers must handle null. `TransactionsRepo.create` surfaces a failure
  /// instead of writing an unattributed row.
  ///
  /// TODO(backend): there is no authenticated user to attribute a row to. The
  /// backend applies no auth middleware, and `TransactionController::store`
  /// never populates the NOT NULL `user_id` column, so this seed-derived value
  /// is the only thing standing in for ownership today.
  int? get currentUserId => _seededUserId;

  /// Newest-first is NOT guaranteed here. Ordering is the repository's job, so
  /// both the mock and the future remote path sort identically.
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  List<Account> get accounts => List.unmodifiable(_accounts);

  List<Category> get categories => List.unmodifiable(_categories);

  /// Ordering is the repository's job here too, so `BudgetsRepo` and a future
  /// remote path sort identically.
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);

  Account? accountById(int? id) {
    if (id == null) return null;
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? categoryById(int? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  BudgetModel? budgetById(int? id) {
    if (id == null) return null;
    for (final b in _budgets) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Returns an id that no row currently holds, and never returns it twice.
  ///
  /// A plain `_transactions.length + 1` counter would collide after an edit
  /// reorders or replaces rows, so the candidate is walked forward past every
  /// id that is actually in use before being handed out.
  int allocateId() {
    final Set<int> used = <int>{};
    for (final t in _transactions) {
      final id = t.id;
      if (id != null) used.add(id);
    }

    var candidate = _nextId;
    while (used.contains(candidate)) {
      candidate++;
    }
    _nextId = candidate + 1;
    return candidate;
  }

  /// Appends a row. [transaction] must already carry its allocated id, because
  /// the repository builds the complete model so that the mock and remote paths
  /// produce the same object.
  void add(TransactionModel transaction) {
    _transactions.add(transaction);
  }

  /// Replaces the row whose id matches [transaction]. Returns false when no such
  /// row exists, so the caller can surface a failure instead of silently
  /// creating a duplicate.
  bool update(TransactionModel transaction) {
    final id = transaction.id;
    if (id == null) return false;

    final index = _transactions.indexWhere((t) => t.id == id);
    if (index < 0) return false;

    _transactions[index] = transaction;
    return true;
  }

  /// Removes the row with [id]. Returns false when no such row exists, so the
  /// caller surfaces a failure rather than reporting a delete that did nothing
  /// — the same contract as [update].
  bool remove(int id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index < 0) return false;

    _transactions.removeAt(index);
    return true;
  }

  /// Returns a budget id that no row currently holds, and never returns it
  /// twice. Same collision walk as [allocateId], over the budgets table.
  int allocateBudgetId() {
    final Set<int> used = <int>{};
    for (final b in _budgets) {
      final id = b.id;
      if (id != null) used.add(id);
    }

    var candidate = _nextBudgetId;
    while (used.contains(candidate)) {
      candidate++;
    }
    _nextBudgetId = candidate + 1;
    return candidate;
  }

  /// Appends a budget. [budget] must already carry its allocated id, for the
  /// same reason as [add].
  void addBudget(BudgetModel budget) {
    _budgets.add(budget);
  }

  /// Replaces the budget whose id matches [budget]. Returns false when no such
  /// row exists, so the caller can surface a failure instead of silently
  /// creating a duplicate.
  bool updateBudget(BudgetModel budget) {
    final id = budget.id;
    if (id == null) return false;

    final index = _budgets.indexWhere((b) => b.id == id);
    if (index < 0) return false;

    _budgets[index] = budget;
    return true;
  }

  /// First non-null `user_id` in the seed. A plain loop rather than
  /// `firstOrNull`, which lives in `package:collection` and is not a direct
  /// dependency of this project.
  int? _findSeededUserId() {
    for (final t in _transactions) {
      final id = t.userId;
      if (id != null) return id;
    }
    return null;
  }

  int _highestSeededId() {
    var highest = 0;
    for (final t in _transactions) {
      final id = t.id;
      if (id != null && id > highest) highest = id;
    }
    return highest;
  }

  int _highestSeededBudgetId() {
    var highest = 0;
    for (final b in _budgets) {
      final id = b.id;
      if (id != null && id > highest) highest = id;
    }
    return highest;
  }
}
