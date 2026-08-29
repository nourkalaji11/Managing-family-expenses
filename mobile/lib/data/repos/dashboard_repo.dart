import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/dashboard/domain/dashboard_domain.dart';

/// The dashboard's data source.
///
/// ---------------------------------------------------------------------------
/// Live against the Laravel API when [useMock] is `false`, which is the default.
/// The mock path is kept compiling as a one-line rollback ([kUseMockData]) and
/// as the seed the widget tests read.
///
/// There is deliberately **no** call to `GET /api/dashboard`. That endpoint
/// exists, but it answers with a role-dependent summary — for an admin
/// `{role, total_family_balance, total_family_spent, alerts}`, for a member
/// `{role, my_spending_limit, my_total_spent, my_remaining_limit}` — and none
/// of it is what this screen draws: no income figure, no per-category
/// breakdown, no account to fill "رقم الحساب العائلي", and no transaction rows
/// for "آخر المعاملات". Every one of those comes from `/accounts` and
/// `/transactions`, which this repository has to fetch anyway, so calling
/// `/dashboard` on top would be a third round trip that contributes nothing.
///
/// TODO(backend): aggregating on-device means downloading every transaction the
/// caller can see — `TransactionController::index` has no `paginate()`. A
/// server-side summary shaped like [DashboardSummary] should replace
/// [_aggregate] once the backend offers one.
/// ---------------------------------------------------------------------------
class DashboardRepo extends DashboardDomain {
  static DioClient client = DioClient();

  /// The single switch between fake and real data, shared with every other
  /// repository so the app can never be half-mocked.
  static const bool useMock = kUseMockData;

  /// How many rows "آخر المعاملات" shows. The design shows three.
  static const int recentTransactionsLimit = 3;

  /// Simulated latency, so loading and error states are actually exercised
  /// during development instead of the screen snapping straight to `Loaded`.
  static const Duration mockDelay = Duration(milliseconds: 600);

  @override
  Future<Either<Failure, DashboardData>> getDashboard() async {
    if (useMock) return _getMock();
    return _getRemote();
  }

  Future<Either<Failure, DashboardData>> _getMock() async {
    try {
      await Future.delayed(mockDelay);

      // Reads the shared session store, NOT `DashboardMockSource` directly.
      // The seed is consumed once, by `MockStore`; calling the seed again here
      // would make every transaction added or edited during the session vanish
      // from the dashboard the next time it loaded.
      final store = MockStore.instance;
      final List<Account> accounts = store.accounts;
      final List<TransactionModel> transactions = store.transactions;

      return Right(_aggregate(accounts, transactions));
    } catch (e) {
      // Defensive only: the mock cannot realistically throw, but returning a
      // Left keeps the Either contract honest rather than letting an exception
      // escape into the bloc.
      return Left(GlobalFailure());
    }
  }

  /// Builds [DashboardData] from raw rows.
  ///
  /// Shared by both paths on purpose: when [useMock] flips, the aggregation and
  /// the sort/limit behaviour stay byte-for-byte identical, so the UI cannot
  /// change shape just because the source changed.
  DashboardData _aggregate(
    List<Account> accounts,
    List<TransactionModel> transactions,
  ) {
    final summary = DashboardSummary.from(
      accounts: accounts,
      transactions: transactions,
    );

    // Newest first. Rows without any timestamp sort last rather than throwing.
    final sorted = [...transactions]
      ..sort((a, b) {
        final da = a.displayedAt;
        final db = b.displayedAt;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    return DashboardData(
      summary: summary,
      recentTransactions: sorted.take(recentTransactionsLimit).toList(),
    );
  }

  /// Fetches the two collections the dashboard aggregates from.
  ///
  /// Issued concurrently: neither depends on the other, and the screen cannot
  /// render until both have landed, so serialising them would double the time
  /// to first paint for no benefit. If either fails, `Future.wait` propagates
  /// the first [Failure] thrown by [unwrapList] and the whole load fails —
  /// which is the honest outcome. A dashboard built from accounts alone would
  /// show a real balance next to a fabricated "0 ر.س" of expenses.
  Future<Either<Failure, DashboardData>> _getRemote() async {
    try {
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

      // The same aggregation the mock path runs, so the screen cannot change
      // shape just because the source changed.
      return Right(_aggregate(accounts, transactions));
    } on DioException catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout ||
          ex.type == DioExceptionType.sendTimeout ||
          ex.type == DioExceptionType.receiveTimeout ||
          ex.type == DioExceptionType.unknown) {
        return Left(ConnectionFailure());
      } else {
        return Left(GlobalFailure());
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }
}
