import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/budgets_data.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/budgets/domain/budgets_domain.dart';

/// The budgets feature's data source.
///
/// MOCK-ONLY FOR NOW. [useMock] comes from [kUseMockData], the app's single
/// switch, and this class makes no network calls at all: `DioClient` is
/// deliberately not imported.
///
/// Why the real endpoints are not called, verified against branch
/// `origin/souad-backend`:
///
///   * `GET /api/budgets` works, but runs
///     `Budget::with('category')->latest()->get()` with no `paginate()` and no
///     `where('user_id', ...)`, so it returns every user's rows.
///     `routes/api.php` applies no middleware.
///   * `POST /api/budgets` validates only `category_id` and `limit_amount`, then
///     calls `Budget::updateOrCreate(['category_id' => ...], ...)`. The NOT NULL
///     `user_id`, `start_date` and `end_date` columns are neither validated nor
///     set, so every call fails on an integrity-constraint violation. The match
///     key carries no user scope either, so one family's budget would overwrite
///     another's.
///   * `PUT/PATCH`, `GET /{id}` and `DELETE /{id}` do not exist on
///     `BudgetController` at all, even though `Route::apiResource` registers
///     them — calling any of them is a 500, not a 404.
///   * `GlobalApiEndpoint.base` is still `https://domain/api/v1`, and the
///     backend serves `/api/budgets` with no `v1` segment.
///
/// To go live: add the endpoints to `GlobalApiEndpoint`, implement the
/// `_remote*` methods below following the try/catch shape used by
/// `NotificationsRepo`, flip [kUseMockData] to `false`, and delete
/// `lib/data/mock/`. The draft-to-JSON mapping already exists as
/// `BudgetDraft.toRequestJson()`.
class BudgetsRepo extends BudgetsDomain {
  /// Mirrors the app-wide switch. Not an independent flag, so the dashboard,
  /// transactions and budgets can never disagree about which world they are in.
  static const bool useMock = kUseMockData;

  /// Simulated latency, so the loading state is actually exercised during
  /// development. Matches `DashboardRepo.mockDelay`.
  static const Duration mockDelay = Duration(milliseconds: 600);

  /// Writes settle faster than reads, for the same reason as in
  /// `TransactionsRepo`: the form shows a spinner on its save button.
  static const Duration mockWriteDelay = Duration(milliseconds: 350);

  @override
  Future<Either<Failure, BudgetsData>> getBudgets() async {
    if (useMock) return _mockGet();
    return _remoteGet();
  }

  @override
  Future<Either<Failure, BudgetModel>> createBudget(BudgetDraft draft) async {
    if (useMock) return _mockCreate(draft);
    return _remoteCreate(draft);
  }

  @override
  Future<Either<Failure, BudgetModel>> updateBudget(
    int id,
    BudgetDraft draft,
  ) async {
    if (useMock) return _mockUpdate(id, draft);
    return _remoteUpdate(id, draft);
  }

