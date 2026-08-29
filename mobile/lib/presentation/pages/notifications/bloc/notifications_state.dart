part of 'notifications_bloc.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => <Object?>[];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  /// Every page fetched so far, in order. Appended to, not replaced — this is
  /// the only paginated list in the app.
  final List<AppNotification> items;

  final int currentPage;
  final int lastPage;

  /// Server-side total across every page, used for the empty check rather than
  /// `items.length`, which only describes what has been fetched.
  final int total;

  /// Unread across the whole collection, not just the loaded pages. Drives the
  /// app-bar badge.
  final int unreadCount;

  /// True while a *next* page is in flight. Separate from the initial load, so
  /// the screen shows a footer spinner instead of replacing the list.
  final bool isLoadingMore;

  const NotificationsLoaded({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.unreadCount = 0,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  bool get isEmpty => items.isEmpty;

  // ---------------------------------------------------------------------------
  // Optimistic transitions. Each returns the state as it will be if the write
  // succeeds; the bloc re-emits the previous state on failure, so the badge can
  // never drift from the server's count.
  // ---------------------------------------------------------------------------

  /// Marks one row read and decrements the badge, but only if it was unread —
  /// tapping an already-read row must not push the count negative.
  NotificationsLoaded markingRead(int id) {
    bool wasUnread = false;
    final List<AppNotification> next = [
      for (final n in items)
        if (n.id == id && !n.seen)
          () {
            wasUnread = true;
            return n.asSeen();
          }()
        else
          n,
    ];

    return copyWith(
      items: next,
      unreadCount: wasUnread ? unreadCount - 1 : unreadCount,
    );
  }

  NotificationsLoaded markingAllRead() => copyWith(
    items: [for (final n in items) n.asSeen()],
    unreadCount: 0,
  );

  /// Removes one row, decrementing both the total and — if it was unread — the
  /// badge.
  NotificationsLoaded removing(int id) {
    bool wasUnread = false;
    final List<AppNotification> next = <AppNotification>[];
    for (final n in items) {
      if (n.id == id) {
        wasUnread = !n.seen;
        continue;
      }
      next.add(n);
    }

    return copyWith(
      items: next,
      total: total > 0 ? total - 1 : 0,
      unreadCount: wasUnread && unreadCount > 0 ? unreadCount - 1 : unreadCount,
    );
  }

  NotificationsLoaded copyWith({
    List<AppNotification>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    int? unreadCount,
    bool? isLoadingMore,
  }) => NotificationsLoaded(
    items: items ?? this.items,
    currentPage: currentPage ?? this.currentPage,
    lastPage: lastPage ?? this.lastPage,
    total: total ?? this.total,
    unreadCount: unreadCount ?? this.unreadCount,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  // `items` is rebuilt as a new list on every transition, so identity is what
  // distinguishes two states — same reasoning as the other loaded states.
  @override
  List<Object?> get props => <Object?>[
    items,
    currentPage,
    lastPage,
    total,
    unreadCount,
    isLoadingMore,
  ];
}

class NotificationsFailure extends NotificationsState {
  final Failure error;

  const NotificationsFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
