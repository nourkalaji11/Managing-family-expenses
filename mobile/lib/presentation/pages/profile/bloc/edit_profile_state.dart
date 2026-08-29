part of 'edit_profile_bloc.dart';

enum EditProfileStatus { editing, submitting, success, failure }

/// One localisation KEY per field, or null when the field is valid.
class EditProfileErrors extends Equatable {
  final String? name;
  final String? email;
  final String? currentPassword;
  final String? password;
  final String? confirmPassword;

  const EditProfileErrors({
    this.name,
    this.email,
    this.currentPassword,
    this.password,
    this.confirmPassword,
  });

  bool get hasAny =>
      name != null ||
      email != null ||
      currentPassword != null ||
      password != null ||
      confirmPassword != null;

  @override
  List<Object?> get props => <Object?>[
    name,
    email,
    currentPassword,
    password,
    confirmPassword,
  ];
}

class EditProfileState extends Equatable {
  final String name;
  final String email;

  /// True when the password section is expanded. While false the three
  /// password fields are neither validated nor sent.
  final bool changingPassword;

  final String currentPassword;
  final String password;
  final String confirmPassword;

  final EditProfileStatus status;
  final bool showErrors;
  final EditProfileErrors errors;

  /// Carries the server's message — which is the only side that can decide a
  /// duplicate email (422) or a wrong current password (422).
  final Failure? failure;

  final User? saved;

  const EditProfileState({
    required this.errors,
    this.name = '',
    this.email = '',
    this.changingPassword = false,
    this.currentPassword = '',
    this.password = '',
    this.confirmPassword = '',
    this.status = EditProfileStatus.editing,
    this.showErrors = false,
    this.failure,
    this.saved,
  });

  const EditProfileState.initial()
    : name = '',
      email = '',
      changingPassword = false,
      currentPassword = '',
      password = '',
      confirmPassword = '',
      status = EditProfileStatus.editing,
      showErrors = false,
      errors = const EditProfileErrors(),
      failure = null,
      saved = null;

  bool get isSubmitting => status == EditProfileStatus.submitting;

  EditProfileState copyWith({
    String? name,
    String? email,
    bool? changingPassword,
    String? currentPassword,
    String? password,
    String? confirmPassword,
    EditProfileStatus? status,
    bool? showErrors,
    EditProfileErrors? errors,
    Failure? failure,
    User? saved,

    /// Explicitly drops a previous failure, since `failure: null` in a
    /// `??`-based copyWith means "keep the old one".
    bool clearFailure = false,
  }) => EditProfileState(
    name: name ?? this.name,
    email: email ?? this.email,
    changingPassword: changingPassword ?? this.changingPassword,
    currentPassword: currentPassword ?? this.currentPassword,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    status: status ?? this.status,
    showErrors: showErrors ?? this.showErrors,
    errors: errors ?? this.errors,
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
  );

  // The password fields appear as **lengths**, never as values.
  //
  // Two reasons, and both matter:
  //   * Plaintext in `props` would reach any bloc observer or crash reporter
  //     that logs state transitions, which is exactly how credentials end up in
  //     a log file.
  //   * They cannot simply be omitted either. `Bloc.emit` drops a state that
  //     compares equal to the current one — so with the fields absent, typing
  //     the second character of a password would produce an "equal" state, the
  //     emit would be skipped, and `state.password` would still hold one
  //     character when submit read it.
  //
  // A length changes on every keystroke and is not a credential.
  @override
  List<Object?> get props => <Object?>[
    name,
    email,
    changingPassword,
    currentPassword.length,
    password.length,
    confirmPassword.length,
    status,
    showErrors,
    errors,
    failure?.message,
    saved?.id,
  ];
}
