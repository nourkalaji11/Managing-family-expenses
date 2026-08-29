import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/auth/domain/auth_domain.dart';

class AuthRepo extends AuthDomain {
  static DioClient client = DioClient();

  static const bool useMock = kUseMockData;

  static const Duration mockDelay = Duration(milliseconds: 700);

  /// What a mock session carries instead of a bearer token.
  ///
  /// It is deliberately not token-shaped. `DioClient` puts `LocalsApp.user.token`
  /// straight into the Authorization header, and a mock build must never end up
  /// holding a string that could be mistaken for a credential — in a log, in a
  /// screenshot, or by a reader of this code. Nothing in the mock path makes a
  /// request, so this value is never sent anywhere; if it ever appears in a
  /// request log, that is the bug it is named to expose.
  static const String mockToken = 'mock-session-no-credential';

  @override
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
  }) async {
    if (useMock) {
      return _mockRegister(name: name, email: email, role: role);
    }

    try {
      String fcm = await LocalStorage().getFCMToken();
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.register.endpoint,
        body: {
          "name": name,
          "email": email,
          "password": password,

          // `users.role` is a required column; the accepted values are
          // `parent` | `member`. Using `AccountRole.apiValue` keeps the Arabic
          // UI labels out of the request payload.
          "role": role.apiValue,

          // Optional fields are omitted entirely rather than sent as empty
          // strings, so the backend never receives placeholder values.
          if (phone != null && phone.isNotEmpty) "phone": phone,
          if (username != null && username.isNotEmpty) "username": username,
          if (referralCode != null && referralCode.isNotEmpty)
            "referral_code": referralCode,

          "player_id": deviceToken,
          "fcm": fcm,

          // TODO(backend): `password_confirmation` is collected and validated in
          // the UI but NOT sent. There is no Laravel project in this repository
          // (`backend/` has only ever contained .gitkeep), so the registration
          // contract cannot be inspected. Once the controller is available and
          // its rules use `confirmed`, add:
          //   "password_confirmation": passwordConfirmation,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // AuthController@register returns a flat body:
        //   { message, access_token, token_type, user }
        // There is no `data` envelope and no Authorization response header.
        var result = json.decode(response.data);
        User user = userFromJson(json.encode(result['user']));
        user.token = result['access_token'];
        return Right(user);
      } else if (response.statusCode == 500) {
        return Left(ServerFailure());
      } else {
        var result = json.decode(response.data);
        return Left(ResultFailure(result['message']));
      }
    } on DioException catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout ||
          ex.type == DioExceptionType.sendTimeout ||
          ex.type == DioExceptionType.receiveTimeout ||
          ex.type == DioExceptionType.unknown) {
        return Left(ConnectionFailure());
      } else {
        return Left(GlobalFailure());
      }
    } on Failure catch (e) {
      print(e);
      return Left(e);
    } catch (e) {
      print(e);
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String? notificationToken,
    required String email,
    required String password,
  }) async {
    if (useMock) return _mockLogin(email: email, password: password);

    try {
      String fcm = await LocalStorage().getFCMToken();
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.login.endpoint,
        body: {
          // The template this project started from sent `"username": ...`.
          // This application logs in with an email address, so the key was
          // changed to `email`. If the backend turns out to expect a username
          // field, this single line is the only thing that has to be reverted.
          "email": email,
          "password": password,
          "player_id": notificationToken,

          "fcm": fcm,
        },
      );

      if (response.statusCode == 200) {
        // AuthController@login returns a flat body:
        //   { message, access_token, token_type, user }
        // There is no `data` envelope and no Authorization response header.
        var result = json.decode(response.data);
        User user = userFromJson(json.encode(result['user']));
        user.token = result['access_token'];
        return Right(user);
      } else if (response.statusCode == 500) {
        return Left(ServerFailure());
      } else {
        var result = json.decode(response.data);
        return Left(ResultFailure(result['message']));
      }
    } on DioException catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout ||
          ex.type == DioExceptionType.sendTimeout ||
          ex.type == DioExceptionType.receiveTimeout ||
          ex.type == DioExceptionType.unknown) {
        return Left(ConnectionFailure());
      } else {
        return Left(GlobalFailure());
      }
    } on Failure catch (e) {
      print(e);
      return Left(e);
    } catch (e) {
      print(e);
      return Left(GlobalFailure());
    }
  }

  // ---------------------------------------------------------------------------
  // Mock path.
  //
  // Auth is the one feature where the mock cannot be faithful, and it is worth
  // being explicit about why: there are no password hashes in the seed and
  // nothing to check one against, so **the password is not verified**. Any
  // non-empty password signs the matching email in.
  //
  // What IS faithful is the part the rest of the app depends on: which user you
  // become. Signing in as `ahmad@example.com` gives the parent — the family
  // list, the spending-limit controls, the alerts panel — and signing in as
  // `nour@example.com` gives a member, whose dashboard draws a ceiling instead
  // and whose profile screen hides the controls a member may not use. An
  // unknown address is rejected, so the failure path renders too.
  //
  // A mock that logged everybody in as the same user would leave every
  // role-dependent branch in the app permanently untested.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, User>> _mockLogin({
    required String email,
    required String password,
  }) async {
    await Future.delayed(mockDelay);

    if (password.isEmpty) {
      return Left(ResultFailure('auth.error_invalid_credentials'.tr()));
    }

    final needle = email.trim().toLowerCase();
    for (final user in MockStore.instance.users) {
      if ((user.email ?? '').toLowerCase() == needle) {
        return Right(_asSession(user));
      }
    }

    return Left(ResultFailure('auth.error_invalid_credentials'.tr()));
  }

  Future<Either<Failure, User>> _mockRegister({
    required String name,
    required String email,
    required AccountRole role,
  }) async {
    await Future.delayed(mockDelay);

    final store = MockStore.instance;
    if (store.emailTaken(email)) {
      // The server enforces this with `unique:users,email`; without it here the
      // family list would grow duplicate rows that login then picks between
      // arbitrarily.
      return Left(ResultFailure('auth.error_email_taken'.tr()));
    }

    final user = User(
      id: store.allocateUserId(),
      name: name,
      email: email,
      role: role.apiValue,
      // No ceiling. `AuthController::register` does not set one either — a
      // parent grants it afterwards, deliberately, so a member cannot pick
      // their own.
    );

    store.addUser(user);
    return Right(_asSession(user));
  }

  /// The signed-in copy of [user], carrying [mockToken].
  ///
  /// A copy rather than the stored object: `LocalsApp.user` is handed out
  /// widely and is mutated in places (`user.token = ...`), and the store's row
  /// must not change identity underneath the family list because a screen
  /// assigned to the session object.
  static User _asSession(User user) {
    final session = user.copyWith();
    session.token = mockToken;
    return session;
  }
}
