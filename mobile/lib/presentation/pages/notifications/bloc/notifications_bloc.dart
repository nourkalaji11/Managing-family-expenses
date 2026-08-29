import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/data/repos/notifications_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/notifications/domain/notifications_domain.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Owns the notifications list: paging, and the read/delete writes.
///
/// The only paginated feature in the app — see `NotificationsRepo` for why.
/// That makes this the only bloc that has to hold "what I have so far" and
/// append, rather than replacing its list on every load.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsDomain _repo;

  NotificationsBloc({NotificationsDomain? repo})
    : _repo = repo ?? NotificationsRepo(),
      super(const NotificationsInitial()) {
    on<NotificationsEvent>((event, emit) async {
      if (event is OnLoadNotifications) {
        emit(const NotificationsLoading());
        await _loadFirstPage(emit);
      } else if (event is OnRefreshNotifications) {
        // Pull-to-refresh keeps the current rows on screen and starts over from
        // page 1, so a notification that arrived meanwhile lands at the top
        // instead of being appended below older ones.
        await _loadFirstPage(emit);
      } else if (event is OnLoadMoreNotifications) {
        await _loadNextPage(emit);
      } else if (event is OnMarkNotificationRead) {
        await _markRead(emit, event.id);
      } else if (event is OnMarkAllNotificationsRead) {
        await _markAllRead(emit);
      } else if (event is OnDeleteNotification) {
        await _delete(emit, event.id);
      }
    });
  }

  Future<void> _loadFirstPage(Emitter<NotificationsState> emit) async {
    final result = await _repo.getNotifications(1);
    result.fold((failure) => emit(NotificationsFailure(failure)), (page) {
      emit(
        NotificationsLoaded(
          items: page.items,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          unreadCount: page.unreadCount,
        ),
      );
    });
  }

  Future<void> _loadNextPage(Emitter<NotificationsState> emit) async {
    final NotificationsState current = state;
    if (current is! NotificationsLoaded) return;

    // Guards a scroll listener firing repeatedly at the bottom of the list:
    // without it every frame at the end would start another request for the
    // same page.
    if (current.isLoadingMore || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final result = await _repo.getNotifications(current.currentPage + 1);
    result.fold(
      // A failed *next* page must not discard the pages already on screen, so
      // this clears the spinner and leaves the list intact rather than emitting
      // a failure state.
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(
        current.copyWith(
          items: [...current.items, ...page.items],
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          unreadCount: page.unreadCount,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> _markRead(Emitter<NotificationsState> emit, int id) async {
    final NotificationsState current = state;
    if (current is! NotificationsLoaded) return;

    // Optimistic: the row greys out immediately. A failure re-emits the
    // previous state, so the badge cannot drift away from the server's count.
    emit(current.markingRead(id));

    final result = await _repo.markAsRead(id);
    result.fold((_) => emit(current), (_) {});
  }

  Future<void> _markAllRead(Emitter<NotificationsState> emit) async {
    final NotificationsState current = state;
    if (current is! NotificationsLoaded) return;
    if (current.unreadCount == 0) return;

    emit(current.markingAllRead());

    final result = await _repo.markAllAsRead();
    result.fold((_) => emit(current), (_) {});
  }

  Future<void> _delete(Emitter<NotificationsState> emit, int id) async {
    final NotificationsState current = state;
    if (current is! NotificationsLoaded) return;

    emit(current.removing(id));

    final result = await _repo.delete(id);
    result.fold((_) => emit(current), (_) {});
  }
}
