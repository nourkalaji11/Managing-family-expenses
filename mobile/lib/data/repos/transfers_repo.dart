import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/transfer_data.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/transfers/domain/transfers_domain.dart';

/// The transfer feature's data source.
///
/// Endpoint notes worth carrying at the call site:
///
///   * `POST /transfers` writes **two** transaction rows in one
///     `DB::transaction` and moves both account balances. It does not go
///     through `POST /transactions`, so the child spending limit is not applied
///     — deliberately: moving money between the family's own accounts is not
///     spending, and capping it would stop a member tidying their own balances.
///   * `DELETE` takes the **group id**. Deleting a single leg through
///     `DELETE /transactions/{id}` would orphan the other and leave one balance
///     wrong; the server also refuses `PUT` on a leg for the same reason.
class TransfersRepo extends TransfersDomain {
  static DioClient client = DioClient();

  static const bool useMock = kUseMockData;

  static const Duration mockDelay = Duration(milliseconds: 500);
  static const Duration mockWriteDelay = Duration(milliseconds: 400);

  @override
  Future<Either<Failure, TransferFormData>> getFormData() async {
    if (useMock) return _mockFormData();

    try {
      // The form cannot open without both: a transfer needs two accounts, and
      // a category because `transactions.category_id` is NOT NULL.
      final responses = await Future.wait([
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.accounts.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.categories.endpoint,
        ),
      ]);

      return Right(
        TransferFormData(
          accounts: [
            for (final json in unwrapList(responses[0])) Account.fromJson(json),
          ],
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

  @override
  Future<Either<Failure, List<TransferModel>>> getTransfers() async {
    if (useMock) return _mockGetTransfers();

    try {
      final response = await client.request(
        requestType: RequestType.get,
        path: GlobalApiEndpoint.transfers.endpoint,
      );

      return Right([
        for (final json in unwrapList(response)) TransferModel.fromJson(json),
      ]);
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, TransferModel>> createTransfer(
    TransferDraft draft,
  ) async {
    if (useMock) return _mockCreate(draft);

    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.transfers.endpoint,
        body: draft.toRequestJson(),
      );

      // `store` answers with `{transfer_group_id, amount, from, to}` where
      // `from`/`to` are the two transaction rows, not accounts — so the
      // response is reshaped here into the same object `index` returns, and the
      // caller never has to care which endpoint it came from.
      final Map<String, dynamic> data = unwrapObject(response);
      final Map<String, dynamic>? from = data['from'] is Map<String, dynamic>
          ? data['from'] as Map<String, dynamic>
          : null;
      final Map<String, dynamic>? to = data['to'] is Map<String, dynamic>
          ? data['to'] as Map<String, dynamic>
          : null;

      return Right(
        TransferModel.fromJson({
          'transfer_group_id': data['transfer_group_id'],
          'amount': data['amount'],
          'description': from?['description'],
          'date': from?['date'],
          'from_account': from?['account'],
          'to_account': to?['account'],
          'created_at': from?['created_at'],
        }),
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
  Future<Either<Failure, bool>> deleteTransfer(String groupId) async {
    if (useMock) return _mockDelete(groupId);

    try {
      final response = await client.request(
        requestType: RequestType.delete,
        path: GlobalApiEndpoint.transferByGroup[[groupId]],
      );

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
  // Mock path.
  //
  // A transfer is stored the way the server stores it: two transaction rows
  // sharing a group id, not an entry in a separate transfers collection. That
  // is what makes a transfer made here move both account balances, appear in
  // transaction history, and stay out of the dashboard's income/expense totals
  // — all of which fall out of the existing code rather than being reproduced.
  // A parallel transfers list would have had to keep agreeing with all of it.
  //
  // The child spending limit is deliberately NOT applied, matching
  // `TransferController`: moving money between the family's own accounts is not
  // spending, and capping it would block a member from tidying their own
  // accounts.
  // ---------------------------------------------------------------------------

  /// Ids handed out by the mock. Not a UUID — the server generates one and this
  /// is deliberately not shaped like it, so a mock group id can never be
  /// mistaken for a real one in a log or a bug report.
  static int _groupSequence = 0;

  Future<Either<Failure, TransferFormData>> _mockFormData() async {
    await Future.delayed(mockDelay);

    final store = MockStore.instance;
    return Right(
      TransferFormData(accounts: store.accounts, categories: store.categories),
    );
  }

  Future<Either<Failure, List<TransferModel>>> _mockGetTransfers() async {
    await Future.delayed(mockDelay);

    final store = MockStore.instance;
    final List<TransferModel> transfers = [];

    for (final legs in store.groupedTransfers()) {
      // A group with one leg cannot happen: both are written together and
      // removed together. Skipped rather than rendered half-built, because a
      // transfer missing its destination is worse than one not shown.
      if (legs.length < 2) continue;

      final out = legs.first;
      final into = legs[1];

      transfers.add(
        TransferModel(
          groupId: out.transferGroupId,
          amount: out.amount,
          description: out.description,
          date: out.date,
          fromAccount: store.accountById(out.accountId),
          toAccount: store.accountById(into.accountId),
          createdAt: out.createdAt,
        ),
      );
    }

    return Right(transfers);
  }

  Future<Either<Failure, TransferModel>> _mockCreate(
    TransferDraft draft,
  ) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;

    final userId = store.currentUserId;
    if (userId == null) return Left(ResultFailure('unauthenticated'.tr()));

    final from = store.accountById(draft.fromAccountId);
    final to = store.accountById(draft.toAccountId);
    final category = store.categoryById(draft.categoryId);
    if (from == null || to == null || category == null) {
      return Left(ResultFailure('transfers.error_invalid_selection'.tr()));
    }

    final groupId = 'mock-transfer-${++_groupSequence}';
    final now = DateTime.now();

    // The outgoing leg is written first and read back first — `_mockGetTransfers`
    // labels "من" and "إلى" by that order.
    final out = TransactionModel(
      id: store.allocateId(),
      amount: draft.amount,
      type: TransactionType.expense,
      description: draft.description,
      date: draft.date,
      createdAt: now,
      userId: userId,
      accountId: from.id,
      categoryId: category.id,
      account: from,
      category: category,
      isTransfer: true,
      transferGroupId: groupId,
    );

    final into = TransactionModel(
      id: store.allocateId(),
      amount: draft.amount,
      type: TransactionType.income,
      description: draft.description,
      date: draft.date,
      createdAt: now,
      userId: userId,
      accountId: to.id,
      categoryId: category.id,
      account: to,
      category: category,
      isTransfer: true,
      transferGroupId: groupId,
    );

    store.add(out);
    store.add(into);

    // Both balances move, or neither should have. There is no transaction
    // boundary to roll back to here, so the balances are written after both
    // legs are in — nothing above this line can fail.
    //
    // Written from the legs' own effects rather than from `draft.amount`, so a
    // transfer moves the balances by exactly what it recorded — the same rule
    // the undo below relies on.
    store.adjustAccountBalance(from.id, MockStore.balanceEffectOf(out));
    store.adjustAccountBalance(to.id, MockStore.balanceEffectOf(into));

    return Right(
      TransferModel(
        groupId: groupId,
        amount: draft.amount,
        description: draft.description,
        date: draft.date,
        // Re-read, so the returned object carries the balances as they now
        // stand rather than as they were before the move.
        fromAccount: store.accountById(from.id),
        toAccount: store.accountById(to.id),
        createdAt: now,
      ),
    );
  }

  Future<Either<Failure, bool>> _mockDelete(String groupId) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    final legs = store.transferLegs(groupId);
    if (legs.isEmpty) {
      return Left(ResultFailure('transfers.error_not_found'.tr()));
    }

    // Reversed leg by leg rather than by re-deriving "the amount": the two legs
    // are the record of what actually happened to each balance, and undoing
    // exactly what was done is what keeps the account totals equal to the sum
    // of their transactions.
    for (final leg in legs) {
      store.adjustAccountBalance(
        leg.accountId,
        -MockStore.balanceEffectOf(leg),
      );
    }

    store.removeTransferGroup(groupId);
    return const Right(true);
  }

  /// Transport-level errors, mapped exactly as the other repositories map them.
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
