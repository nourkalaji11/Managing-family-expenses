import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/data/mock/mock_config.dart';
import 'package:family_expense_management/data/mock/mock_store.dart';
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
  static const bool useMock = kUseMockData;

  static const Duration mockDelay = Duration(milliseconds: 450);
  static const Duration mockWriteDelay = Duration(milliseconds: 250);

  static const int pageSize = 20;

  @override
  Future<Either<Failure, NotificationsPage>> getNotifications(int page) async {
    if (useMock) return _mockGet(page);

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
    if (useMock)
      return _mockWrite(() => MockStore.instance.markNotificationRead(id));

    return _write(RequestType.post, GlobalApiEndpoint.markAsRead[[id]]);
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead() async {
    if (useMock) {
      return _mockWrite(() {
        MockStore.instance.markAllNotificationsRead();
        // Always succeeds, including when nothing was unread — the server
        // answers 200 in that case too rather than treating it as an error.
        return true;
      });
    }

    return _write(RequestType.post, GlobalApiEndpoint.markAllAsRead.endpoint);
  }

  @override
  Future<Either<Failure, bool>> delete(int id) async {
    if (useMock)
      return _mockWrite(() => MockStore.instance.removeNotification(id));

    return _write(RequestType.delete, GlobalApiEndpoint.notificationById[[id]]);
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

  // ---------------------------------------------------------------------------
  // Mock path. Paginated locally, because the page counters are what the list
  // screen's infinite scroll reads — a mock that returned everything in one
  // page would leave that path unexercised.
  // ---------------------------------------------------------------------------

  Future<Either<Failure, NotificationsPage>> _mockGet(int page) async {
    await Future.delayed(mockDelay);

    final store = MockStore.instance;
    final viewerId = store.signedInUser?.id;

    // Addressed to this person only. The server never returns anybody else's
    // rows, so the live path needs no filter; the mock keeps one list for the
    // whole family and would otherwise show a child the copy written to their
    // parent — revealing both that the parent was told and what they were told.
    //
    // A null `userId` is a seeded row that predates addressing: shown to
    // everyone rather than hidden from everyone.
    //
    // Newest first. The store keeps insertion order and prepends, so this sort
    // is what guarantees the seed and anything added since interleave correctly
    // by time rather than by when they happened to be written.
    final all =
        [
          for (final n in store.notifications)
            if (n.userId == null || n.userId == viewerId) n,
        ]..sort((a, b) {
          final x = a.createdAt, y = b.createdAt;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return y.compareTo(x);
        });

    final total = all.length;
    // At least 1, so an empty list reports page 1 of 1 rather than 1 of 0 —
    // `hasMore` would otherwise read as true forever on an empty inbox.
    final lastPage = total == 0 ? 1 : ((total - 1) ~/ pageSize) + 1;
    final current = page < 1 ? 1 : (page > lastPage ? lastPage : page);

    final start = (current - 1) * pageSize;
    final end = (start + pageSize) > total ? total : (start + pageSize);

    return Right(
      NotificationsPage(
        items: start >= total ? const [] : all.sublist(start, end),
        currentPage: current,
        lastPage: lastPage,
        total: total,
        unreadCount: store.unreadNotificationCount,
      ),
    );
  }

  /// Runs [write] against the store and maps a false return to the server's
  /// 404 — a notification id that matches nothing is an error, not a no-op.
  Future<Either<Failure, bool>> _mockWrite(bool Function() write) async {
    await Future.delayed(mockWriteDelay);

    if (!write()) {
      return Left(ResultFailure('notifications_page.error_not_found'.tr()));
    }
    return const Right(true);
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
