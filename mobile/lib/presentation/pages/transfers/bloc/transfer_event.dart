part of 'transfer_bloc.dart';

sealed class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loads the accounts and categories the pickers need.
///
/// Unlike the transaction and budget forms, this one fetches its own options
/// rather than receiving them from a list screen: it is opened from the
/// dashboard's quick action, which holds neither.
class OnTransferFormStarted extends TransferEvent {
  const OnTransferFormStarted();
}

class OnTransferFromChanged extends TransferEvent {
  final int accountId;

  const OnTransferFromChanged(this.accountId);

  @override
  List<Object?> get props => <Object?>[accountId];
}

class OnTransferToChanged extends TransferEvent {
  final int accountId;

  const OnTransferToChanged(this.accountId);

  @override
  List<Object?> get props => <Object?>[accountId];
}

/// Swaps source and target. Faster than re-picking both when the user realises
/// they had the direction backwards.
class OnTransferSwapAccounts extends TransferEvent {
  const OnTransferSwapAccounts();
}

class OnTransferCategoryChanged extends TransferEvent {
  final int categoryId;

  const OnTransferCategoryChanged(this.categoryId);

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// The raw text of the amount field, exactly as typed.
class OnTransferAmountChanged extends TransferEvent {
  final String amountInput;

  const OnTransferAmountChanged(this.amountInput);

  @override
  List<Object?> get props => <Object?>[amountInput];
}

class OnTransferDescriptionChanged extends TransferEvent {
  final String description;

  const OnTransferDescriptionChanged(this.description);

  @override
  List<Object?> get props => <Object?>[description];
}

class OnTransferDateChanged extends TransferEvent {
  final DateTime date;

  const OnTransferDateChanged(this.date);

  @override
  List<Object?> get props => <Object?>[date];
}

/// Validates, then executes. Ignored while a transfer is already in flight —
/// a double tap must not move the money twice.
class OnSubmitTransfer extends TransferEvent {
  const OnSubmitTransfer();
}
