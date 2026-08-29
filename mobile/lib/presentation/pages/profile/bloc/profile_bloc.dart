import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/data/repos/profile_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/profile/domain/profile_domain.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Owns the profile screen: the signed-in user and sign-out.
///
/// The user is re-read from `GET /profile` rather than taken from
/// `LocalsApp.user`, which holds whatever the login response contained. A
/// parent may have changed this member's spending ceiling since — and the
/// screen that displays the ceiling must not show a stale one.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileDomain _repo;

  ProfileBloc({ProfileDomain? repo})
    : _repo = repo ?? ProfileRepo(),
      super(const ProfileInitial()) {
    on<ProfileEvent>((event, emit) async {
      if (event is OnLoadProfile) {
        // The cached user is shown immediately so the screen is never blank,
        // then replaced by the server's copy. Showing a spinner over data the
        // app already holds would be a step backwards.
        final User? cached = LocalsApp.user;
        if (cached != null) {
          emit(ProfileLoaded(user: cached, isRefreshing: true));
        } else {
          emit(const ProfileLoading());
        }
        await _load(emit);
      } else if (event is OnRefreshProfile) {
        await _load(emit);
      } else if (event is OnProfileUpdated) {
        emit(ProfileLoaded(user: event.user));
      } else if (event is OnLogout) {
        await _logout(emit);
      }
    });
  }

  Future<void> _load(Emitter<ProfileState> emit) async {
    final result = await _repo.getProfile();
    result.fold(
      (failure) {
        // A failed refresh keeps the cached user on screen: the profile is not
        // worth an error page when there is a perfectly good local copy.
        final ProfileState current = state;
        if (current is ProfileLoaded) {
          emit(current.copyWith(isRefreshing: false));
        } else {
          emit(ProfileFailure(failure));
        }
      },
      (user) {
        // The session is refreshed too, so every other screen sees the same
        // role and ceiling this one just read.
        LocalsApp.user = user;
        emit(ProfileLoaded(user: user));
      },
    );
  }

  Future<void> _logout(Emitter<ProfileState> emit) async {
    final ProfileState current = state;
    if (current is ProfileLoaded) {
      emit(current.copyWith(isLoggingOut: true));
    }

    // Always succeeds — see `ProfileRepo.logout` for why signing out locally
    // must not depend on the network.
    await _repo.logout();
    emit(const ProfileLoggedOut());
  }
}
