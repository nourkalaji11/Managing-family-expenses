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

class RegisterSuccess extends AuthState {
  const RegisterSuccess();

  @override
  List<Object> get props => [];
}

class LoginSuccess extends AuthState {
  const LoginSuccess();

  @override
  List<Object> get props => [];
}
