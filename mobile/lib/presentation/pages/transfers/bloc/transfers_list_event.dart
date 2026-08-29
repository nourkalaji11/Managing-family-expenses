part of 'transfers_list_bloc.dart';

sealed class TransfersListEvent extends Equatable {
  const TransfersListEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the full-screen loader.
class OnLoadTransfers extends TransfersListEvent {
  const OnLoadTransfers();
}

/// Pull-to-refresh, and what the screen dispatches after a new transfer is
/// made from the form it was pushed from.
class OnRefreshTransfers extends TransfersListEvent {
  const OnRefreshTransfers();
}

/// Reverses a transfer: deletes both legs and restores both balances.
///
/// Takes the **group id**, not a transaction id — deleting one leg would leave
/// the other orphaned, which the server refuses outright.
///
/// Ignored while another undo is in flight.
class OnUndoTransfer extends TransfersListEvent {
  final String groupId;

  const OnUndoTransfer(this.groupId);

  @override
  List<Object?> get props => <Object?>[groupId];
}
