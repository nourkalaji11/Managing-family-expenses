import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/budgets_data.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/budgets/domain/budgets_domain.dart';

/// The budgets feature's data source.
///
/// Mock or live, on [useMock] — see [kUseMockData], which defaults to the mock
/// so the app runs with no backend. Both paths are maintained; neither is a
/// leftover.
///
/// Endpoint notes worth carrying at the call site:
///
///   * `POST /budgets` is an **upsert**, not an insert:
///     `Budget::updateOrCreate(['category_id' => ..., 'user_id' => ...], ...)`.
///     Creating a second budget for a category the caller already budgeted
///     overwrites the first instead of adding a row. The app does not surface
///     that distinction anywhere, because the form offers no way to tell the
///     two apart either.
///   * `user_id` is taken from the bearer token, never from the request body —
///     which is why [BudgetDraft.toRequestJson] does not send one.
///   * `budgets.current_spending` is a real column that **nothing maintains**:
///     no controller writes it and there is no observer or scheduled recompute.
///     The server therefore always reports its `0.00` default, and
///     [withDerivedSpending] fills in what the column is meant to hold — which
///     is why [_remoteGet] also fetches transactions.
///
/// TODO(backend): `index` applies no `where('user_id', ...)`, same as
/// `TransactionController`. See `TransactionsRepo` for the cross-tenant note.
class BudgetsRepo extends BudgetsDomain {
  static DioClient client = DioClient();

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

  @override
  Future<Either<Failure, bool>> deleteBudget(int id) async {
    if (useMock) return _mockDelete(id);
    return _remoteDelete(id);
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
  /// **Mock path only.** The remote path no longer calls this:
  /// `BudgetController::index` computes the figure in SQL and the payload is
  /// trusted as-is — see [_remoteGet]. The method stays because `MockStore` has
  /// no server to compute anything, and because it is the reference the two
  /// implementations were checked against (both produce 555.5 / 180 / 420 on
  /// the seeded data).
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
      // A transfer's outgoing leg is an expense row filed under whatever
      // category the form happened to require, so counting it would consume a
      // budget the family never actually spent against. The server's own
      // `NotificationService::spentBefore` applies the same exclusion, so the
      // "budget exceeded" alert and this bar can never disagree.
      if (t.isTransfer) continue;
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
  // Remote path. Status handling lives in `unwrapList` / `unwrapObject`, which
  // throw a `Failure` that the `on Failure` catch below turns into a Left — the
  // same ladder `NotificationsRepo` uses, minus the duplication.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, BudgetsData>> _remoteGet() async {
    try {
      // Two concurrent reads. This used to be three: transactions were fetched
      // as well, purely so [withDerivedSpending] could fill in a figure the
      // server left at `0.00`.
      //
      // `BudgetController::index` now computes `current_spending` itself, so
      // the payload is authoritative and the third request is gone. That is
      // also a correctness win, not just one fewer round trip: a client-side
      // sum can only see the rows the client happens to hold, and now that
      // `/transactions` is scoped by role a member's own list would have
      // produced a smaller figure than the budget actually consumed.
      final responses = await Future.wait([
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.budgets.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.categories.endpoint,
        ),
      ]);

      final budgets = [
        for (final json in unwrapList(responses[0])) BudgetModel.fromJson(json),
      ];

      return Right(
        BudgetsData(
          // No derivation: the server's figure is trusted as-is.
          budgets: sortedNewestFirst(budgets),
          categories: [
            for (final json in unwrapList(responses[1]))
              Category.fromJson(json),
          ],
        ),
      );
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, BudgetModel>> _remoteCreate(BudgetDraft draft) async {
    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.budgets.endpoint,
        body: draft.toRequestJson(),
      );

      // `store` eager-loads `category` before responding, so the card can be
      // rendered immediately. `current_spending` comes back as the column's
      // `0.00` default; the next list load derives the real figure.
      return Right(BudgetModel.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, bool>> _mockDelete(int id) async {
    try {
      await Future.delayed(mockWriteDelay);

      // No guard and no balance to unwind: a budget owns nothing. Removing one
      // changes only what the Budgets tab draws — the transactions it was
      // measuring are untouched, which is why this is a plain removal where the
      // account and category deletes need a 409 check.
      if (!MockStore.instance.removeBudget(id)) {
        return Left(ResultFailure('budgets.error_not_found'.tr()));
      }
      return const Right(true);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, bool>> _remoteDelete(int id) async {
    try {
      final response = await client.request(
        requestType: RequestType.delete,
        path: GlobalApiEndpoint.budgetById[[id]],
      );

      // 404 carries the server's Arabic message, which `ensureSuccess` raises
      // as a `ResultFailure` — the same one a member gets for another family's
      // budget, deliberately, so probing ids reveals nothing.
      ensureSuccess(response);
      return const Right(true);
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, BudgetModel>> _remoteUpdate(
    int id,
    BudgetDraft draft,
  ) async {
    try {
      final response = await client.request(
        requestType: RequestType.put,
        path: GlobalApiEndpoint.budgetById[[id]],
        body: draft.toRequestJson(),
      );

      // The body carries no `user_id`, so the budget keeps its original owner.
      return Right(BudgetModel.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  /// Transport-level errors, mapped exactly as `NotificationsRepo` maps them.
  static Failure _mapDioException(DioException ex) {
    if (ex.type == DioExceptionType.connectionTimeout ||
        ex.type == DioExceptionType.sendTimeout ||
        ex.type == DioExceptionType.receiveTimeout ||
        ex.type == DioExceptionType.unknown) {
      return ConnectionFailure();
    }
    return GlobalFailure();
  }
}
