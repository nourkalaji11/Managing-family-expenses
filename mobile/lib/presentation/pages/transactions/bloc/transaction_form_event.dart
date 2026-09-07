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

/// The amount as typed on the system keyboard.
///
/// Replaces the whole buffer rather than appending, because a real keyboard
/// also allows selecting, pasting and deleting from the middle — none of which
/// a digit-at-a-time event can express.
class OnAmountChanged extends TransactionFormEvent {
  final String input;

  const OnAmountChanged(this.input);

  @override
  List<Object?> get props => <Object?>[input];
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
