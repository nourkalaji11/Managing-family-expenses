part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => <Object?>[];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Only reached when there is no cached user at all — in practice, never, since
/// the screen is unreachable without signing in first.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;

  /// True while the server copy is being fetched over an already-shown cached
  /// user. The screen renders normally; nothing spins.
  final bool isRefreshing;

  final bool isLoggingOut;

  const ProfileLoaded({
    required this.user,
    this.isRefreshing = false,
    this.isLoggingOut = false,
  });

  ProfileLoaded copyWith({User? user, bool? isRefreshing, bool? isLoggingOut}) =>
      ProfileLoaded(
        user: user ?? this.user,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      );

  @override
  List<Object?> get props => <Object?>[
    user.id,
    user.name,
    user.email,
    user.role,
    user.spendingLimit,
    isRefreshing,
    isLoggingOut,
  ];
}

/// Terminal. The screen navigates back to login on this and clears the stack.
class ProfileLoggedOut extends ProfileState {
  const ProfileLoggedOut();
}

class ProfileFailure extends ProfileState {
  final Failure error;

  const ProfileFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
