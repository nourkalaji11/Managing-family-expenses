import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/transactions_data.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/data/repos/budgets_repo.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/transactions/domain/transactions_domain.dart';

/// The transactions feature's data source.
///
/// Mock or live, on [useMock] — see [kUseMockData], which defaults to the mock
/// so the app runs with no backend. Both paths are maintained; neither is a
/// leftover.
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
      final viewer = store.signedInUser;
      final bool isParent = viewer?.isParent ?? false;

      // Scoped exactly as `TransactionController::index` scopes it: a parent
      // sees the family's rows, a member sees only their own. The screen builds
      // its person filter from what it is given, so getting this wrong here
      // would put siblings' names in a child's filter.
      final rows = isParent
          ? store.transactions
          : [
              for (final t in store.transactions)
                if (t.userId == viewer?.id) t,
            ];

      return Right(
        TransactionsData(
          transactions: sortedNewestFirst([
            // The owner is attached on the way out rather than stored on the
            // row: a rename would otherwise leave every past transaction
            // labelled with the old name.
            for (final t in rows) t.copyWith(user: store.userById(t.userId)),
          ]),
          accounts: store.accounts,
          categories: store.categories,
          // Same rule as the server: a member is given only themselves.
          members: isParent
              ? store.users
              : (viewer == null ? const <User>[] : <User>[viewer]),
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

      // `MockStore.currentUserId` is derived from the seeded family and is
      // nullable on purpose. Failing loudly beats writing a row with an
      // invented owner.
      final viewer = store.signedInUser;
      final userId = viewer?.id ?? store.currentUserId;
      if (userId == null) {
        return Left(ResultFailure('transactions.error_no_user'.tr()));
      }

      final account = store.accountById(draft.accountId);
      final category = store.categoryById(draft.categoryId);
      if (account == null || category == null) {
        // The real backend enforces this with `exists:accounts,id` /
        // `exists:categories,id`; the mock enforces the same rule locally.
        return Left(ResultFailure('transactions.error_invalid_selection'.tr()));
      }

      // The spending ceiling, enforced where `TransactionController::store`
      // enforces it: a member, an expense, and the whole history summed rather
      // than this month's. Without this, the ceiling card a member's dashboard
      // draws would be a number that never stops anything.
      final block = _ceilingBlock(store, viewer, draft.type, draft.amount);
      if (block != null) return Left(block);

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
      // The balance moves with the row. The server does this inside the same
      // `DB::transaction`; skipping it here left the dashboard's total balance
      // frozen while its income and expense figures moved, so three numbers on
      // one screen disagreed with each other.
      store.adjustAccountBalance(
        account.id,
        MockStore.balanceEffectOf(transaction),
      );

      _notifyAfterWrite(store, viewer, transaction);
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

      // The ceiling is re-checked on edit, as it is server-side: without it a
      // member could book a small expense and then edit it upwards to any
      // amount, and the check on create would be decoration.
      final block = _ceilingBlock(
        store,
        store.signedInUser,
        draft.type,
        draft.amount,
        // The row's own current amount is already inside the total, so it is
        // discounted — otherwise saving an expense without changing it could
        // fail against its own contribution.
        excluding: existing,
      );
      if (block != null) return Left(block);

      // Replaces in place, keyed by id, so an edit can never append a duplicate.
      if (!store.update(updated)) {
        return Left(ResultFailure('transactions.error_not_found'.tr()));
      }

      // Old effect undone before the new one is applied, and on whichever
      // account each belonged to — an edit that moves a row between accounts
      // has to take its money with it.
      store.adjustAccountBalance(
        existing.accountId,
        -MockStore.balanceEffectOf(existing),
      );
      store.adjustAccountBalance(
        updated.accountId,
        MockStore.balanceEffectOf(updated),
      );

      return Right(updated);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  Future<Either<Failure, bool>> _mockDelete(int id) async {
    try {
      await Future.delayed(mockWriteDelay);

      final store = MockStore.instance;

      // Read before the removal: undoing the balance needs the row's amount,
      // type and account.
      TransactionModel? existing;
      for (final t in store.transactions) {
        if (t.id == id) {
          existing = t;
          break;
        }
      }
      if (existing == null || !store.remove(id)) {
        return Left(ResultFailure('transactions.error_not_found'.tr()));
      }

      store.adjustAccountBalance(
        existing.accountId,
        -MockStore.balanceEffectOf(existing),
      );
      return const Right(true);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  /// The [Failure] to answer with when [amount] would put [viewer] over their
  /// ceiling, or null when the write may proceed.
  ///
  /// Mirrors `TransactionController::store`: parents are unrestricted, income is
  /// unrestricted, transfers are excluded from the total, and the comparison is
  /// `spent + amount > limit` against the whole history. [excluding] discounts a
  /// row that is being replaced, so an edit is measured against the others.
  ///
  /// Fires `limit_blocked` on the way out, as `NotificationService` does — a
  /// refusal the family never hears about is one the parent cannot act on.
  static Failure? _ceilingBlock(
    MockStore store,
    User? viewer,
    TransactionType type,
    num amount, {
    TransactionModel? excluding,
  }) {
    if (viewer == null || viewer.isParent) return null;
    if (type != TransactionType.expense) return null;

    // Null means no ceiling has been set, NOT a ceiling of zero. The server
    // draws the same distinction: conflating them refused every expense a
    // child made before their parent had decided on an allowance.
    final limit = viewer.spendingLimit;
    if (limit == null) return null;

    var spent = store.spentAgainstLimitBy(viewer.id);
    if (excluding != null && excluding.isExpense && !excluding.isTransfer) {
      spent -= excluding.amount ?? 0;
    }

    if (spent + amount <= limit) return null;

    final remaining = limit - spent;
    store.addNotification(
      AppNotification(
        id: store.allocateNotificationId(),
        // The person refused. `NotificationService::limitBlocked` also tells
        // the parents; that copy is added below.
        userId: viewer.id,
        rawType: NotificationType.limitBlocked.wire,
        title: 'محاولة تجاوز سقف السحب',
        message:
            'مبلغ ${amount.toStringAsFixed(2)} يتجاوز سقف سحبك. '
            'المتبقي لك ${(remaining < 0 ? 0 : remaining).toStringAsFixed(2)} '
            'من أصل ${limit.toStringAsFixed(2)}.',
        createdAt: DateTime.now(),
      ),
    );

    for (final parent in store.users) {
      if (!parent.isParent) continue;
      store.addNotification(
        AppNotification(
          id: store.allocateNotificationId(),
          userId: parent.id,
          rawType: NotificationType.limitBlocked.wire,
          title: 'محاولة تجاوز سقف السحب',
          message:
              'حاول ${viewer.name ?? ''} صرف ${amount.toStringAsFixed(2)} '
              'وهو ما يتجاوز سقفه.',
          createdAt: DateTime.now(),
        ),
      );
    }

    return ResultFailure('transactions.error_limit_exceeded'.tr());
  }

  /// The notifications a successful write produces on the server.
  ///
  /// Two of `NotificationService`'s four types are generated here:
  ///
  ///   * `member_spent` — a member's expense, so the parent sees the spending
  ///     as it happens.
  ///   * `budget_exceeded` — fired only on **crossing** the limit, not on every
  ///     write once over it, which is why the before-figure is recomputed by
  ///     subtracting this row rather than read after the fact.
  ///
  /// The third, `limit_blocked`, belongs to the refusal path in [_ceilingBlock];
  /// the fourth, `limit_updated`, to `ProfileRepo`.
  static void _notifyAfterWrite(
    MockStore store,
    User? viewer,
    TransactionModel written,
  ) {
    if (!written.isExpense || written.isTransfer) return;

    _warnIfNearingCeiling(store, viewer, written);

    if (viewer != null && !viewer.isParent) {
      // Parents only. Telling someone what they themselves just did is noise.
      for (final parent in store.users) {
        if (!parent.isParent) continue;
        store.addNotification(
          AppNotification(
            id: store.allocateNotificationId(),
            userId: parent.id,
            rawType: NotificationType.memberSpent.wire,
            title: 'عملية صرف جديدة',
            message:
                'صرف ${viewer.name ?? ''} '
                '${(written.amount ?? 0).toStringAsFixed(2)} '
                'على ${written.category?.name ?? ''}.',
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    final all = store.transactions;
    for (final budget in store.budgets) {
      if (budget.categoryId != written.categoryId) continue;

      // `limitAmount` is nullable; `limit` is the same value defaulted to 0.
      final limit = budget.limitAmount;
      if (limit == null || limit <= 0) continue;

      final after = BudgetsRepo.spentFor(budget, all);
      // This row's own contribution removed, giving the figure as it stood
      // immediately before the write. If it was already over, the family has
      // been told once and does not need telling again.
      final before = after - (written.amount ?? 0);
      if (before > limit || after <= limit) continue;

      // A budget belongs to the family, so everyone is told.
      for (final member in store.users) {
        store.addNotification(
          AppNotification(
            id: store.allocateNotificationId(),
            userId: member.id,
            rawType: NotificationType.budgetExceeded.wire,
            title: 'تجاوزت الميزانية',
            message:
                'تجاوز الصرف على ${written.category?.name ?? ''} '
                'ميزانية ${limit.toStringAsFixed(2)}.',
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }

  /// The share of a ceiling at which the family is warned.
  ///
  /// Matches `NotificationService::APPROACHING_RATIO`. 0.8 rather than 0.9: a
  /// warning that arrives with a tenth of the allowance left arrives too late
  /// for a parent to decide anything before the child is refused.
  static const double approachingRatio = 0.8;

  /// The "running out of allowance" warning — the one that arrives BEFORE a
  /// refusal, which is the point of it.
  ///
  /// Both people are told, as on the server: the child so a refusal does not
  /// come as a surprise, the parent so they can raise the ceiling or ask what
  /// the money is going on while there is still time to do either.
  ///
  /// Fires on **crossing** the threshold only. Warning on every expense after
  /// 80% turns the list into noise, and the one warning that mattered is lost
  /// in it.
  static void _warnIfNearingCeiling(
    MockStore store,
    User? viewer,
    TransactionModel written,
  ) {
    if (viewer == null || viewer.isParent) return;

    final limit = viewer.spendingLimit;
    if (limit == null || limit <= 0) return;

    final after = store.spentAgainstLimitBy(viewer.id);
    // The row has already been written, so its own amount is removed to
    // recover the figure as it stood immediately before.
    final before = after - (written.amount ?? 0);

    final threshold = limit * approachingRatio;
    if (before >= threshold || after < threshold) return;

    final left = limit - after;
    final remaining = left < 0 ? 0 : left;
    final percent = ((after / limit) * 100).round();
    final remainingText = remaining.toStringAsFixed(2);
    final limitText = limit.toStringAsFixed(2);

    store.addNotification(
      AppNotification(
        id: store.allocateNotificationId(),
        userId: viewer.id,
        rawType: NotificationType.limitApproaching.wire,
        title: 'اقتربت من نهاية مصروفك',
        message:
            'صرفت $percent% من مصروفك. '
            'المتبقي لك $remainingText من أصل $limitText.',
        createdAt: DateTime.now(),
      ),
    );

    // The parent's copy. Named, because a warning that does not say whose
    // allowance is running out cannot be acted on.
    for (final parent in store.users) {
      if (!parent.isParent) continue;
      store.addNotification(
        AppNotification(
          id: store.allocateNotificationId(),
          userId: parent.id,
          rawType: NotificationType.limitApproaching.wire,
          title: 'اقترب مصروف الابن من نهايته',
          message:
              'صرف ${viewer.name ?? ''} $percent% من مصروفه. '
              'المتبقي له $remainingText من أصل $limitText.',
          createdAt: DateTime.now(),
        ),
      );
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
        // The family, for the "whose spending" filter. Scoped server-side: a
        // member gets back only themselves, so the filter offers them nothing
        // rather than the app having to decide what to hide.
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.users.endpoint,
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
            for (final json in unwrapList(responses[2]))
              Category.fromJson(json),
          ],
          members: [
            for (final json in unwrapList(responses[3])) User.fromJson(json),
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
