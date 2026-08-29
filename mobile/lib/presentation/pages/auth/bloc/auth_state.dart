part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

final class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthFailure extends AuthState {
  final Failure error;

  const AuthFailure(this.error);

  @override
  List<Object> get props => [error];
}

class SendOTPSuccess extends AuthState {
  final LoginProvider provider;
  final String emailORphone;
  const SendOTPSuccess(this.provider, this.emailORphone);

  @override
  List<Object> get props => [provider, emailORphone];
}

class VerifyOTPSuccess extends AuthState {
  const VerifyOTPSuccess();

  @override
  List<Object> get props => [];
}

class RegisterSuccess extends AuthState {
  const RegisterSuccess();

  @override
  List<Object> get props => [];
}

class SocialSignUpSuccess extends AuthState {
  const SocialSignUpSuccess();

  @override
  List<Object> get props => [];
}

class LoginSuccess extends AuthState {
  const LoginSuccess();

  @override
  List<Object> get props => [];
}
