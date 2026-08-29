import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/accounts_data.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/accounts/domain/accounts_domain.dart';

/// The accounts feature's data source.
///
/// Live against the Laravel API only — there is deliberately no mock path here.
/// `kUseMockData` exists for the three features that were built before the
/// backend was wired; this one was built against it from the start, and adding
/// a seed nobody reads would be dead weight.
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

  @override
  Future<Either<Failure, AccountsData>> getAccounts() async {
    try {
      // Concurrent. Transactions are fetched only to count them per account;
      // see `AccountsData.transactionCounts` for why the count is derived here.
      final responses = await Future.wait([
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.accounts.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.transactions.endpoint,
        ),
      ]);

      final accounts = [
        for (final json in unwrapList(responses[0])) Account.fromJson(json),
      ];
      final transactions = [
        for (final json in unwrapList(responses[1]))
          TransactionModel.fromJson(json),
      ];

      return Right(
        AccountsData(
          accounts: accounts,
          transactionCounts: countByAccount(transactions),
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

  /// Transactions per account id. Rows with no `account_id` are skipped rather
  /// than bucketed under a null key, which nothing would read.
  ///
  /// Static and pure so it is directly testable, matching the convention in
  /// `BudgetsRepo`.
  static Map<int, int> countByAccount(List<TransactionModel> transactions) {
    final Map<int, int> counts = <int, int>{};
    for (final t in transactions) {
      final int? id = t.accountId ?? t.account?.id;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
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
