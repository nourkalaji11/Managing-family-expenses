import 'package:family_expense_management/data/mock/budgets_mock_source.dart';
import 'package:family_expense_management/data/mock/dashboard_mock_source.dart';
import 'package:family_expense_management/data/mock/family_mock_source.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/user.dart';

/// The one mutable in-memory dataset for the running session.
///
/// Runtime flow:
///
///   DashboardMockSource / BudgetsMockSource / FamilyMockSource
///     (seed data, immutable literals)
///     -> seeded exactly once ->
///   MockStore            (the single mutable collection)
///     -> read by ->
///   every repository: dashboard, transactions, budgets, accounts, categories,
///   profile, notifications, transfers and auth
///
/// The seed sources are seed data ONLY. After [instance] is first read, nothing
/// calls `DashboardMockSource.transactions()` or `BudgetsMockSource.budgets()`
/// again. If a repository did, every add and edit made during the session would
/// silently vanish the next time that screen loaded.
///
/// Because every repository reads this one object, the app stays internally
/// consistent under the mock the way it does under the server: a transaction
/// added on the Transactions tab moves its account's balance, the dashboard's
/// income, expenses, remaining and breakdown, the spent figure on the Budgets
/// tab, the count under the account and category rows, and — if it crosses a
/// budget or a member's ceiling — the notifications tab. None of that is
/// special-cased; it falls out of there being one dataset.
///
/// Not read at all when `kUseMockData` is off: every repository branches before
/// it touches this class, so a live build carries the seed as dead weight in the
/// binary and nothing more.
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

    // People are seeded before anything derived from them. `_seededUserId` used
    // to be read off the first transaction's `user_id`, which meant the mock
    // could describe an owner it could not name. It now comes from the family
    // itself, and the transactions' `user_id` agrees with it because the two
    // seeds share the same literal — see `FamilyMockSource.signedInUserId`.
    _users = FamilyMockSource.users();
    // The seed's owner. Distinct from the session — nobody is signed in yet at
    // construction time, and conflating the two is what let a member's writes
    // be judged against the parent's permissions.
    _seededUserId = FamilyMockSource.signedInUserId;
    _nextUserId = _highestId<User>(_users, (u) => u.id) + 1;

    _notifications = FamilyMockSource.notifications();
    _nextNotificationId =
        _highestId<AppNotification>(_notifications, (n) => n.id) + 1;

    _nextId = _highestSeededId() + 1;
    _nextAccountId = _highestId<Account>(_accounts, (a) => a.id) + 1;
    _nextCategoryId = _highestId<Category>(_categories, (c) => c.id) + 1;

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
  late final List<User> _users;
  late final List<AppNotification> _notifications;

  /// Monotonic id allocator. See [allocateId] for the collision guarantee.
  late int _nextId;

  /// Every table has its own primary key on the server, so each gets its own
  /// allocator here rather than sharing one sequence. Sharing would hand out
  /// gappy ids that no real database would produce, and hide off-by-one bugs in
  /// any screen that assumes ids are dense.
  late int _nextBudgetId;
  late int _nextAccountId;
  late int _nextCategoryId;
  late int _nextUserId;
  late int _nextNotificationId;

  late final int? _seededUserId;

  /// Who new rows are attributed to — the signed-in user, not the seed's owner.
  ///
  /// Null before anyone signs in, and callers must handle that: inventing an
  /// owner would be exactly the fabricated backend behaviour this mock exists to
  /// avoid. `TransactionsRepo.create` surfaces a failure rather than writing an
  /// unattributed row.
  int? get currentUserId => signedInUser?.id;

  /// The signed-in user. Everything the mock does is done as this person: there
  /// is one session, so the family scoping the server applies per-request is a
  /// no-op here and is not reimplemented.
  ///
  /// This follows the **session**, not the seed. It used to return the seeded
  /// user unconditionally, which made every role check in the mock answer for
  /// the parent no matter who had actually logged in: a member's spending
  /// ceiling was never applied, their dashboard drew the parent's layout, and
  /// the family list showed them everybody. Signing in is what sets it — see
  /// [signInAs].
  User? get signedInUser => _signedIn();

  /// Binds the session to [userId]. Called by `AuthRepo` on login and register,
  /// and with null by `ProfileRepo` on logout.
  ///
  /// The store holds the id rather than the `User` so that an edit to the row —
  /// a rename, a new ceiling — is picked up on the next read instead of leaving
  /// a stale copy behind.
  void signInAs(int? userId) => _sessionUserId = userId;

  int? _sessionUserId;

  /// The whole family, in seed order. The server scopes this by role — a parent
  /// sees everyone, a member sees only themselves — and `ProfileRepo` applies
  /// that same rule on the way out rather than this getter, so the store stays a
  /// plain collection.
  List<User> get users => List.unmodifiable(_users);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  User? userById(int? id) {
    if (id == null) return null;
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

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

  /// Removes the budget with [id]. Returns false when no such row exists, so
  /// the caller surfaces a failure rather than reporting a delete that did
  /// nothing — the same contract as [remove].
  bool removeBudget(int id) {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index < 0) return false;
    _budgets.removeAt(index);
    return true;
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

  // ---------------------------------------------------------------------------
  // Accounts.
  //
  // `Account` has no `copyWith`, so an edit replaces the whole object. Note what
  // is NOT stored: `transactionsCount`. The server computes it per request with
  // `withCount`, and the mock does the same in `AccountsRepo` by counting
  // `_transactions`. Carrying it on the object would mean re-deriving it on
  // every write, and the first path that forgot would silently show 0.
  // ---------------------------------------------------------------------------

  int allocateAccountId() {
    final id = _walkPast(_nextAccountId, _accounts, (a) => a.id);
    _nextAccountId = id + 1;
    return id;
  }

  void addAccount(Account account) => _accounts.add(account);

  bool updateAccount(Account account) {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (account.id == null || index < 0) return false;
    _accounts[index] = account;
    return true;
  }

  bool removeAccount(int id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index < 0) return false;
    _accounts.removeAt(index);
    return true;
  }

  /// Moves [accountId]'s balance by [delta] and returns false when there is no
  /// such account.
  ///
  /// The one place balance arithmetic happens, because it is the invariant the
  /// whole dataset rests on: an account's balance must equal the sum of the
  /// transactions booked against it. The server keeps that true inside a
  /// `DB::transaction` on every write; here every caller — an expense, an edit,
  /// a delete, both legs of a transfer — goes through this method, so there is
  /// one place to check rather than five.
  ///
  /// `Account` has no `copyWith`, so the row is rebuilt field by field. Dropping
  /// `userId` here would silently re-own the account.
  bool adjustAccountBalance(int? accountId, num delta) {
    if (accountId == null) return false;

    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index < 0) return false;

    final account = _accounts[index];
    _accounts[index] = Account(
      id: account.id,
      name: account.name,
      balance: (account.balance ?? 0) + delta,
      userId: account.userId,
    );
    return true;
  }

  /// What [transaction] does to its account's balance: income adds, expense
  /// subtracts. Pass the negation to undo it.
  static num balanceEffectOf(TransactionModel transaction) {
    final amount = transaction.amount ?? 0;
    return transaction.isExpense ? -amount : amount;
  }

  /// How many transactions point at [accountId] — the number the account rows
  /// show as a subtitle, and the one the delete guard checks.
  ///
  /// Transfer legs are counted: they are real rows against the account and they
  /// do block a delete, exactly as on the server.
  int countTransactionsForAccount(int? accountId) {
    if (accountId == null) return 0;
    var count = 0;
    for (final t in _transactions) {
      if (t.accountId == accountId) count++;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Categories.
  // ---------------------------------------------------------------------------

  int allocateCategoryId() {
    final id = _walkPast(_nextCategoryId, _categories, (c) => c.id);
    _nextCategoryId = id + 1;
    return id;
  }

  void addCategory(Category category) => _categories.add(category);

  bool updateCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (category.id == null || index < 0) return false;
    _categories[index] = category;
    return true;
  }

  bool removeCategory(int id) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index < 0) return false;
    _categories.removeAt(index);
    return true;
  }

  /// Excludes transfer legs, matching `CategoryController::index` — a transfer
  /// borrows a category for schema reasons only, and counting it would inflate
  /// every tile the moment the user moved money.
  int countTransactionsForCategory(int? categoryId) {
    if (categoryId == null) return 0;
    var count = 0;
    for (final t in _transactions) {
      if (t.categoryId == categoryId && !t.isTransfer) count++;
    }
    return count;
  }

  int countBudgetsForCategory(int? categoryId) {
    if (categoryId == null) return 0;
    var count = 0;
    for (final b in _budgets) {
      if (b.categoryId == categoryId) count++;
    }
    return count;
  }

  /// True when another category already carries [name], ignoring [exceptId] so
  /// that renaming a category to its own name is not a conflict. Mirrors the
  /// server's `unique:categories,name`.
  bool categoryNameTaken(String name, {int? exceptId}) {
    final needle = name.trim().toLowerCase();
    for (final c in _categories) {
      if (c.id == exceptId) continue;
      if ((c.name ?? '').trim().toLowerCase() == needle) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Users.
  // ---------------------------------------------------------------------------

  int allocateUserId() {
    final id = _walkPast(_nextUserId, _users, (u) => u.id);
    _nextUserId = id + 1;
    return id;
  }

  void addUser(User user) => _users.add(user);

  /// Replaces the stored user with [user], matched on id.
  ///
  /// Note this replaces rather than merges: `User.copyWith` carries every field
  /// forward, so callers build the complete object and this method stays a
  /// straight swap.
  bool updateUser(User user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (user.id == null || index < 0) return false;
    _users[index] = user;
    return true;
  }

  /// True when [email] already belongs to somebody other than [exceptId].
  /// Mirrors the server's `unique:users,email`.
  bool emailTaken(String email, {int? exceptId}) {
    final needle = email.trim().toLowerCase();
    for (final u in _users) {
      if (u.id == exceptId) continue;
      if ((u.email ?? '').trim().toLowerCase() == needle) return true;
    }
    return false;
  }

  /// What [userId] has spent against their ceiling.
  ///
  /// **All time, not per month.** `TransactionController::store` sums the whole
  /// history when it decides whether to block an expense, and
  /// `DashboardController` sums the same rows so the figure on screen is the
  /// one that will actually stop the next purchase. A monthly window would read
  /// more naturally but would disagree with both.
  ///
  /// Income and transfer legs are excluded: a ceiling caps spending, and moving
  /// money between the family's own accounts is not spending.
  num spentAgainstLimitBy(int? userId) {
    if (userId == null) return 0;

    num total = 0;
    for (final t in _transactions) {
      if (t.userId != userId || !t.isExpense || t.isTransfer) continue;
      total += t.amount ?? 0;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Notifications.
  // ---------------------------------------------------------------------------

  int allocateNotificationId() {
    final id = _walkPast(_nextNotificationId, _notifications, (n) => n.id);
    _nextNotificationId = id + 1;
    return id;
  }

  /// Prepends, because notifications read newest-first and this is the newest.
  void addNotification(AppNotification notification) =>
      _notifications.insert(0, notification);

  bool markNotificationRead(int id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return false;
    _notifications[index] = _notifications[index].asSeen();
    return true;
  }

  void markAllNotificationsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].asSeen();
    }
  }

  bool removeNotification(int id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return false;
    _notifications.removeAt(index);
    return true;
  }

  int get unreadNotificationCount {
    var count = 0;
    for (final n in _notifications) {
      if (!n.seen) count++;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Transfers.
  //
  // There is no transfers collection. A transfer is two transaction rows sharing
  // a `transferGroupId`, exactly as the server stores it, so a transfer made on
  // the transfers tab moves both account balances and shows up in transaction
  // history without anything having to keep two collections agreeing.
  // ---------------------------------------------------------------------------

  /// The legs of [groupId], in insertion order — the outgoing one first.
  List<TransactionModel> transferLegs(String groupId) => [
    for (final t in _transactions)
      if (t.transferGroupId == groupId) t,
  ];

  /// Every transfer group present, newest group first.
  ///
  /// Grouping is done by walking the rows rather than with a map-of-lists so
  /// that leg order inside a group is preserved: the outgoing leg is written
  /// first and the UI relies on that to label "من" and "إلى".
  List<List<TransactionModel>> groupedTransfers() {
    final List<String> order = [];
    final Map<String, List<TransactionModel>> groups = {};

    for (final t in _transactions) {
      final group = t.transferGroupId;
      if (group == null) continue;
      if (!groups.containsKey(group)) {
        groups[group] = [];
        order.add(group);
      }
      groups[group]!.add(t);
    }

    return [for (final g in order.reversed) groups[g]!];
  }

  /// Removes both legs of [groupId]. Returns false when the group does not
  /// exist, so the caller surfaces a failure rather than reporting an undo that
  /// undid nothing. Restoring the balances is the repository's job — it owns the
  /// arithmetic for the write, and owns reversing it.
  bool removeTransferGroup(String groupId) {
    final before = _transactions.length;
    _transactions.removeWhere((t) => t.transferGroupId == groupId);
    return _transactions.length != before;
  }

  /// The session's user. A plain loop rather than `firstWhereOrNull`, which
  /// lives in `package:collection` and is not a direct dependency here.
  ///
  /// Returns null when nobody has signed in, rather than falling back to the
  /// seeded parent: a silent fallback is what hid the role bug this method used
  /// to have, and a null forces the caller to deal with "no session" explicitly.
  User? _signedIn() {
    final id = _sessionUserId;
    if (id == null) return null;

    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Highest id in [rows], or 0 when none carries one.
  static int _highestId<T>(List<T> rows, int? Function(T) idOf) {
    var highest = 0;
    for (final row in rows) {
      final id = idOf(row);
      if (id != null && id > highest) highest = id;
    }
    return highest;
  }

  /// Walks [candidate] forward past every id currently in use and returns the
  /// first free one, leaving the allocator one past it. Same collision guarantee
  /// as [allocateId], which predates this helper and is left as it is because it
  /// is the one allocator with a written contract other code depends on.
  static int _walkPast<T>(int candidate, List<T> rows, int? Function(T) idOf) {
    final Set<int> used = <int>{};
    for (final row in rows) {
      final id = idOf(row);
      if (id != null) used.add(id);
    }

    var next = candidate;
    while (used.contains(next)) {
      next++;
    }
    return next;
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
