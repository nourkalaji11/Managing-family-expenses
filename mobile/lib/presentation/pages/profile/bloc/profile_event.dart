part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the cached user immediately, then refreshes from the
/// server.
class OnLoadProfile extends ProfileEvent {
  const OnLoadProfile();
}

/// Pull-to-refresh, and what the screen dispatches after returning from the
/// edit form.
class OnRefreshProfile extends ProfileEvent {
  const OnRefreshProfile();
}

/// The edit form saved. Carries the updated user so the screen does not have to
/// wait for a round trip to show the new name.
class OnProfileUpdated extends ProfileEvent {
  final User user;

  const OnProfileUpdated(this.user);

  @override
  List<Object?> get props => <Object?>[user.id, user.name, user.email];
}

/// Revokes the token and clears the local session.
class OnLogout extends ProfileEvent {
  const OnLogout();
}
