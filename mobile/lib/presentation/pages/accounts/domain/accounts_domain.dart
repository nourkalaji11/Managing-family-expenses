import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/accounts_data.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the accounts feature needs, independent of where the data lives.
///
/// `AccountsRepo` in `data/repos/` implements it. Same arrangement as
/// `TransactionsDomain` and `BudgetsDomain`, so the blocs never see Dio.
///
/// Unlike those two, this contract **does** expose a delete: the add/edit design
/// draws a trash button next to "حفظ التغييرات", and `AccountController::destroy`
/// backs it.
abstract class AccountsDomain {
  /// Loads the accounts plus the per-account transaction counts the rows show
  /// as a subtitle.
  Future<Either<Failure, AccountsData>> getAccounts();

  /// Creates an account and returns it, with `id` populated.
  Future<Either<Failure, Account>> createAccount(AccountDraft draft);

  /// Updates the account identified by [id], preserving its `user_id`, and
  /// returns the updated row.
  Future<Either<Failure, Account>> updateAccount(int id, AccountDraft draft);

  /// Deletes the account identified by [id].
  ///
  /// Fails with a [ResultFailure] carrying the server's message when the
  /// account still holds transactions: `destroy` answers 409 rather than
  /// cascading the delete through to them.
  Future<Either<Failure, bool>> deleteAccount(int id);
}
