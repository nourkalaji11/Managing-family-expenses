part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class OnFetchNotifications extends NotificationsEvent {
  const OnFetchNotifications();

  @override
  List<Object> get props => [];
}

class OnFetchMoreNotifications extends NotificationsEvent {
  final int page;
  const OnFetchMoreNotifications(this.page);

  @override
  List<Object> get props => [];
}

class OnMarkAsRead extends NotificationsEvent {
  final int id;
  const OnMarkAsRead(this.id);

  @override
  List<Object> get props => [id];
}

class OnMarkAllAsRead extends NotificationsEvent {
  const OnMarkAllAsRead();

  @override
  List<Object> get props => [];
}
