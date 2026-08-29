import 'package:flutter/material.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/style/colors.dart';

/// Icon and tint per notification kind.
///
/// Keyed by the server's own `type` enum rather than by parsing the title, so a
/// wording change on the backend cannot silently repaint every row.
///
/// Unlike `CategoryVisuals` and `AccountVisuals`, this lookup is **not** a
/// stand-in for a missing column: `app_notifications.type` exists precisely so
/// the client can style rows without reading the message.
class NotificationVisuals {
  const NotificationVisuals._();

  static IconData iconFor(NotificationType type) => switch (type) {
    NotificationType.budgetExceeded => Icons.pie_chart_outline,
    NotificationType.limitBlocked => Icons.block_outlined,
    NotificationType.memberSpent => Icons.receipt_long_outlined,
    NotificationType.limitUpdated => Icons.tune_outlined,
    NotificationType.general => Icons.notifications_none,
  };

  /// The ink for the glyph.
  ///
  /// Only the two kinds that report something going wrong are red. A member
  /// simply recording an expense is routine, and painting it red would train
  /// the user to ignore the colour that matters.
  static Color inkFor(NotificationType type) => switch (type) {
    NotificationType.budgetExceeded => ColorsApp.errorRed,
    NotificationType.limitBlocked => ColorsApp.errorRed,
    NotificationType.memberSpent => ColorsApp.primaryGreenPressed,
    NotificationType.limitUpdated => ColorsApp.dashboardBlue,
    NotificationType.general => ColorsApp.onSurfaceVariant,
  };

  /// The tile behind the glyph: the ink at low opacity, so every row stays
  /// legible against the white card.
  static Color tintFor(NotificationType type) =>
      inkFor(type).withValues(alpha: 0.12);
}
