part of 'edit_profile_bloc.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Seeds the form from the user being edited.
class OnEditProfileStarted extends EditProfileEvent {
  final User user;

  const OnEditProfileStarted(this.user);

  @override
  List<Object?> get props => <Object?>[user.id, user.name, user.email];
}

class OnEditNameChanged extends EditProfileEvent {
  final String name;

  const OnEditNameChanged(this.name);

  @override
  List<Object?> get props => <Object?>[name];
}

class OnEditEmailChanged extends EditProfileEvent {
  final String email;

  const OnEditEmailChanged(this.email);

  @override
  List<Object?> get props => <Object?>[email];
}

/// Opens or closes the password section, clearing its three fields either way.
class OnTogglePasswordSection extends EditProfileEvent {
  const OnTogglePasswordSection();
}

class OnEditCurrentPasswordChanged extends EditProfileEvent {
  final String value;

  const OnEditCurrentPasswordChanged(this.value);

  @override
  List<Object?> get props => <Object?>[value];
}

class OnEditPasswordChanged extends EditProfileEvent {
  final String value;

  const OnEditPasswordChanged(this.value);

  @override
  List<Object?> get props => <Object?>[value];
}

class OnEditConfirmPasswordChanged extends EditProfileEvent {
  final String value;

  const OnEditConfirmPasswordChanged(this.value);

  @override
  List<Object?> get props => <Object?>[value];
}

/// Validates, then saves. Ignored while a save is already in flight.
class OnSubmitEditProfile extends EditProfileEvent {
  const OnSubmitEditProfile();
}
