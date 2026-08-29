import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/accounts_data.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/accounts/domain/accounts_domain.dart';

/// The accounts feature's data source.
///
/// Reads `MockStore` when `kUseMockData` is on, the Laravel API when it is off.
/// The mock is faithful where the UI can observe the difference: it enforces the
/// same delete guard the server does, so the 409 path is reachable offline
/// rather than only against a running backend.
///
/// Endpoint notes worth carrying at the call site:
///
///   * `POST /accounts` sets `user_id` from the bearer token, so
///     [AccountDraft] does not send one.
///   * `PUT /accounts/{id}` writes `balance` **directly**. It does not create a
///     balancing transaction. That is correct for what the form calls it — an
///     opening balance, i.e. a manual correction — but it means the account's
///     transaction history will not explain the change.
///   * `DELETE /accounts/{id}` answers **409** with an Arabic message when the
///     account still holds transactions, instead of cascading the delete
///     through to them. [unwrapList] surfaces that message verbatim.
class AccountsRepo extends AccountsDomain {
  static DioClient client = DioClient();

  static const bool useMock = kUseMockData;

  static const Duration mockDelay = Duration(milliseconds: 500);
  static const Duration mockWriteDelay = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, AccountsData>> getAccounts() async {
    if (useMock) return _mockGet();

    try {
      // One request. This used to be two: `/transactions` was fetched whole
      // purely so [countByAccount] could produce the number under each account
      // name. `AccountController::index` now returns `transactions_count` from
      // a `withCount`, so the extra download is gone and the figure covers
      // every row rather than the ones the client happened to hold.
      final response = await client.request(
        requestType: RequestType.get,
        path: GlobalApiEndpoint.accounts.endpoint,
      );

      final accounts = [
        for (final json in unwrapList(response)) Account.fromJson(json),
      ];

      return Right(
        AccountsData(
          accounts: accounts,
          transactionCounts: {
            for (final a in accounts)
              if (a.id != null && a.transactionsCount != null)
                a.id!: a.transactionsCount!,
          },
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

  @override
  Future<Either<Failure, Account>> createAccount(AccountDraft draft) async {
    if (useMock) return _mockCreate(draft);

    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.accounts.endpoint,
        body: draft.toRequestJson(),
      );

      return Right(Account.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, Account>> updateAccount(
    int id,
    AccountDraft draft,
  ) async {
    if (useMock) return _mockUpdate(id, draft);

    try {
      final response = await client.request(
        requestType: RequestType.put,
        path: GlobalApiEndpoint.accountById[[id]],
        body: draft.toRequestJson(),
      );

      return Right(Account.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAccount(int id) async {
    if (useMock) return _mockDelete(id);

    try {
      final response = await client.request(
        requestType: RequestType.delete,
        path: GlobalApiEndpoint.accountById[[id]],
      );

      // The 409 "still holds transactions" case throws a `ResultFailure`
      // carrying the server's own message, which is more useful than anything
      // this app could phrase — it names the exact count.
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

  // ---------------------------------------------------------------------------
  // Mock path. Reads and writes `MockStore`, so an account added here changes
  // the dashboard's total balance and shows up in the transaction form's picker.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, AccountsData>> _mockGet() async {
    await Future.delayed(mockDelay);

    final store = MockStore.instance;
    final accounts = store.accounts;

    return Right(
      AccountsData(
        accounts: accounts,
        // Counted here, not carried on the model. The server derives this per
        // request with a `withCount`; deriving it per read is what keeps the
        // subtitle correct after a transaction is added or deleted, which a
        // stored count would miss.
        transactionCounts: {
          for (final a in accounts)
            if (a.id != null) a.id!: store.countTransactionsForAccount(a.id),
        },
      ),
    );
  }

  Future<Either<Failure, Account>> _mockCreate(AccountDraft draft) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    final account = Account(
      id: store.allocateAccountId(),
      name: draft.name,
      balance: draft.balance,
      // `AccountController::store` takes the owner from the bearer token; the
      // mock takes it from the signed-in user, which is the same claim.
      userId: store.currentUserId,
    );

    store.addAccount(account);
    return Right(account);
  }

  Future<Either<Failure, Account>> _mockUpdate(
    int id,
    AccountDraft draft,
  ) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    final existing = store.accountById(id);
    if (existing == null) {
      return Left(ResultFailure('accounts.error_not_found'.tr()));
    }

    // `userId` is carried forward rather than re-derived: an edit must not
    // change who owns the account, and the server preserves it for the same
    // reason. `Account` has no `copyWith`, so this is spelled out.
    final updated = Account(
      id: existing.id,
      name: draft.name,
      // Written directly, no balancing transaction — see the class comment.
      balance: draft.balance,
      userId: existing.userId,
    );

    if (!store.updateAccount(updated)) {
      return Left(ResultFailure('accounts.error_not_found'.tr()));
    }
    return Right(updated);
  }

  Future<Either<Failure, bool>> _mockDelete(int id) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    if (store.accountById(id) == null) {
      return Left(ResultFailure('accounts.error_not_found'.tr()));
    }

    // The server's 409. Enforced here too, because the alternative is a mock
    // build where the delete always succeeds and silently orphans every
    // transaction pointing at the account — the dashboard would then show
    // balances that no account explains.
    final count = store.countTransactionsForAccount(id);
    if (count > 0) {
      return Left(
        ResultFailure(
          'accounts.error_has_transactions'.tr(
            namedArgs: {'count': count.toString()},
          ),
        ),
      );
    }

    store.removeAccount(id);
    return const Right(true);
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
