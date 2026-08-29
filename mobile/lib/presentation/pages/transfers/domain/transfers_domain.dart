import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/transfer_data.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the transfer feature needs, independent of where the data lives.
///
/// There is deliberately no `updateTransfer`. Editing one leg would leave the
/// other on its old amount and one account's balance wrong, so the server
/// refuses it outright (422) — the correct edit is delete plus re-create.
abstract class TransfersDomain {
  /// Loads the accounts and categories the form's pickers need.
  Future<Either<Failure, TransferFormData>> getFormData();

  /// Loads past transfers, newest first, already grouped back into single
  /// objects rather than two transaction rows each.
  Future<Either<Failure, List<TransferModel>>> getTransfers();

  /// Moves money between two accounts, adjusting both balances.
  Future<Either<Failure, TransferModel>> createTransfer(TransferDraft draft);

  /// Reverses a transfer, deleting both legs and restoring both balances.
  /// Takes the group id, not a transaction id.
  Future<Either<Failure, bool>> deleteTransfer(String groupId);
}
