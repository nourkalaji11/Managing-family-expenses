import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/data/repos/profile_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/profile/domain/profile_domain.dart';

part 'family_event.dart';
part 'family_state.dart';

/// Owns the family-members screen: the member list and their spending ceilings.
///
/// The list is **not** filtered here. `GET /users` already scopes by role — a
/// parent receives everyone, a member receives only themselves — and filtering
/// again on the client would imply the client is what protects the other
/// members' details. It is not.
class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final ProfileDomain _repo;

  FamilyBloc({ProfileDomain? repo})
    : _repo = repo ?? ProfileRepo(),
      super(const FamilyInitial()) {
    on<FamilyEvent>((event, emit) async {
      if (event is OnLoadFamily) {
        emit(const FamilyLoading());
        await _load(emit);
      } else if (event is OnRefreshFamily) {
        final current = state;
        if (current is FamilyLoaded) emit(current.copyWith(isRefreshing: true));
        await _load(emit);
      } else if (event is OnSetSpendingLimit) {
        await _setLimit(emit, event.userId, event.limit);
      } else if (event is OnAddFamilyMember) {
        await _addMember(emit, event);
      }
    });
  }

  Future<void> _load(Emitter<FamilyState> emit) async {
    final result = await _repo.getFamilyMembers();
    result.fold(
      (failure) => emit(FamilyFailure(failure)),
      (members) => emit(
        FamilyLoaded(
          members: members,
          // Taken from the session rather than inferred from the list length:
          // a family with exactly one member would otherwise read as a parent.
          canManage: LocalsApp.user?.isParent ?? false,
        ),
      ),
    );
  }

  Future<void> _addMember(
    Emitter<FamilyState> emit,
    OnAddFamilyMember event,
  ) async {
    final FamilyState current = state;
    if (current is! FamilyLoaded) return;
    // A second submission while the first is in flight would create the child
    // twice — or once, plus a confusing duplicate-email error.
    if (current.isAddingMember) return;

    emit(current.copyWith(isAddingMember: true, clearFailure: true));

    final result = await _repo.createMember(
      name: event.name,
      email: event.email,
      password: event.password,
      spendingLimit: event.spendingLimit,
    );

    result.fold(
      (failure) =>
          emit(current.copyWith(isAddingMember: false, writeFailure: failure)),
      (created) {
        // Appended and re-sorted rather than refetched: the server answers with
        // the new row, and the list is ordered by name on both sides.
        final List<User> next = [...current.members, created]
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

        emit(
          current.copyWith(
            members: next,
            isAddingMember: false,
            lastAddedMemberId: created.id,
          ),
        );
      },
    );
  }

  Future<void> _setLimit(
    Emitter<FamilyState> emit,
    int userId,
    num limit,
  ) async {
    final FamilyState current = state;
    if (current is! FamilyLoaded) return;
    if (current.savingMemberId != null) return;

    emit(current.copyWith(savingMemberId: userId, clearFailure: true));

    final result = await _repo.setSpendingLimit(userId, limit);

    result.fold(
      (failure) => emit(
        current.copyWith(clearSavingMemberId: true, writeFailure: failure),
      ),
      (updated) {
        // The row is replaced in place rather than the whole list refetched:
        // the server answers with the updated user, and a second round trip
        // would only re-read what is already known.
        final List<User> next = [
          for (final m in current.members)
            if (m.id == updated.id) updated else m,
        ];
        emit(
          current.copyWith(
            members: next,
            clearSavingMemberId: true,
            lastSavedMemberId: updated.id,
          ),
        );
      },
    );
  }
}
