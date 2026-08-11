part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class OnSendOTP extends AuthEvent {
  final LoginProvider provider;
  final String emailORphone;

  const OnSendOTP({required this.provider, required this.emailORphone});

  @override
  List<Object> get props => [provider, emailORphone];
}

class OnVerifyOTP extends AuthEvent {
  final LoginProvider provider;
  final String emailORphone;
  final String otp;

  const OnVerifyOTP(
    this.otp, {
    required this.provider,
    required this.emailORphone,
  });

  @override
  List<Object> get props => [provider, emailORphone, otp];
}

class OnRegister extends AuthEvent {
  final String name;
  final String email;
  final String password;

  /// Local confirmation of [password].
  ///
  /// TODO(backend): not sent to the API yet — the Laravel registration contract
  /// has not been confirmed, so we do not guess a `password_confirmation` field.
  final String passwordConfirmation;

  /// Sent to the API as `role` (`parent` | `member`). The `users.role` column
  /// is required by the schema. See [AccountRole].
  final AccountRole role;

  /// Optional legacy fields kept so the older [Signup] screen still compiles.
  /// They are omitted from the request body when null/empty.
  final String? phone;
  final String? username;
  final String? referralCode;

  const OnRegister({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.role,
    this.phone,
    this.username,
    this.referralCode,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    passwordConfirmation,
    role,
    phone,
    username,
    referralCode,
  ];
}

class OnSocial extends AuthEvent {
  final LoginProvider provider;
  final String token;
  final String? fullName;
  final String? secretToken;
  final String? referralCode;

  const OnSocial({
    required this.provider,
    required this.token,
    required this.fullName,
    required this.secretToken,
    this.referralCode,
  });

  @override
  List<Object?> get props => [
    provider,
    token,
    fullName,
    secretToken,
    referralCode,
  ];
}

class OnLogin extends AuthEvent {
  /// Login is email-based for this application (see `AuthRepo.login`).
  final String email;
  final String password;

  const OnLogin({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
