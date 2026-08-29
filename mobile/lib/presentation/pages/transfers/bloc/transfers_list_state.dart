part of 'transfers_list_bloc.dart';

sealed class TransfersListState extends Equatable {
  const TransfersListState();

  @override
  List<Object?> get props => <Object?>[];
}

class TransfersListInitial extends TransfersListState {
  const TransfersListInitial();
}

class TransfersListLoading extends TransfersListState {
  const TransfersListLoading();
}

class TransfersListLoaded extends TransfersListState {
  /// Newest first, already grouped by the server into one object per transfer
  /// rather than the two transaction rows each is stored as.
  final List<TransferModel> transfers;

  /// Group id currently being undone, or null when idle. Only one at a time —
  /// two concurrent undos on the same account would race its balance.
  final String? undoingGroupId;

  /// The group undone most recently, so the screen can confirm.
  final String? undoneGroupId;

  /// Set when an undo fails; carries the server's message.
  final Failure? writeFailure;

  final bool isRefreshing;

  const TransfersListLoaded({
    required this.transfers,
    this.undoingGroupId,
    this.undoneGroupId,
    this.writeFailure,
    this.isRefreshing = false,
  });

  bool get isEmpty => transfers.isEmpty;

  bool isUndoing(String? groupId) =>
      groupId != null && undoingGroupId == groupId;

  TransfersListLoaded copyWith({
    List<TransferModel>? transfers,
    String? undoingGroupId,
    String? undoneGroupId,
    Failure? writeFailure,
    bool? isRefreshing,

    /// Explicit clears, because `null` in a `??`-based copyWith means "keep".
    bool clearUndoing = false,
    bool clearFailure = false,
  }) => TransfersListLoaded(
    transfers: transfers ?? this.transfers,
    undoingGroupId: clearUndoing
        ? null
        : (undoingGroupId ?? this.undoingGroupId),
    undoneGroupId: undoneGroupId ?? this.undoneGroupId,
    writeFailure: clearFailure ? null : (writeFailure ?? this.writeFailure),
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => <Object?>[
    [for (final t in transfers) t.groupId],
    undoingGroupId,
    undoneGroupId,
    writeFailure?.message,
    isRefreshing,
  ];
}

class TransfersListFailure extends TransfersListState {
  final Failure error;

  const TransfersListFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
