import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/profile/domain/profile_domain.dart';

/// The profile feature's data source: the signed-in user, the family member
/// list, spending ceilings, and sign-out.
///
/// Endpoint notes worth carrying at the call site:
///
///   * `GET /profile` and `PUT /profile` answer `{message, user}` — the flat
///     `AuthController` shape, **not** the `{message, data}` envelope every
///     resource controller uses. That is why this class parses `user` by hand
///     instead of calling [unwrapObject], the same way `AuthRepo` does.
///   * `GET /users` and `PUT /users/{id}/limit` **do** use the envelope,
///     because they were added alongside the resource controllers.
///   * The token is never re-issued by `PUT /profile`, so a saved user must
///     keep the one it already has — see [User.copyWith].
class ProfileRepo extends ProfileDomain {
  static DioClient client = DioClient();

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final response = await client.request(
        requestType: RequestType.get,
        path: GlobalApiEndpoint.profile.endpoint,
      );

      return Right(_userFrom(response));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? email,
    String? password,
    String? currentPassword,
  }) async {
    try {
      final response = await client.request(
        requestType: RequestType.put,
        path: GlobalApiEndpoint.profile.endpoint,
        body: {
          // Every field is optional server-side (`sometimes`), so unchanged
          // ones are omitted entirely rather than sent back unchanged — that
          // way an email the user never touched cannot trip the unique rule.
          if (name != null && name.isNotEmpty) 'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
          if (password != null && password.isNotEmpty) ...{
            'password': password,
            // The server validates `confirmed`, so the pair must be sent.
            'password_confirmation': password,
            'current_password': currentPassword,
          },
        },
      );

      return Right(_userFrom(response));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, List<User>>> getFamilyMembers() async {
    try {
      final response = await client.request(
        requestType: RequestType.get,
        path: GlobalApiEndpoint.users.endpoint,
      );

      return Right([
        for (final json in unwrapList(response)) User.fromJson(json),
      ]);
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, User>> setSpendingLimit(int userId, num limit) async {
    try {
      final response = await client.request(
        requestType: RequestType.put,
        path: GlobalApiEndpoint.userLimit[[userId]],
        body: {'spending_limit': limit},
      );

      return Right(User.fromJson(unwrapObject(response)));
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    // The local session is cleared in a `finally`, so signing out always
    // succeeds from the user's point of view. A failed request would otherwise
    // leave them staring at a screen that will not let them out — and the
    // token they are trying to abandon still installed on the device. Losing a
    // server-side token revocation is the lesser problem.
    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.logout.endpoint,
      );
      ensureSuccess(response);
      return const Right(true);
    } on DioException {
      return const Right(true);
    } on Failure {
      return const Right(true);
    } catch (e) {
      return const Right(true);
    } finally {
      // `removeUser` is declared `void`, not `Future<void>`, so there is
      // nothing to await here — clearing the in-memory session is what actually
      // signs the user out for the rest of this process.
      LocalStorage().removeUser();
      LocalsApp.user = null;
    }
  }

  /// Parses the flat `{message, user}` body `AuthController` returns.
  ///
  /// The bearer token is carried over from the in-memory session: the endpoint
  /// does not re-issue one, and a `User` without a token would sign the user
  /// out on the next request.
  static User _userFrom(Response response) {
    // Runs the shared status ladder first — 401, 422 and 500 all throw here
    // before the body is read.
    ensureSuccess(response);

    final decoded = json.decode(response.data);
    if (decoded is! Map<String, dynamic> || decoded['user'] is! Map) {
      throw ServerFailure();
    }

    final User user = User.fromJson(decoded['user'] as Map<String, dynamic>);
    user.token = LocalsApp.user?.token;
    return user;
  }

  /// Transport-level errors, mapped exactly as the other repositories map them.
  static Failure _mapDioException(DioException ex) {
    if (ex.type == DioExceptionType.connectionTimeout ||
        ex.type == DioExceptionType.sendTimeout ||
        ex.type == DioExceptionType.receiveTimeout ||
        ex.type == DioExceptionType.unknown) {
      return ConnectionFailure();
    }
    return GlobalFailure();
  }
}
