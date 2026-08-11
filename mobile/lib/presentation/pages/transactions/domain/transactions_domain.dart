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
/// There is deliberately no `deleteTransaction`. The design shows no delete
/// affordance on either the list or the form, so the app exposes none, even
/// though `TransactionController::destroy` is the one write endpoint that
/// actually works.
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
}
