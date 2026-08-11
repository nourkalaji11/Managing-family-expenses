import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/data/repos/auth_repo.dart';
import 'package:family_expense_management/network/failure.dart';

part 'auth_event.dart';
part 'auth_state.dart';

String? tempProvider;
int secondsDue = 0;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      if (event is OnSendOTP) {
        print(event.emailORphone);
        print(tempProvider);
        print(secondsDue);
        if (tempProvider == event.emailORphone && secondsDue > 0) {
          emit(SendOTPSuccess(event.provider, event.emailORphone));
        } else {
          emit(AuthLoading());
          final result = await AuthRepo().sendOTP(
            provider: event.provider,
            emailORphone: event.emailORphone,
          );
          result.fold(
            (left) {
              emit(AuthFailure(left));
            },
            (right) {
              emit(SendOTPSuccess(event.provider, event.emailORphone));
            },
          );
        }
      }

      if (event is OnVerifyOTP) {
        emit(AuthLoading());
        final result = await AuthRepo().verifyOTP(
          provider: event.provider,
          emailORphone: event.emailORphone,
          otp: event.otp,
          deviceToken: LocalsApp.deviceToken ?? "",
        );
        result.fold(
          (left) {
            emit(AuthFailure(left));
          },
          (right) {
            LocalStorage().saveUser(right.token ?? "");
            LocalsApp.user = right;
            emit(const VerifyOTPSuccess());
          },
        );
      }

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

      if (event is OnSocial) {
        emit(AuthLoading());
        final result = await AuthRepo().social(
          token: event.token,
          secretToken: event.secretToken,
          provider: event.provider,
          notificationToken: LocalsApp.deviceToken,
          referralCode: event.referralCode,
          fullName: event.fullName,
        );
        result.fold(
          (left) {
            emit(AuthFailure(left));
          },
          (right) {
            LocalStorage().saveUser(right);
            emit(const SocialSignUpSuccess());
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
