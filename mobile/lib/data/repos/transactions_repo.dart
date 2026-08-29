import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/transactions_data.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/transactions/domain/transactions_domain.dart';

/// The transactions feature's data source.
///
/// Live against the Laravel API when [useMock] is `false`, which is the default.
/// The mock path is kept compiling as a one-line rollback ([kUseMockData]).
///
/// Endpoint notes worth carrying at the call site:
///
///   * `GET /transactions` is **not paginated** — `index` runs
///     `Transaction::with(['account','category'])->latest()->get()`. Every row
///     the caller may see arrives in one response.
///   * `POST /transactions` sets `user_id` from the bearer token and adjusts
///     `accounts.balance` inside a `DB::transaction`, so the balance the
///     dashboard shows moves on its own after a write. The client must not
///     also adjust it.
///   * `POST` answers **403**, not 422, when a `member` exceeds the spending
///     limit their parent set. The body carries an Arabic `message`, which
///     [unwrapObject] surfaces verbatim — the user needs to read the actual
///     limit, not a generic "server error".
///
/// TODO(backend): `index` applies no `where('user_id', ...)` and the route
/// group has no policy, so any authenticated caller reads every family's rows.
/// Fine for a single-family deployment; a cross-tenant read as soon as it is
/// not one.
class TransactionsRepo extends TransactionsDomain {
  static DioClient client = DioClient();

  /// Mirrors the app-wide switch. Not an independent flag, so the dashboard and
  /// this feature can never disagree about which world they are in.
  static const bool useMock = kUseMockData;

  /// Simulated latency, so the loading state is actually exercised during
  /// development. Matches `DashboardRepo.mockDelay`.
  static const Duration mockDelay = Duration(milliseconds: 600);

  /// Writes settle faster than reads: the form shows a spinner on its save
  /// button, and a long delay there just feels broken.
  static const Duration mockWriteDelay = Duration(milliseconds: 350);

  @override
  Future<Either<Failure, TransactionsData>> getTransactions() async {
    if (useMock) return _mockGet();
    return _remoteGet();
  }

  @override
  Future<Either<Failure, TransactionModel>> createTransaction(
    TransactionDraft draft,
  ) async {
    if (useMock) return _mockCreate(draft);
    return _remoteCreate(draft);
  }

  @override
  Future<Either<Failure, TransactionModel>> updateTransaction(
    int id,
    TransactionDraft draft,
  ) async {
    if (useMock) return _mockUpdate(id, draft);
    return _remoteUpdate(id, draft);
  }

  @override
  Future<Either<Failure, bool>> deleteTransaction(int id) async {
    if (useMock) return _mockDelete(id);
    return _remoteDelete(id);
  }

