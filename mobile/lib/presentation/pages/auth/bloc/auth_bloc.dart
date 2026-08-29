import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/data/repos/auth_repo.dart';
import 'package:family_expense_management/network/failure.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      if (event is OnRegister) {
        emit(AuthLoading());
        final result = await AuthRepo().register(
          name: event.name,
          email: event.email,
          password: event.password,
          passwordConfirmation: event.passwordConfirmation,
          role: event.role,
          phone: event.phone,
          username: event.username,
          referralCode: event.referralCode,
          deviceToken: LocalsApp.deviceToken ?? "",
        );
        result.fold(
          (left) {
            emit(AuthFailure(left));
          },
          (right) {
            LocalStorage().saveUser(right.token ?? "");
            LocalsApp.user = right;
            emit(const RegisterSuccess());
          },
        );
      }

      if (event is OnLogin) {
        emit(AuthLoading());
        final result = await AuthRepo().login(
          email: event.email,
          password: event.password,
          notificationToken: LocalsApp.deviceToken ?? "",
        );
        result.fold(
          (left) {
            emit(AuthFailure(left));
          },
          (right) {
            LocalStorage().saveUser(right.token ?? "");
            LocalsApp.user = right;
            emit(const LoginSuccess());
          },
        );
      }
    });
  }
}
