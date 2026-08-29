part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the full-screen loader.
class OnLoadNotifications extends NotificationsEvent {
  const OnLoadNotifications();
}

/// Pull-to-refresh. Starts over from page 1 while keeping the rows on screen.
class OnRefreshNotifications extends NotificationsEvent {
  const OnRefreshNotifications();
}

/// The list reached its end. Ignored when a page is already in flight or the
/// last page has been reached.
class OnLoadMoreNotifications extends NotificationsEvent {
  const OnLoadMoreNotifications();
}

class OnMarkNotificationRead extends NotificationsEvent {
  final int id;

  const OnMarkNotificationRead(this.id);

  @override
  List<Object?> get props => <Object?>[id];
}

/// Marks everything read.
///
/// Dispatched from a button, deliberately **not** automatically on open: the
/// previous implementation fired it as soon as the list loaded, which meant a
/// user who glanced at the screen lost the ability to see which alerts were new.
class OnMarkAllNotificationsRead extends NotificationsEvent {
  const OnMarkAllNotificationsRead();
}

class OnDeleteNotification extends NotificationsEvent {
  final int id;

  const OnDeleteNotification(this.id);

  @override
  List<Object?> get props => <Object?>[id];
}
