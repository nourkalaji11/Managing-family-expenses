part of 'notifications_bloc.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object> get props => [];
}

final class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsFailure extends NotificationsState {
  final Failure error;

  const NotificationsFailure(this.error);

  @override
  List<Object> get props => [error];
}

class FetchNotificationsSuccess extends NotificationsState {
  final List<CustomNotification> notifications;
  final bool hasReachedMax;
  final int now;
  const FetchNotificationsSuccess(
    this.notifications,
    this.hasReachedMax,
    this.now,
  );

  @override
  List<Object> get props => [notifications, hasReachedMax, now];
}

class MarkAsReadSuccess extends NotificationsState {}
