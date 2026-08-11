import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/dashboard/domain/dashboard_domain.dart';

/// The dashboard's data source.
///
/// ---------------------------------------------------------------------------
/// MOCK-ONLY FOR NOW. [useMock] is `true` and this class makes **no network
/// calls at all** — `DioClient` is deliberately not even imported.
///
/// Why: `GlobalApiEndpoint.base` is still the placeholder
/// `https://domain/api/v1`, and the Laravel backend lives on the unmerged
/// branch `origin/souad-backend`, where `routes/api.php` applies no middleware
/// and does not implement the login/register routes this app calls.
///
/// To go live later:
///   1. Set a real `GlobalApiEndpoint.base`.
///   2. Add the resource endpoints to `GlobalApiEndpoint` (intentionally not
///      added yet, so no unused/invented contract sits in the codebase).
///   3. Implement [_getRemote] following the exact try/catch shape used by
///      `NotificationsRepo` / `AuthRepo`.
///   4. Flip [useMock] to `false` and delete `lib/data/mock/`.
///
/// TODO(backend): no `/dashboard/summary` endpoint is assumed or referenced
/// anywhere. Whether the totals stay client-side (as [DashboardSummary.from]
/// does) or move server-side is a decision for when the backend contract is
/// confirmed.
///
/// TODO(backend): account balances do not move when a transaction is written.
/// `accounts.balance` keeps its seeded value for the whole session, so adding
/// an expense changes "المصاريف", "المتبقي" and the category breakdown but
/// leaves "الرصيد الإجمالي" untouched. This is deliberate: the backend defines
/// no balance mutation or recalculation contract for transaction writes —
/// `TransactionController::store` never touches the `accounts` table, and there
/// is no trigger, observer or recompute endpoint anywhere on
/// `origin/souad-backend`. Inventing the arithmetic here would be fabricating
/// accounting behaviour the server does not have, and would silently disagree
/// with it the moment the real API is wired up. Decide server-side first: either
/// `store()`/`update()`/`destroy()` adjust `accounts.balance` transactionally,
/// or balance becomes a derived sum rather than a stored column.
/// ---------------------------------------------------------------------------
class DashboardRepo extends DashboardDomain {
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

  /// TODO(backend): unimplemented on purpose.
  ///
  /// Filling this in requires endpoints that either do not exist yet or are not
  /// safe to call (see the class doc). Returning a `ServerFailure` is the honest
  /// behaviour — it must never silently return empty data that the UI would
  /// render as a real, zeroed-out dashboard.
  Future<Either<Failure, DashboardData>> _getRemote() async {
    return Left(ServerFailure());
  }
}
