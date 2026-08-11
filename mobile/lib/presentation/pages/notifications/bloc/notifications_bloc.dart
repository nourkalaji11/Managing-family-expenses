import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/custom_notification.dart';
import 'package:family_expense_management/data/repos/notifications_repo.dart';
import 'package:family_expense_management/network/failure.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  int currentPage = 1;
  NotificationsBloc() : super(NotificationsInitial()) {
    on<NotificationsEvent>((event, emit) async {
      if (event is OnFetchNotifications) {
        emit(NotificationsLoading());
        final result = await NotificationsRepo().getNotifications(1);
        currentPage = 1;
        result.fold(
          (left) {
            emit(NotificationsFailure(left));
          },
          (right) {
            emit(
              FetchNotificationsSuccess(
                right.$1,
                right.$1.length < right.$2,
                1,
              ),
            );
          },
        );
      }

      if (event is OnFetchMoreNotifications) {
        final result = await NotificationsRepo().getNotifications(event.page);
        currentPage++;
        result.fold(
          (left) {
            emit(NotificationsFailure(left));
          },
          (right) {
            var data = (state as FetchNotificationsSuccess).notifications;
            data.addAll(right.$1);
            emit(
              FetchNotificationsSuccess(
                data,
                right.$1.length < right.$2,
                event.page,
              ),
            );
          },
        );
      }

      if (event is OnMarkAsRead) {
        emit(NotificationsLoading());
        final result = await NotificationsRepo().markAsRead(event.id);
        result.fold(
          (left) {
            emit(NotificationsFailure(left));
          },
          (right) {
            emit(MarkAsReadSuccess());
          },
        );
      }

      if (event is OnMarkAllAsRead) {
        emit(NotificationsLoading());
        final result = await NotificationsRepo().markAllAsRead();
        result.fold(
          (left) {
            emit(NotificationsFailure(left));
          },
          (right) {
            emit(MarkAsReadSuccess());
          },
        );
      }
    });
  }
}
