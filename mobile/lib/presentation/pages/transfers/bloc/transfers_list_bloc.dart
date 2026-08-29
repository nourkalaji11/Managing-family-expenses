import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/transfer_data.dart';
import 'package:family_expense_management/data/repos/transfers_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/transfers/domain/transfers_domain.dart';

part 'transfers_list_event.dart';
part 'transfers_list_state.dart';

/// Owns the transfer history: the past transfers and undoing one.
///
/// Separate from `TransferBloc`, which drives the *form*. They share a
/// repository but nothing else: one holds a draft being composed, the other a
/// list already committed, and folding them together would put an
/// `amountInput` string in the same state object as a list of saved rows.
class TransfersListBloc extends Bloc<TransfersListEvent, TransfersListState> {
  final TransfersDomain _repo;

  TransfersListBloc({TransfersDomain? repo})
    : _repo = repo ?? TransfersRepo(),
      super(const TransfersListInitial()) {
    on<TransfersListEvent>((event, emit) async {
      if (event is OnLoadTransfers) {
        emit(const TransfersListLoading());
        await _load(emit);
      } else if (event is OnRefreshTransfers) {
        final current = state;
        if (current is TransfersListLoaded) {
          emit(current.copyWith(isRefreshing: true));
        }
        await _load(emit);
      } else if (event is OnUndoTransfer) {
        await _undo(emit, event.groupId);
      }
    });
  }

  Future<void> _load(Emitter<TransfersListState> emit) async {
    final result = await _repo.getTransfers();
    result.fold(
      (failure) => emit(TransfersListFailure(failure)),
      (transfers) => emit(TransfersListLoaded(transfers: transfers)),
    );
  }

  Future<void> _undo(Emitter<TransfersListState> emit, String groupId) async {
    final TransfersListState current = state;
    if (current is! TransfersListLoaded) return;
    if (current.undoingGroupId != null) return;

    emit(current.copyWith(undoingGroupId: groupId, clearFailure: true));

    final result = await _repo.deleteTransfer(groupId);

    result.fold(
      // The row is put back on failure: an undo that silently did nothing would
      // leave the user believing two balances had moved back when they had not.
      (failure) => emit(
        current.copyWith(clearUndoing: true, writeFailure: failure),
      ),
      (_) => emit(
        current.copyWith(
          transfers: [
            for (final t in current.transfers)
              if (t.groupId != groupId) t,
          ],
          clearUndoing: true,
          undoneGroupId: groupId,
        ),
      ),
    );
  }
}
