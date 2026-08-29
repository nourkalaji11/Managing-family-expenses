part of 'transaction_form_bloc.dart';

sealed class TransactionFormEvent extends Equatable {
  const TransactionFormEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Seeds the form.
///
/// [transaction] null means Add; non-null means Edit and pre-fills every
/// editable field. [accounts] and [categories] come from the list screen's
/// already-loaded state, so the form never blocks on its own request.
class OnFormStarted extends TransactionFormEvent {
  final TransactionModel? transaction;
  final List<Account> accounts;
  final List<Category> categories;

  const OnFormStarted({
    required this.transaction,
    required this.accounts,
    required this.categories,
  });

  @override
  List<Object?> get props => <Object?>[transaction?.id, accounts, categories];
}

class OnAmountDigitPressed extends TransactionFormEvent {
  /// A single character: "0".."9" or ".".
  final String digit;

  const OnAmountDigitPressed(this.digit);

  @override
  List<Object?> get props => <Object?>[digit];
}

class OnAmountBackspace extends TransactionFormEvent {
  const OnAmountBackspace();
}

class OnTypeChanged extends TransactionFormEvent {
  final TransactionType type;

  const OnTypeChanged(this.type);

  @override
  List<Object?> get props => <Object?>[type];
}

class OnAccountChanged extends TransactionFormEvent {
  final int accountId;

  const OnAccountChanged(this.accountId);

  @override
  List<Object?> get props => <Object?>[accountId];
}

class OnCategoryChanged extends TransactionFormEvent {
  final int categoryId;

  const OnCategoryChanged(this.categoryId);

  @override
  List<Object?> get props => <Object?>[categoryId];
}

class OnDateChanged extends TransactionFormEvent {
  final DateTime date;

  const OnDateChanged(this.date);

  @override
  List<Object?> get props => <Object?>[date];
}

class OnDescriptionChanged extends TransactionFormEvent {
  final String description;

  const OnDescriptionChanged(this.description);

  @override
  List<Object?> get props => <Object?>[description];
}

/// Validates, then saves. Ignored while a save is already in flight.
class OnSubmitForm extends TransactionFormEvent {
  const OnSubmitForm();
}

/// Deletes the transaction being edited. Ignored in Add mode, and while a save
/// or delete is already in flight.
///
/// The screen confirms with the user before dispatching this.
class OnDeleteTransaction extends TransactionFormEvent {
  const OnDeleteTransaction();
}
