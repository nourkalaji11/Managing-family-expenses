import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
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

  @override
  Future<Either<Failure, TransferFormData>> getFormData() async {
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
            for (final json in unwrapList(responses[1])) Category.fromJson(json),
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
