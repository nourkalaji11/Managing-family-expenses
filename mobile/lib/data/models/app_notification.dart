/// Mirrors the `app_notifications` table.
///
///     app_notifications (id, user_id, type, title, message,
///                        data JSON NULL, seen BOOL, created_at, updated_at)
///
/// Replaces the previous `CustomNotification`, which was carried over from the
/// template this project started from: it modelled `booking_id`, `post_id`,
/// `expert_name`, `follower_id` and `liker_name`, none of which exist in a
/// family-expenses backend. Keeping it would have meant parsing a contract no
/// server produces.
class AppNotification {
  final int? id;

  /// One of [NotificationType]'s wire values. Kept as the raw string as well as
  /// the parsed enum so an unrecognised type from a newer server still round
  /// trips rather than being lost.
  final String? rawType;

  final String? title;
  final String? message;

  /// The `data` JSON column. Its shape depends on [type] — a
  /// `budget_exceeded` row carries `budget_id`, `category`, `limit` and
  /// `spent`, while `limit_blocked` carries `attempted` and `remaining`.
  ///
  /// Deliberately left as a raw map rather than modelled per type: nothing in
  /// the UI reads it today, and inventing five payload classes for a field the
  /// screen does not render would be contract nobody uses.
  final Map<String, dynamic>? data;

  final bool seen;
  final DateTime? createdAt;

  const AppNotification({
    this.id,
    this.rawType,
    this.title,
    this.message,
    this.data,
    this.seen = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json["id"],
        rawType: json["type"],
        title: json["title"],
        message: json["message"],
        data: json["data"] is Map<String, dynamic> ? json["data"] : null,
        // The server casts this to a real bool, but SQLite-backed payloads have
        // been seen to send 0/1 — both are accepted rather than assumed.
        seen: _toBool(json["seen"]),
        createdAt: _toDate(json["created_at"]),
      );

  /// The parsed type, falling back to [NotificationType.general] for anything
  /// this build does not know about.
  NotificationType get type => NotificationTypeX.fromWire(rawType);

  /// Returns a copy marked read, so the list can update one row without
  /// refetching the page.
  AppNotification asSeen() => AppNotification(
    id: id,
    rawType: rawType,
    title: title,
    message: message,
    data: data,
    seen: true,
    createdAt: createdAt,
  );
}

/// The notification kinds the backend emits, from `AppNotification`'s constants.
///
/// [general] is not a server value: it is the fallback for a type this build
/// has never heard of, so a newer server can add one without this screen
/// throwing or rendering a blank row.
enum NotificationType {
  budgetExceeded('budget_exceeded'),
  limitBlocked('limit_blocked'),
  memberSpent('member_spent'),
  limitUpdated('limit_updated'),
  general('');

  final String wire;

  const NotificationType(this.wire);
}

extension NotificationTypeX on NotificationType {
  static NotificationType fromWire(String? value) {
    if (value == null) return NotificationType.general;
    for (final t in NotificationType.values) {
      if (t.wire == value) return t;
    }
    return NotificationType.general;
  }
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

/// One page of notifications plus the counters the app bar badge needs.
///
/// `unread_count` is deliberately server-computed over the **whole** collection,
/// not the current page: the badge means "unread for you", not "unread on this
/// screen".
class NotificationsPage {
  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int unreadCount;

  const NotificationsPage({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.unreadCount = 0,
  });

  bool get hasMore => currentPage < lastPage;
}
