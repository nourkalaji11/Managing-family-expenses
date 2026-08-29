import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/categories_data.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/categories/domain/categories_domain.dart';

/// The categories feature's data source.
///
/// Live against the Laravel API only — no mock path, for the same reason as
/// `AccountsRepo`.
///
/// Endpoint notes worth carrying at the call site:
///
///   * `categories` has **no owner**. The table is `(id, name, timestamps)` with
///     no `user_id`, so the list is global: every family shares one set, and a
///     rename by one is a rename for all. That is the schema's design, not an
///     oversight this repository should paper over.
///   * `POST` and `PUT` enforce `unique:categories,name`, so a duplicate name
///     comes back as a **422** whose message is already Arabic. [unwrapObject]
///     surfaces it verbatim.
///   * `DELETE /categories/{id}` answers **409** when the category is still
///     referenced by a transaction or a budget, instead of cascading.
class CategoriesRepo extends CategoriesDomain {
  static DioClient client = DioClient();

  @override
  Future<Either<Failure, CategoriesData>> getCategories() async {
    try {
      // Three concurrent reads. Transactions supply the "12 معاملة" tile
      // subtitle; budgets supply nothing visible, only the delete guard — see
      // `CategoriesData.budgetCounts`.
      final responses = await Future.wait([
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.categories.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.transactions.endpoint,
        ),
        client.request(
          requestType: RequestType.get,
          path: GlobalApiEndpoint.budgets.endpoint,
        ),
      ]);

      final categories = [
        for (final json in unwrapList(responses[0])) Category.fromJson(json),
      ];
      final transactions = [
        for (final json in unwrapList(responses[1]))
          TransactionModel.fromJson(json),
      ];
      final budgets = [
        for (final json in unwrapList(responses[2])) BudgetModel.fromJson(json),
      ];

      return Right(
        CategoriesData(
          categories: categories,
          transactionCounts: countTransactions(transactions),
          budgetCounts: countBudgets(budgets),
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
  Future<Either<Failure, Category>> createCategory(CategoryDraft draft) async {
    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.categories.endpoint,
        body: draft.toRequestJson(),
      );

      return Right(Category.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(
    int id,
    CategoryDraft draft,
  ) async {
    try {
      final response = await client.request(
        requestType: RequestType.put,
        path: GlobalApiEndpoint.categoryById[[id]],
        body: draft.toRequestJson(),
      );

      return Right(Category.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCategory(int id) async {
    try {
      final response = await client.request(
        requestType: RequestType.delete,
        path: GlobalApiEndpoint.categoryById[[id]],
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

  /// Transactions per category id. Rows with no `category_id` are skipped.
  ///
  /// Transfer legs are skipped too: their category is filler the form was
  /// forced to pick because `transactions.category_id` is NOT NULL, so counting
  /// them would inflate an unrelated category's tile. The **account** counts in
  /// `AccountsRepo` deliberately do include them — a transfer really does touch
  /// both accounts.
  static Map<int, int> countTransactions(List<TransactionModel> transactions) {
    final Map<int, int> counts = <int, int>{};
    for (final t in transactions) {
      if (t.isTransfer) continue;
      final int? id = t.categoryId ?? t.category?.id;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  /// Budgets per category id. Rows with no `category_id` are skipped.
  static Map<int, int> countBudgets(List<BudgetModel> budgets) {
    final Map<int, int> counts = <int, int>{};
    for (final b in budgets) {
      final int? id = b.categoryId ?? b.category?.id;
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
