import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/data/repos/profile_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/profile/domain/profile_domain.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

/// Drives the edit-profile form.
///
/// Validation mirrors what `AuthController::updateProfile` enforces, plus one
/// rule the UI owns: a new password must be confirmed here as well as
/// server-side, so a typo is caught before a round trip.
///
/// The password section is optional and collapsed by default. Sending an
/// unchanged password on every save would force the user to re-enter their
/// current one just to fix a typo in their name.
class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final ProfileDomain _repo;

  EditProfileBloc({ProfileDomain? repo})
    : _repo = repo ?? ProfileRepo(),
      super(const EditProfileState.initial()) {
    on<EditProfileEvent>((event, emit) async {
      if (event is OnEditProfileStarted) {
        emit(
          EditProfileState(
            name: event.user.name ?? '',
            email: event.user.email ?? '',
            errors: const EditProfileErrors(),
          ),
        );
      } else if (event is OnEditNameChanged) {
        emit(_revalidated(state.copyWith(name: event.name)));
      } else if (event is OnEditEmailChanged) {
        emit(_revalidated(state.copyWith(email: event.email)));
      } else if (event is OnTogglePasswordSection) {
        emit(
          _revalidated(
            state.copyWith(
              changingPassword: !state.changingPassword,
              // Clearing the fields on collapse means a half-typed password
              // cannot be submitted by an accidental second toggle.
              currentPassword: '',
              password: '',
              confirmPassword: '',
            ),
          ),
        );
      } else if (event is OnEditCurrentPasswordChanged) {
        emit(_revalidated(state.copyWith(currentPassword: event.value)));
      } else if (event is OnEditPasswordChanged) {
        emit(_revalidated(state.copyWith(password: event.value)));
      } else if (event is OnEditConfirmPasswordChanged) {
        emit(_revalidated(state.copyWith(confirmPassword: event.value)));
      } else if (event is OnSubmitEditProfile) {
        await _submit(emit);
      }
    });
  }

  EditProfileState _revalidated(EditProfileState next) => next.copyWith(
    errors: validate(next),
    status: EditProfileStatus.editing,
    clearFailure: true,
  );

  Future<void> _submit(Emitter<EditProfileState> emit) async {
    if (state.isSubmitting) return;

    final EditProfileErrors errors = validate(state);
    if (errors.hasAny) {
      emit(state.copyWith(errors: errors, showErrors: true));
      return;
    }

    emit(
      state.copyWith(
        status: EditProfileStatus.submitting,
        showErrors: true,
        errors: errors,
        clearFailure: true,
      ),
    );

    final result = await _repo.updateProfile(
      name: state.name.trim(),
      email: state.email.trim(),
      password: state.changingPassword ? state.password : null,
      currentPassword: state.changingPassword ? state.currentPassword : null,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: EditProfileStatus.failure, failure: failure),
      ),
      (user) {
        // The session is updated here rather than by the screen, so every other
        // surface sees the new name without waiting for its own refresh.
        LocalsApp.user = user;
        emit(state.copyWith(status: EditProfileStatus.success, saved: user));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Validation. Returns localisation KEYS, not translated strings.
  // ---------------------------------------------------------------------------

  /// Backend rule: `max:255` on both name and email.
  static const int maxNameLength = 255;

  /// Backend rule: `min:8`.
  static const int minPasswordLength = 8;

  static EditProfileErrors validate(EditProfileState state) {
    final String name = state.name.trim();
    String? nameError;
    if (name.isEmpty) {
      nameError = 'profile.error_name_required';
    } else if (name.length > maxNameLength) {
      nameError = 'profile.error_name_too_long';
    }

    final String email = state.email.trim();
    String? emailError;
    if (email.isEmpty) {
      emailError = 'auth.error_email_required';
    } else if (!_looksLikeEmail(email)) {
      emailError = 'auth.error_email_invalid';
    }

    // Uniqueness is not checked here on purpose: the client cannot see other
    // families' emails, so the authoritative answer is the server's 422.

    String? currentError;
    String? passwordError;
    String? confirmError;

    if (state.changingPassword) {
      if (state.currentPassword.isEmpty) {
        currentError = 'profile.error_current_password_required';
      }
      if (state.password.isEmpty) {
        passwordError = 'auth.error_password_required';
      } else if (state.password.length < minPasswordLength) {
        passwordError = 'auth.error_password_short';
      }
      if (state.confirmPassword != state.password) {
        confirmError = 'auth.error_passwords_not_match';
      }
    }

    return EditProfileErrors(
      name: nameError,
      email: emailError,
      currentPassword: currentError,
      password: passwordError,
      confirmPassword: confirmError,
    );
  }

  /// A deliberately loose check: one `@`, something either side, a dot in the
  /// domain. Anything stricter rejects addresses that are legitimately valid,
  /// and the server validates properly anyway.
  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}
