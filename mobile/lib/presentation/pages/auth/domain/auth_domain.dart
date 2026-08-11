import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/network/failure.dart';

abstract class AuthDomain {
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required AccountRole role,
    required String deviceToken,
    String? phone,
    String? username,
    String? referralCode,
  });

  Future<Either<Failure, bool>> sendOTP({
    required LoginProvider provider,
    required String emailORphone,
  });

  Future<Either<Failure, User>> verifyOTP({
    required LoginProvider provider,
    required String emailORphone,
    required String otp,
    required String deviceToken,
  });

  Future<Either<Failure, String>> social({
    required LoginProvider provider,
    required String token,
    required String? fullName,
    required String? secretToken,
    required String? notificationToken,
    String? referralCode,
  });

  Future<Either<Failure, User>> login({
    required String? notificationToken,
    required String email,
    required String password,
  });
}
