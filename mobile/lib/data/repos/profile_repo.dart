import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
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

  static const bool useMock = kUseMockData;

  static const Duration mockDelay = Duration(milliseconds: 450);
  static const Duration mockWriteDelay = Duration(milliseconds: 350);

  @override
  Future<Either<Failure, User>> getProfile() async {
    if (useMock) return _mockGetProfile();

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
    if (useMock) {
      return _mockUpdateProfile(
        name: name,
        email: email,
        password: password,
        currentPassword: currentPassword,
      );
    }

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
    if (useMock) return _mockFamilyMembers();

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
    if (useMock) return _mockSetSpendingLimit(userId, limit);

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
    if (useMock) {
      // No request to make — there is no token to revoke. The local clear below
      // is what signing out actually means here, so it is done directly rather
      // than by letting a doomed request fall through to the `finally`.
      await Future.delayed(mockWriteDelay);
      LocalStorage().removeUser();
      LocalsApp.user = null;
      return const Right(true);
    }

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

  // ---------------------------------------------------------------------------
  // Mock path.
  //
  // The role rules ARE reproduced here — `getFamilyMembers` scopes by role and
  // `setSpendingLimit` refuses a member and refuses a parent target — because
  // they are the whole point of these screens. Sign in as `nour@example.com` and
  // the family list shortens to one row and the ceiling controls answer 403,
  // exactly as against a real server.
  //
  // What cannot be reproduced is the password check: the seed carries no
  // hashes, so `updateProfile` verifies only that a current password was
  // *supplied*, not that it is right. That is called out where it happens.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, User>> _mockGetProfile() async {
    await Future.delayed(mockDelay);

    final user = MockStore.instance.signedInUser;
    if (user == null) return Left(ResultFailure('unauthenticated'.tr()));

    return Right(_asSession(user));
  }

  Future<Either<Failure, User>> _mockUpdateProfile({
    String? name,
    String? email,
    String? password,
    String? currentPassword,
  }) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    final current = store.signedInUser;
    if (current == null) return Left(ResultFailure('unauthenticated'.tr()));

    if (password != null && password.isNotEmpty) {
      // `required_with:password` — the only half of the server's check that can
      // be reproduced without a hash to compare against. A wrong-but-non-empty
      // current password is accepted here and would be rejected by the server.
      if (currentPassword == null || currentPassword.isEmpty) {
        return Left(ResultFailure('profile.error_wrong_password'.tr()));
      }
    }

    if (email != null &&
        email.isNotEmpty &&
        store.emailTaken(email, exceptId: current.id)) {
      return Left(ResultFailure('profile.error_email_taken'.tr()));
    }

    // The role is deliberately not editable, matching `updateProfile`: a member
    // promoting themselves to parent is a privilege escalation, not a profile
    // edit. `copyWith` carries the existing role forward untouched.
    final updated = current.copyWith(
      name: (name != null && name.isNotEmpty) ? name : null,
      email: (email != null && email.isNotEmpty) ? email : null,
    );

    if (!store.updateUser(updated)) {
      return Left(ResultFailure('profile.error_member_not_found'.tr()));
    }
    return Right(_asSession(updated));
  }

  Future<Either<Failure, List<User>>> _mockFamilyMembers() async {
    await Future.delayed(mockDelay);

    final store = MockStore.instance;
    final viewer = store.signedInUser;
    if (viewer == null) return Left(ResultFailure('unauthenticated'.tr()));

    // The server's rule: a parent sees everyone, a member sees only themselves.
    // A member who could enumerate the family would be reading other people's
    // names, emails and ceilings.
    final members = viewer.isParent
        ? ([...store.users]
            ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? '')))
        : <User>[viewer];

    return Right(members);
  }

  Future<Either<Failure, User>> _mockSetSpendingLimit(
    int userId,
    num limit,
  ) async {
    await Future.delayed(mockWriteDelay);

    final store = MockStore.instance;
    final viewer = store.signedInUser;
    if (viewer == null) return Left(ResultFailure('unauthenticated'.tr()));

    // 403.
    if (!viewer.isParent) {
      return Left(ResultFailure('profile.error_limit_forbidden'.tr()));
    }

    final target = store.userById(userId);
    if (target == null) {
      return Left(ResultFailure('profile.error_member_not_found'.tr()));
    }

    // 422. A ceiling on a parent is a number that constrains nothing but reads
    // as though it does.
    if (target.isParent) {
      return Left(ResultFailure('profile.error_limit_parent'.tr()));
    }

    final updated = target.copyWith(spendingLimit: limit);
    if (!store.updateUser(updated)) {
      return Left(ResultFailure('profile.error_member_not_found'.tr()));
    }

    // `NotificationService::limitUpdated` fires here on the server. Generated
    // in the mock too, so the notifications tab reflects what was just done
    // rather than staying frozen on its seed.
    store.addNotification(
      AppNotification(
        id: store.allocateNotificationId(),
        rawType: NotificationType.limitUpdated.wire,
        title: 'تم تحديث سقف السحب',
        message:
            'تم تعيين سقف سحب بقيمة ${limit.toStringAsFixed(0)} ل.س '
            'لحساب ${target.name ?? ''}.',
        createdAt: DateTime.now(),
      ),
    );

    return Right(updated);
  }

  /// A copy of [user] carrying the session's token.
  ///
  /// The remote path does the same in [_userFrom]: `/profile` answers with the
  /// user but no token, and dropping it would leave `LocalsApp.user` unable to
  /// authorise the next request.
  static User _asSession(User user) {
    final session = user.copyWith();
    session.token = LocalsApp.user?.token;
    return session;
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
