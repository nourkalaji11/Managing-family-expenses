import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/custom_notification.dart';
import 'package:family_expense_management/network/failure.dart';

abstract class NotificationsDomain {
  Future<Either<Failure, (List<CustomNotification>, int)>> getNotifications(
    int page,
  );
  Future<Either<Failure, bool>> markAsRead(int id);
  Future<Either<Failure, bool>> markAllAsRead();
}
