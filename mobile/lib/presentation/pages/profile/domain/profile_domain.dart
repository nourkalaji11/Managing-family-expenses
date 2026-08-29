import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the profile feature needs, independent of where the data lives.
///
/// Covers three surfaces that share one backend controller: the signed-in
/// user's own record, the family member list, and each member's spending
/// ceiling.
abstract class ProfileDomain {
  /// The signed-in user, re-read from the server rather than from the cached
  /// login response — the role or the ceiling may have changed since.
  Future<Either<Failure, User>> getProfile();

  /// Edits name, email, or password.
  ///
  /// [currentPassword] is required by the server whenever [password] is
  /// supplied, and rejected as a 422 if wrong: a stolen token must not be
  /// enough to take the account over permanently.
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? email,
    String? password,
    String? currentPassword,
  });

  /// Family members. The server scopes this by role: a parent gets everyone, a
  /// member gets only themselves.
  Future<Either<Failure, List<User>>> getFamilyMembers();

  /// Sets a member's spending ceiling. Parent-only; the server answers 403
  /// otherwise, and 422 when the target is itself a parent.
  Future<Either<Failure, User>> setSpendingLimit(int userId, num limit);

  /// Revokes the token this device is using.
  ///
  /// Returns `true` even when the request itself failed: see `ProfileRepo` for
  /// why signing out locally must not depend on the network.
  Future<Either<Failure, bool>> logout();
}
