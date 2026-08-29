import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/models/custom_notification.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/notifications/domain/notifications_domain.dart';

class NotificationsRepo extends NotificationsDomain {
  static DioClient client = DioClient();

  @override
  Future<Either<Failure, (List<CustomNotification>, int)>> getNotifications(
    int page,
  ) async {
    try {
      final response = await client.request(
        requestType: RequestType.get,
        path: GlobalApiEndpoint.notifications.endpoint,
        queryParameters: {"page": page},
      );

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 200) {
        var result = json.decode(response.data);
        var perPage = result['pagination']['per_page'];
        var s = result['data'] as List;
        var data = s
            .map((e) => customNotificationFromJson(json.encode(e)))
            .toList();
        return Right((data, perPage));
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
  Future<Either<Failure, bool>> markAsRead(int id) async {
    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.markAsRead[[id]],
      );

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 200) {
        return Right(true);
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
  Future<Either<Failure, bool>> markAllAsRead() async {
    try {
      final response = await client.request(
        requestType: RequestType.post,
        path: GlobalApiEndpoint.markAllAsRead.endpoint,
      );

      print(response.statusCode);
      print(response.data);
      if (response.statusCode == 200) {
        return Right(true);
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
