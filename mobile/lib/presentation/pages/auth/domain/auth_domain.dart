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

  Future<Either<Failure, User>> login({
    required String? notificationToken,
    required String email,
    required String password,
  });
}
