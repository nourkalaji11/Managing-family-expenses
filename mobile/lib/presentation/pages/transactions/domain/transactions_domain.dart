import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/transactions_data.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the transactions feature needs, independent of where the data lives.
///
/// `TransactionsRepo` in `data/repos/` implements it: today against the shared
/// in-memory `MockStore`, later against the API. Swapping the source never
/// touches the blocs or the widgets.
///
/// [deleteTransaction] was absent for a long while, on the grounds that the
/// design draws no delete affordance. That reasoning no longer holds: the
/// account, category and budget forms all grew one, `DELETE /transactions/{id}`
/// is a working routed endpoint, and a ledger a family can only add to is not a
/// ledger they can correct. It lives on the edit form, beside Save, exactly
/// where the other three put theirs.
abstract class TransactionsDomain {
  /// Loads the rows plus the accounts and categories the form's pickers need.
  Future<Either<Failure, TransactionsData>> getTransactions();

  /// Creates a row and returns it, with `id` and `createdAt` populated.
  Future<Either<Failure, TransactionModel>> createTransaction(
    TransactionDraft draft,
  );

  /// Updates the row identified by [id], preserving its `id`, `createdAt` and
  /// `userId`, and returns the updated row.
  Future<Either<Failure, TransactionModel>> updateTransaction(
    int id,
    TransactionDraft draft,
  );

  /// Deletes the row identified by [id] and reverses its effect on the
  /// account's balance.
  ///
  /// Fails with a [ResultFailure] carrying the server's message when the row is
  /// one leg of a transfer: deleting a leg on its own would orphan the other
  /// and leave a balance wrong, so the server answers 422 and points at
  /// `DELETE /transfers/{group}` instead.
  Future<Either<Failure, bool>> deleteTransaction(int id);
}
