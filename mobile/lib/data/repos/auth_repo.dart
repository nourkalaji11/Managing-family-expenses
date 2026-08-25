import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/auth/domain/auth_domain.dart';

class AuthRepo extends AuthDomain {
  static DioClient client = DioClient();
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

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        var result = json.decode(response.data);
        User user = userFromJson(json.encode(result['data']));
        user.token = response.headers['authorization']?.first;
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
  Future<Either<Failure, bool>> sendOTP({
    required LoginProvider provider,
    required String emailORphone,
  }) async {
    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.sendOTP.endpoint,
        body: {
          if (provider == LoginProvider.phone) "phone": emailORphone,
          if (provider == LoginProvider.email) "email": emailORphone,
        },
      );

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 200) {
        return const Right(true);
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
  Future<Either<Failure, User>> verifyOTP({
    required LoginProvider provider,
    required String emailORphone,
    required String otp,
    required String deviceToken,
  }) async {
    try {
      String fcm = await LocalStorage().getFCMToken();
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.verifyOTP.endpoint,
        body: {
          if (provider == LoginProvider.phone) "phone": emailORphone,
          if (provider == LoginProvider.email) "email": emailORphone,
          "otp": otp,
          "player_id": deviceToken,
          "fcm": fcm,
        },
      );

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 200) {
        var result = json.decode(response.data);
        User user = userFromJson(json.encode(result['data']['user']));
        user.token = response.headers['authorization']?.first;
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
  Future<Either<Failure, String>> social({
    required LoginProvider provider,
    required String token,
    required String? fullName,
    required String? secretToken,
    required String? notificationToken,
    String? referralCode,
  }) async {
    try {
      String fcm = await LocalStorage().getFCMToken();
      var fields = {
        "type": "User",
        "full_name": fullName,
        "token": token,
        if (secretToken != null) "secret_token": secretToken,
        "provider": provider.name,
        "player_id": notificationToken,
        "referral_code": referralCode,
        'fcm': fcm,
      };

      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.social.endpoint,
        body: fields,
      );

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 200) {
        return Right(response.headers['authorization']?.first as String);
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

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 200) {
        var result = json.decode(response.data);
        User user = userFromJson(json.encode(result['data']['user']));
        user.token = response.headers['authorization']?.first;
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
}
