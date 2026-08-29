import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the notifications feature needs, independent of where the data lives.
///
/// This replaces the previous contract, which returned a `(List, int)` record
/// of rows plus a per-page number parsed from a `pagination` envelope no
/// controller in this project produces. [NotificationsPage] carries the page
/// counters and the unread total the app-bar badge needs.
abstract class NotificationsDomain {
  /// One page, newest first. [page] is 1-based.
  Future<Either<Failure, NotificationsPage>> getNotifications(int page);

  /// Marks one notification read. The server scopes the lookup by owner, so a
  /// guessed id belonging to another family member answers 404.
  Future<Either<Failure, bool>> markAsRead(int id);

  /// Marks every unread notification read.
  Future<Either<Failure, bool>> markAllAsRead();

  /// Deletes one notification.
  Future<Either<Failure, bool>> delete(int id);
}
