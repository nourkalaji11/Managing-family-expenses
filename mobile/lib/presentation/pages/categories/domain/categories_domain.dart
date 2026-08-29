import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/categories_data.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the categories feature needs, independent of where the data lives.
///
/// `CategoriesRepo` in `data/repos/` implements it, mirroring
/// [AccountsDomain] exactly — including the delete, which
/// `CategoryController::destroy` backs.
abstract class CategoriesDomain {
  /// Loads the categories plus the transaction and budget counts the tiles and
  /// the delete guard need.
  Future<Either<Failure, CategoriesData>> getCategories();

  /// Creates a category and returns it, with `id` populated.
  Future<Either<Failure, Category>> createCategory(CategoryDraft draft);

  /// Updates the category identified by [id] and returns the updated row.
  Future<Either<Failure, Category>> updateCategory(int id, CategoryDraft draft);

  /// Deletes the category identified by [id].
  ///
  /// Fails with a [ResultFailure] carrying the server's message when the
  /// category is still referenced by a transaction or a budget: `destroy`
  /// answers 409 rather than cascading the delete through to them.
  Future<Either<Failure, bool>> deleteCategory(int id);
}
