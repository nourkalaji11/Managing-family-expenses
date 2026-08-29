import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/network/api_envelope.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_client.dart';
import 'package:family_expense_management/presentation/pages/notifications/domain/notifications_domain.dart';

/// The notifications feature's data source.
///
/// Rewritten against the real `app_notifications` endpoints. The previous
/// version read `result['pagination']['per_page']` and parsed a
/// `CustomNotification` carrying booking and follower fields — a contract from
/// the template this project started from, which no controller here produces.
///
/// Endpoint notes worth carrying at the call site:
///
///   * `GET /notifications` is the **only paginated** index in this API.
///     Everything else returns its whole collection, because everything else is
///     bounded; notifications grow with every expense a member records.
///   * The `meta.unread_count` is computed over the whole collection, not the
///     page, because the app-bar badge means "unread for you".
///   * `POST /notifications/{id}/read` scopes its lookup by owner, so a
///     notification belonging to another member answers 404 rather than being
///     silently marked.
class NotificationsRepo extends NotificationsDomain {
  static DioClient client = DioClient();

  /// Matches the server's default. The server caps `per_page` at 50.
  static const int pageSize = 20;

  @override
  Future<Either<Failure, NotificationsPage>> getNotifications(int page) async {
    try {
      final response = await client.request(
        requestType: RequestType.get,
        path: GlobalApiEndpoint.notifications.endpoint,
        queryParameters: {'page': page, 'per_page': pageSize},
      );

      // The page counters live in `meta`, beside `data` rather than inside it,
      // so this one endpoint reads the decoded body directly instead of going
      // through `unwrapList`. The status ladder is still shared: `unwrapList`
      // runs first and throws on any non-2xx before `meta` is touched.
      final items = [
        for (final json in unwrapList(response)) AppNotification.fromJson(json),
      ];

      final decoded = json.decode(response.data);
      final meta = decoded is Map<String, dynamic> ? decoded['meta'] : null;

      return Right(
        NotificationsPage(
          items: items,
          currentPage: _toInt(meta?['current_page'], fallback: page),
          lastPage: _toInt(meta?['last_page'], fallback: page),
          total: _toInt(meta?['total'], fallback: items.length),
          unreadCount: _toInt(meta?['unread_count']),
        ),
      );
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(int id) async {
    return _write(
      RequestType.post,
      GlobalApiEndpoint.markAsRead[[id]],
    );
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead() async {
    return _write(
      RequestType.post,
      GlobalApiEndpoint.markAllAsRead.endpoint,
    );
  }

  @override
  Future<Either<Failure, bool>> delete(int id) async {
    return _write(
      RequestType.delete,
      GlobalApiEndpoint.notificationById[[id]],
    );
  }

  /// The three write calls differ only in verb and path, so they share one body
  /// rather than three identical try/catch blocks.
  Future<Either<Failure, bool>> _write(RequestType type, String path) async {
    try {
      final response = await client.request(requestType: type, path: path);
      ensureSuccess(response);
      return const Right(true);
    } on DioException catch (ex) {
      return Left(_mapDioException(ex));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(GlobalFailure());
    }
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
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
