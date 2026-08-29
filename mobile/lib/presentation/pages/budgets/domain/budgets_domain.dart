import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/budgets_data.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the budgets feature needs, independent of where the data lives.
///
/// `BudgetsRepo` in `data/repos/` implements it: today against the shared
/// in-memory `MockStore`, later against the API. Swapping the source never
/// touches the blocs or the widgets.
///
/// There is deliberately no `deleteBudget`. The design shows no delete
/// affordance on either the list or the form, so the app exposes none — and
/// unlike transactions, the backend has no working `destroy` either.
abstract class BudgetsDomain {
  /// Loads the budgets plus the categories the form's picker needs.
  Future<Either<Failure, BudgetsData>> getBudgets();

  /// Creates a budget and returns it, with `id` and `createdAt` populated.
  Future<Either<Failure, BudgetModel>> createBudget(BudgetDraft draft);

  /// Updates the budget identified by [id], preserving its `id`, `createdAt`
  /// and `userId`, and returns the updated row.
  Future<Either<Failure, BudgetModel>> updateBudget(int id, BudgetDraft draft);
}
