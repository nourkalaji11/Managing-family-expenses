import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/transactions_data.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/transactions/domain/transactions_domain.dart';

/// The transactions feature's data source.
///
/// MOCK-ONLY FOR NOW. [useMock] comes from [kUseMockData], the app's single
/// switch, and this class makes no network calls at all: `DioClient` is
/// deliberately not imported.
///
/// Why the real endpoints are not called, verified against branch
/// `origin/souad-backend`:
///
///   * `GET /api/transactions` works, but runs
///     `Transaction::with(['account','category'])->latest()->get()` with no
///     `paginate()` and no `where('user_id', ...)`, so it returns every user's
///     rows. `routes/api.php` applies no middleware.
///   * `POST /api/transactions` validates six fields and then calls
///     `Transaction::create($validated)`. `user_id` is neither validated nor
///     set, but the column is `foreignId()->constrained()`, i.e. NOT NULL, so
///     every call fails on an integrity-constraint violation.
///   * `PUT/PATCH /api/transactions/{id}` is an empty stub. It returns 200 and
///     changes nothing, which is the worst possible failure mode for a form:
///     the UI would report success on every save while the database never moved.
///   * `GET /api/transactions/{id}` is an empty stub too.
///   * `GlobalApiEndpoint.base` is still `https://domain/api/v1`, and the
///     backend serves `/api/transactions` with no `v1` segment.
///
/// To go live: add the endpoints to `GlobalApiEndpoint`, implement the
/// `_remote*` methods below following the try/catch shape used by
/// `NotificationsRepo`, flip [kUseMockData] to `false`, and delete
/// `lib/data/mock/`. The draft-to-JSON mapping already exists as
/// `TransactionDraft.toRequestJson()`.
class TransactionsRepo extends TransactionsDomain {
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
  // Remote path. Unimplemented on purpose: see the class doc for why each of
  // these endpoints is either missing, broken, or unsafe to call. Returning a
  // ServerFailure is the honest behaviour — none of them may silently succeed.
  // ---------------------------------------------------------------------------

  /// TODO(backend): needs a user-scoped, paginated `index`.
  Future<Either<Failure, TransactionsData>> _remoteGet() async {
    return Left(ServerFailure());
  }

  /// TODO(backend): `store()` must set `user_id` before this can be called.
  Future<Either<Failure, TransactionModel>> _remoteCreate(
    TransactionDraft draft,
  ) async {
    return Left(ServerFailure());
  }

  /// TODO(backend): `update()` is an empty stub and must be implemented.
  Future<Either<Failure, TransactionModel>> _remoteUpdate(
    int id,
    TransactionDraft draft,
  ) async {
    return Left(ServerFailure());
  }
}
