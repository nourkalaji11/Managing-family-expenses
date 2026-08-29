import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/categories_data.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/categories/domain/categories_domain.dart';

/// The categories feature's data source.
///
/// Reads `MockStore` when `kUseMockData` is on, the Laravel API when it is
/// off, on the same terms as `AccountsRepo` — including the 409 delete guard
/// and the unique-name rule, both of which the mock enforces locally.
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

  static const bool useMock = kUseMockData;

  static const Duration mockDelay = Duration(milliseconds: 500);
  static const Duration mockWriteDelay = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, CategoriesData>> getCategories() async {
    if (useMock) return _mockGet();

    try {
      // One request. This used to be three: `/transactions` for the "12 معاملة"
      // tile subtitle and `/budgets` for the delete guard, both downloaded
      // whole so they could be counted here. `CategoryController::index` now
      // returns both counts from a `withCount`, and excludes transfer legs from
      // the transaction one server-side.
      final response = await client.request(
        requestType: RequestType.get,
        path: GlobalApiEndpoint.categories.endpoint,
      );

      final categories = [
        for (final json in unwrapList(response)) Category.fromJson(json),
      ];

      return Right(
        CategoriesData(
          categories: categories,
          transactionCounts: {
            for (final c in categories)
              if (c.id != null && c.transactionsCount != null)
                c.id!: c.transactionsCount!,
          },
          budgetCounts: {
            for (final c in categories)
              if (c.id != null && c.budgetsCount != null)
                c.id!: c.budgetsCount!,
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
  Future<Either<Failure, Category>> createCategory(CategoryDraft draft) async {
    if (useMock) return _mockCreate(draft);

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
    if (useMock) return _mockUpdate(id, draft);

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
    if (useMock) return _mockDelete(id);

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

  // ---------------------------------------------------------------------------
  // Mock path.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, CategoriesData>> _mockGet() async {
    await Future.delayed(mockDelay);

    final store = MockStore.instance;
    // Ordered by name ascending, matching `CategoryController::index`. Doing it
    // here rather than in the store keeps ordering a repository concern, the
    // same arrangement `TransactionsRepo` uses for newest-first.
    final categories = [...store.categories]
      ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

    return Right(
      CategoriesData(
        categories: categories,
        transactionCounts: {
          for (final c in categories)
            if (c.id != null) c.id!: store.countTransactionsForCategory(c.id),
        },
        budgetCounts: {
          for (final c in categories)
            if (c.id != null) c.id!: store.countBudgetsForCategory(c.id),
        },
      ),
    );
  }

  Future<Either<Failure, Category>> _mockCreate(CategoryDraft draft) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    if (store.categoryNameTaken(draft.name)) {
      return Left(ResultFailure('categories.error_name_taken'.tr()));
    }

    final category = Category(id: store.allocateCategoryId(), name: draft.name);
    store.addCategory(category);
    return Right(category);
  }

  Future<Either<Failure, Category>> _mockUpdate(
    int id,
    CategoryDraft draft,
  ) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    if (store.categoryById(id) == null) {
      return Left(ResultFailure('categories.error_not_found'.tr()));
    }
    // `exceptId` so that saving a category without renaming it is not a
    // conflict with itself — the server's unique rule excludes the row under
    // edit for the same reason.
    if (store.categoryNameTaken(draft.name, exceptId: id)) {
      return Left(ResultFailure('categories.error_name_taken'.tr()));
    }

    final updated = Category(id: id, name: draft.name);
    if (!store.updateCategory(updated)) {
      return Left(ResultFailure('categories.error_not_found'.tr()));
    }
    return Right(updated);
  }

  Future<Either<Failure, bool>> _mockDelete(int id) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    if (store.categoryById(id) == null) {
      return Left(ResultFailure('categories.error_not_found'.tr()));
    }

    // The server's 409, enforced locally for the same reason as the account
    // guard: a category deleted out from under a transaction leaves the
    // dashboard's breakdown attributing money to nothing.
    final transactions = store.countTransactionsForCategory(id);
    final budgets = store.countBudgetsForCategory(id);
    if (transactions > 0 || budgets > 0) {
      return Left(
        ResultFailure(
          'categories.error_in_use'.tr(
            namedArgs: {
              'transactions': transactions.toString(),
              'budgets': budgets.toString(),
            },
          ),
        ),
      );
    }

    store.removeCategory(id);
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
