import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/budgets_data.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the budgets feature needs, independent of where the data lives.
///
/// `BudgetsRepo` in `data/repos/` implements it, against the shared in-memory
/// `MockStore` or the API depending on `kUseMockData`. Swapping the source
/// never touches the blocs or the widgets.
abstract class BudgetsDomain {
  /// Loads the budgets plus the categories the form's picker needs.
  Future<Either<Failure, BudgetsData>> getBudgets();

  /// Creates a budget and returns it, with `id` and `createdAt` populated.
  Future<Either<Failure, BudgetModel>> createBudget(BudgetDraft draft);

  /// Updates the budget identified by [id], preserving its `id`, `createdAt`
  /// and `userId`, and returns the updated row.
  Future<Either<Failure, BudgetModel>> updateBudget(int id, BudgetDraft draft);

  /// Deletes the budget identified by [id].
  ///
  /// Unguarded, unlike the account and category deletes: a budget is a ceiling
  /// the family set for itself, not something transactions point at, so nothing
  /// is orphaned by removing one. `BudgetController::destroy` answers 404 — not
  /// 403 — when the budget belongs to another family, so that a member cannot
  /// learn which ids exist by probing.
  Future<Either<Failure, bool>> deleteBudget(int id);
}