  // ---------------------------------------------------------------------------
  // Mock path. Every method goes through `MockStore.instance`, the one mutable
  // collection for the session, so a transaction added on the Transactions tab
  // moves the spent and remaining figures here.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, BudgetsData>> _mockGet() async {
    try {
      await Future.delayed(mockDelay);

      final store = MockStore.instance;
      return Right(
        BudgetsData(
          budgets: withDerivedSpending(
            sortedNewestFirst(store.budgets),
            store.transactions,
          ),
          categories: store.categories,
        ),
      );
    } catch (e) {
      // Defensive only: the mock cannot realistically throw, but returning a
      // Left keeps the Either contract honest.
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, BudgetModel>> _mockCreate(BudgetDraft draft) async {
    try {
      await Future.delayed(mockWriteDelay);

      final store = MockStore.instance;

      // `MockStore.currentUserId` is derived from the seed and is nullable on
      // purpose. Failing loudly beats writing a row with an invented owner.
      final userId = store.currentUserId;
      if (userId == null) {
        return Left(ResultFailure('transactions.error_no_user'.tr()));
      }

      final category = store.categoryById(draft.categoryId);
      if (category == null) {
        // The real backend enforces this with `exists:categories,id`; the mock
        // enforces the same rule locally.
        return Left(ResultFailure('budgets.error_invalid_category'.tr()));
      }

      final budget = BudgetModel(
        id: store.allocateBudgetId(),
        limitAmount: draft.limitAmount,
        // The column's default. The real value is derived on read, because
        // nothing maintains the column — see `BudgetModel.currentSpending`.
        currentSpending: 0,
        startDate: draft.startDate,
        endDate: draft.endDate,
        userId: userId,
        categoryId: category.id,
        // The row is being created now, so this is a genuine insert timestamp
        // rather than a fabricated one.
        createdAt: DateTime.now(),
        category: category,
      );

      store.addBudget(budget);
      return Right(budget);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, BudgetModel>> _mockUpdate(
    int id,
    BudgetDraft draft,
  ) async {
    try {
      await Future.delayed(mockWriteDelay);

      final store = MockStore.instance;

      final BudgetModel? existing = store.budgetById(id);
      if (existing == null) {
        return Left(ResultFailure('budgets.error_not_found'.tr()));
      }

      final category = store.categoryById(draft.categoryId);
      if (category == null) {
        return Left(ResultFailure('budgets.error_invalid_category'.tr()));
      }

      // `copyWith` replaces only the form-owned fields. `id`, `createdAt` and
      // `userId` are not passed, so they carry over untouched: editing a budget
      // must not move its creation timestamp or change its owner.
      final updated = existing.copyWith(
        limitAmount: draft.limitAmount,
        startDate: draft.startDate,
        endDate: draft.endDate,
        categoryId: category.id,
        // The relation object is replaced alongside the id, so the card can
        // never render a category name that disagrees with its `categoryId`.
        category: category,
      );

      // Replaces in place, keyed by id, so an edit can never append a duplicate.
      if (!store.updateBudget(updated)) {
        return Left(ResultFailure('budgets.error_not_found'.tr()));
      }
      return Right(updated);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  // ---------------------------------------------------------------------------
  // Derivation, shared by both paths so the two can never disagree.
  // ---------------------------------------------------------------------------

  /// Fills each budget's `current_spending` from the transactions that fall
  /// inside its own period.
  ///
  /// TODO(backend): this belongs server-side. The column exists but nothing
  /// writes it (see `BudgetModel.currentSpending`), so the client computes what
  /// the column is meant to hold. When the backend starts maintaining it —
  /// through an observer on `transactions`, a scheduled recompute, or a
  /// `withSum` on the query — delete this method and trust the payload, because
  /// a client-side sum can only ever see the rows the client happens to have.
  static List<BudgetModel> withDerivedSpending(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    return [
      for (final b in budgets)
        b.copyWith(currentSpending: spentFor(b, transactions)),
    ];
  }

  /// Total expense amount booked against [budget]'s category inside its period.
  ///
  /// Income is excluded: a budget caps spending, so counting a salary against it
  /// would reduce the consumed figure. The date used is the transaction's own
  /// `date` (falling back to `created_at`), matching how `TransactionsBloc`
  /// groups rows — a back-dated expense counts in the period it happened, not
  /// the one it was typed in.
  static num spentFor(BudgetModel budget, List<TransactionModel> transactions) {
    final int? categoryId = budget.categoryId ?? budget.category?.id;
    if (categoryId == null) return 0;

    num total = 0;
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      if ((t.categoryId ?? t.category?.id) != categoryId) continue;

      final DateTime? day = t.date ?? t.createdAt;
      if (day == null) continue;
      if (!budget.containsDay(day)) continue;

      total += t.amount ?? 0;
    }
    return total;
  }

  /// Newest first, mirroring `BudgetController::index`'s `latest()`.
  ///
  /// `created_at` is the ordering column; `id` breaks ties, and rows carrying
  /// neither sort last rather than throwing.
  static List<BudgetModel> sortedNewestFirst(List<BudgetModel> budgets) {
    // Copies first: the caller's list (and `MockStore`'s) is never reordered.
    final sorted = [...budgets]
      ..sort((a, b) {
        final DateTime? ca = a.createdAt;
        final DateTime? cb = b.createdAt;
        if (ca != null && cb != null) {
          final int byDate = cb.compareTo(ca);
          if (byDate != 0) return byDate;
        } else if (ca == null && cb != null) {
          return 1;
        } else if (ca != null && cb == null) {
          return -1;
        }

        return (b.id ?? 0).compareTo(a.id ?? 0);
      });
    return sorted;
  }

  // ---------------------------------------------------------------------------
  // Remote path. Unimplemented on purpose: see the class doc for why each of
  // these endpoints is either missing, broken, or unsafe to call. Returning a
  // ServerFailure is the honest behaviour — none of them may silently succeed.
  // ---------------------------------------------------------------------------

  /// TODO(backend): needs a user-scoped `index`, and `current_spending` to be
  /// maintained (or summed) server-side.
  Future<Either<Failure, BudgetsData>> _remoteGet() async {
    return Left(ServerFailure());
  }

  /// TODO(backend): `store()` must set `user_id`, `start_date` and `end_date`,
  /// and scope its `updateOrCreate` match by user, before this can be called.
  Future<Either<Failure, BudgetModel>> _remoteCreate(BudgetDraft draft) async {
    return Left(ServerFailure());
  }

  /// TODO(backend): `BudgetController` has no `update()` method at all.
  Future<Either<Failure, BudgetModel>> _remoteUpdate(
    int id,
    BudgetDraft draft,
  ) async {
    return Left(ServerFailure());
  }
}