  // ---------------------------------------------------------------------------
  // Mock path. Every method goes through `MockStore.instance`, the one mutable
  // collection for the session, so an add here shows up on the dashboard too.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, TransactionsData>> _mockGet() async {
    try {
      await Future.delayed(mockDelay);

      final store = MockStore.instance;
      return Right(
        TransactionsData(
          transactions: sortedNewestFirst(store.transactions),
          accounts: store.accounts,
          categories: store.categories,
        ),
      );
    } catch (e) {
      // Defensive only: the mock cannot realistically throw, but returning a
      // Left keeps the Either contract honest.
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, TransactionModel>> _mockCreate(
    TransactionDraft draft,
  ) async {
    try {
      await Future.delayed(mockWriteDelay);

      final store = MockStore.instance;

      // `MockStore.currentUserId` is derived from the seed and is nullable on
      // purpose. Failing loudly beats writing a row with an invented owner.
      final userId = store.currentUserId;
      if (userId == null) return Left(ResultFailure('transactions.error_no_user'.tr()));

      final account = store.accountById(draft.accountId);
      final category = store.categoryById(draft.categoryId);
      if (account == null || category == null) {
        // The real backend enforces this with `exists:accounts,id` /
        // `exists:categories,id`; the mock enforces the same rule locally.
        return Left(ResultFailure('transactions.error_invalid_selection'.tr()));
      }

      final transaction = TransactionModel(
        id: store.allocateId(),
        amount: draft.amount,
        type: draft.type,
        description: draft.description,
        date: draft.date,
        // The row is being created now, so this is a genuine insert timestamp
        // rather than a fabricated one.
        createdAt: DateTime.now(),
        userId: userId,
        accountId: account.id,
        categoryId: category.id,
        account: account,
        category: category,
      );

      store.add(transaction);
      return Right(transaction);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, TransactionModel>> _mockUpdate(
    int id,
    TransactionDraft draft,
  ) async {
    try {
      await Future.delayed(mockWriteDelay);

      final store = MockStore.instance;

      TransactionModel? existing;
      for (final t in store.transactions) {
        if (t.id == id) {
          existing = t;
          break;
        }
      }
      if (existing == null) {
        return Left(ResultFailure('transactions.error_not_found'.tr()));
      }

      final account = store.accountById(draft.accountId);
      final category = store.categoryById(draft.categoryId);
      if (account == null || category == null) {
        return Left(ResultFailure('transactions.error_invalid_selection'.tr()));
      }

      // `copyWith` replaces only the form-owned fields. `id`, `createdAt` and
      // `userId` are not passed, so they carry over untouched: editing a row
      // must not move its creation timestamp or change its owner.
      final updated = existing.copyWith(
        amount: draft.amount,
        type: draft.type,
        description: draft.description,
        date: draft.date,
        accountId: account.id,
        categoryId: category.id,
        // The relation objects are replaced alongside the ids, so the row can
        // never render an account name that disagrees with its `accountId`.
        account: account,
        category: category,
      );

      // Replaces in place, keyed by id, so an edit can never append a duplicate.
      if (!store.update(updated)) {
        return Left(ResultFailure('transactions.error_not_found'.tr()));
      }
      return Right(updated);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, bool>> _mockDelete(int id) async {
    try {
      await Future.delayed(mockWriteDelay);

      final store = MockStore.instance;
      if (!store.remove(id)) {
        return Left(ResultFailure('transactions.error_not_found'.tr()));
      }
      return const Right(true);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  /// Newest first, with undated rows last rather than throwing.
  ///
  /// Shared by both paths on purpose, and identical to `DashboardRepo`'s
  /// comparator so the two screens can never order the same rows differently.
  static List<TransactionModel> sortedNewestFirst(
    List<TransactionModel> transactions,
  ) {
    // Copies first: the caller's list (and `MockStore`'s) is never reordered.
    final sorted = [...transactions]
      ..sort((a, b) {
        final da = a.displayedAt;
        final db = b.displayedAt;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    return sorted;
  }

  // ---------------------------------------------------------------------------
  // Remote path. Status handling lives in `unwrapList` / `unwrapObject`, which
  // throw a `Failure` that the `on Failure` catch below turns into a Left — the
  // same ladder `NotificationsRepo` uses, minus the duplication.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, TransactionsData>> _remoteGet() async {
    try {
      // Concurrent: the three are independent, and the form's pickers need the
      // accounts and categories the moment the list is on screen.
      final responses = await Future.wait([
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.transactions.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.accounts.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.categories.endpoint,
        ),
      ]);

      final transactions = [
        for (final json in unwrapList(responses[0]))
          TransactionModel.fromJson(json),
      ];

      return Right(
        TransactionsData(
          // Re-sorted client-side even though `index` already applies
          // `latest()`: that orders by `created_at`, while the app groups rows
          // by the transaction's own `date`. Sorting here keeps the remote and
          // mock paths byte-identical in ordering.
          transactions: sortedNewestFirst(transactions),
          accounts: [
            for (final json in unwrapList(responses[1])) Account.fromJson(json),
          ],
          categories: [
            for (final json in unwrapList(responses[2])) Category.fromJson(json),
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

  Future<Either<Failure, TransactionModel>> _remoteCreate(
    TransactionDraft draft,
  ) async {
    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.transactions.endpoint,
        body: draft.toRequestJson(),
      );

      // `store` eager-loads `account` and `category` before responding, so the
      // returned row can be rendered immediately without re-fetching the list.
      return Right(TransactionModel.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, TransactionModel>> _remoteUpdate(
    int id,
    TransactionDraft draft,
  ) async {
    try {
      final response = await client.request(
        requestType: RequestType.put,
        path: GlobalApiEndpoint.transactionById[[id]],
        body: draft.toRequestJson(),
      );

      // The body carries no `user_id`, so the row keeps its original owner;
      // `update` reverses the old amount's effect on the account balance before
      // applying the new one.
      return Right(TransactionModel.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, bool>> _remoteDelete(int id) async {
    try {
      final response = await client.request(
        requestType: RequestType.delete,
        path: GlobalApiEndpoint.transactionById[[id]],
      );

      // The 422 "this is a transfer leg" case throws a `ResultFailure` carrying
      // the server's own message, which names the right action — the app has no
      // better wording for a rule it does not own.
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
