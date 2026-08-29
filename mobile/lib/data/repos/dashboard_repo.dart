import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/dashboard/domain/dashboard_domain.dart';

/// The dashboard's data source.
///
/// ---------------------------------------------------------------------------
/// Mock or live, on [useMock] — see [kUseMockData], which now defaults to the
/// mock so that a build with no backend running is a working app rather than a
/// wall of connection errors.
///
/// The remote path makes **one** request, to `GET /dashboard`, and parses the
/// server's own summary. It used to fetch `/accounts` and `/transactions` whole
/// and aggregate them here, because the endpoint answered with something else
/// entirely — a role summary with no income figure, no breakdown and no rows.
/// `DashboardController` was rewritten to return what this screen draws, so
/// that download is gone and the totals now cover every row rather than the
/// ones the device happened to hold.
///
/// [_aggregate] survives for the mock path, which has no server to ask. Both
/// paths produce the same totals and the same four slices on the seeded data —
/// that equivalence is what the SQL version was checked against.
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
      final viewer = store.signedInUser;

      // Scoped by role, as `DashboardController` scopes it: a parent's figures
      // cover the family, a member's cover only their own rows. Without this a
      // child's home screen reported the household's income and spending as
      // though it were theirs — and the parent's whole reason for the app,
      // seeing what each child spends, would show the same numbers to both.
      //
      // `total_balance` stays family-wide on both sides, deliberately: the
      // accounts are shared and listed to everyone, so hiding their sum from a
      // child is theatre they could undo by adding the list up themselves.
      final List<TransactionModel> transactions =
          (viewer == null || viewer.isParent)
          ? store.transactions
          : [
              for (final t in store.transactions)
                if (t.userId == viewer.id) t,
            ];

      // A member's dashboard draws their ceiling where a parent's draws the
      // alerts panel, so the mock has to know which one is signed in. Without
      // this, signing in as a member offline would silently show the parent
      // layout and the ceiling card would never render.
      final num? limit = (viewer != null && !viewer.isParent)
          ? viewer.spendingLimit
          : null;

      return Right(
        _aggregate(
          accounts,
          transactions,
          spendingLimit: limit,
          spentOfLimit: limit == null
              ? null
              : store.spentAgainstLimitBy(viewer?.id),
          // Parents only, matching `GET /users`: a member is given nobody but
          // themselves, so the family card does not appear on their home.
          members: (viewer?.isParent ?? false)
              ? [
                  for (final m in store.users)
                    m.copyWith(
                      spent: store.spentAgainstLimitBy(m.id),
                      remaining: _remainingFor(store, m),
                    ),
                ]
              : const <User>[],
        ),
      );
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
  /// What is left of [member]'s allowance, or null when they have none.
  ///
  /// Same arithmetic as `ProfileRepo._withUsage`, and the same floor at zero
  /// that `DashboardController` applies: a member who has overshot has nothing
  /// left, not a negative allowance.
  static num? _remainingFor(MockStore store, User member) {
    final limit = member.spendingLimit;
    if (limit == null) return null;

    final left = limit - store.spentAgainstLimitBy(member.id);
    return left < 0 ? 0 : left;
  }

  DashboardData _aggregate(
    List<Account> accounts,
    List<TransactionModel> transactions, {
    num? spendingLimit,
    num? spentOfLimit,
    List<User> members = const <User>[],
  }) {
    final summary = DashboardSummary.from(
      accounts: accounts,
      transactions: transactions,
      spendingLimit: spendingLimit,
      spentOfLimit: spentOfLimit,
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
      members: members,
    );
  }

  /// Reads the server's summary.
  ///
  /// One request. This used to be two — `/accounts` and `/transactions` — whose
  /// rows were then summed on the device. `GET /dashboard` now computes the
  /// totals, the breakdown and the recent rows in SQL, which is both fewer
  /// round trips and a more honest figure: an on-device sum can only see the
  /// rows the client holds, and `/transactions` is now scoped by role and can
  /// be paginated.
  Future<Either<Failure, DashboardData>> _getRemote() async {
    try {
      // Two requests, not one: the dashboard payload has no member list, and
      // `GET /users` already computes `spent` and `remaining` per person.
      // Adding those to the dashboard response would be a second source for
      // the same numbers, and a second thing to keep in agreement.
      final responses = await Future.wait([
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.dashboard.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.users.endpoint,
        ),
      ]);

      final Map<String, dynamic> data = unwrapObject(responses[0]);

      return Right(
        DashboardData(
          summary: DashboardSummary.fromJson(data),
          recentTransactions: [
            for (final json
                in (data['recent_transactions'] as List? ?? const []))
              if (json is Map<String, dynamic>) TransactionModel.fromJson(json),
          ],
          // Scoped by the server: a member gets only themselves back, and
          // `DashboardData.children` then filters that to nothing.
          members: [
            for (final json in unwrapList(responses[1])) User.fromJson(json),
          ],
        ),
      );
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
