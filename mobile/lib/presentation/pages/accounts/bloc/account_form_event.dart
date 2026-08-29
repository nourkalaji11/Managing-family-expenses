part of 'account_form_bloc.dart';

sealed class AccountFormEvent extends Equatable {
  const AccountFormEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Seeds the form.
///
/// [account] null means Add; non-null means Edit and pre-fills both fields.
class OnAccountFormStarted extends AccountFormEvent {
  final Account? account;

  /// How many transactions the account being edited carries, handed down from
  /// the list's already-loaded counts. Used to warn before a delete the server
  /// would refuse, so the user is not sent to press a button that cannot work.
  final int transactionCount;

  const OnAccountFormStarted({
    required this.account,
    this.transactionCount = 0,
  });

  @override
  List<Object?> get props => <Object?>[account?.id, transactionCount];
}

class OnAccountNameChanged extends AccountFormEvent {
  final String name;

  const OnAccountNameChanged(this.name);

  @override
  List<Object?> get props => <Object?>[name];
}

/// The raw text of the balance field, exactly as typed.
class OnAccountBalanceChanged extends AccountFormEvent {
  final String balanceInput;

  const OnAccountBalanceChanged(this.balanceInput);

  @override
  List<Object?> get props => <Object?>[balanceInput];
}

/// Validates, then saves. Ignored while a save or delete is already in flight.
class OnSubmitAccountForm extends AccountFormEvent {
  const OnSubmitAccountForm();
}

/// Deletes the account being edited. Ignored in Add mode, and while a save or
/// delete is already in flight.
///
/// The screen confirms with the user before dispatching this.
class OnDeleteAccount extends AccountFormEvent {
  const OnDeleteAccount();
}
