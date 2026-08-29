import 'package:easy_localization/easy_localization.dart';

/// Number and date formatting for the dashboard.
///
/// The design uses Western Arabic numerals ("12,450.00", "10:30") even in the
/// Arabic layout, so every formatter is pinned to the `en` locale. Only the
/// surrounding words are translated.
class DashboardFormatter {
  const DashboardFormatter._();

  /// "12,450.00" — grouped, always two decimals.
  static String amount(num? value) {
    final v = value ?? 0;
    return NumberFormat('#,##0.00', 'en').format(v);
  }

  /// "8,500" — grouped, no decimals unless the value actually has them.
  /// Used by the compact stat cards, which show "8,500" not "8,500.00".
  static String compactAmount(num? value) {
    final v = value ?? 0;
    if (v % 1 == 0) return NumberFormat('#,##0', 'en').format(v);
    return NumberFormat('#,##0.00', 'en').format(v);
  }

  /// A signed transaction amount: "-245.50" / "+1,200.00".
  ///
  /// The sign is written before the digits deliberately. In an RTL paragraph a
  /// leading "-" would otherwise be reordered to the visual right of the
  /// number; wrapping the result in an LTR isolate keeps "-245.50" reading
  /// correctly in both directions.
  static String signedAmount(num? value, {required bool isExpense}) {
    final sign = isExpense ? '-' : '+';
    return '\u2066$sign${amount(value)}\u2069';
  }

  /// "0%" .. "100%" for the chart legend.
  static String percent(double fraction) {
    return NumberFormat.percentPattern('en').format(fraction);
  }

  /// The transaction subtitle: "اليوم، 10:30 ص".
  ///
  /// [dateTime] should be `TransactionModel.displayedAt`. Note that the
  /// `transactions.date` column is date-only, so a row with no `created_at`
  /// falls back to midnight — see the model's field docs.
  static String relativeDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);

    final String day;
    if (that == today) {
      day = 'dashboard.today'.tr();
    } else if (that == today.subtract(const Duration(days: 1))) {
      day = 'dashboard.yesterday'.tr();
    } else {
      day = DateFormat('yyyy/MM/dd', 'en').format(local);
    }

    return '$day، ${_time(local)}';
  }

  // ---------------------------------------------------------------------------
  // Transactions feature. APPEND-ONLY: nothing above this line changed, because
  // the dashboard already depends on it.
  //
  // These live here rather than in a second formatter so the two features can
  // never drift apart on how a number or a date is written. The class keeps its
  // name for now; renaming it is a separate cleanup, not this feature's job.
  // ---------------------------------------------------------------------------

  /// "14:30" — 24-hour clock, no meridiem.
  ///
  /// The transactions list design writes times as "14:30" / "08:00" / "19:15",
  /// unlike the dashboard rows, which use the 12-hour "10:30 ص" form. Both are
  /// reproduced rather than unified, because both come from the design files.
  ///
  /// Wrapped in an LTR isolate so "14:30" is not reordered inside an RTL
  /// paragraph.
  ///
  /// TODO(backend): the only column carrying a time-of-day is `created_at`, the
  /// row's insert timestamp — `transactions.date` is SQL `DATE`. So a back-dated
  /// transaction shows the time it was entered, not the time it happened.
  /// Rendering this truthfully needs `date` promoted to `DATETIME`, or a
  /// separate time column.
  static String timeOfDay(DateTime? dateTime) {
    if (dateTime == null) return '';
    final DateTime local = dateTime.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '\u2066$hour:$minute\u2069';
  }

  /// The day separator above each group: "اليوم، 24 مايو", "أمس، 23 مايو", or
  /// plain "20 مايو" for anything older.
  ///
  /// The month name is read from the translation files rather than from
  /// `DateFormat('MMMM', 'ar')`, because `initializeDateFormatting` is never
  /// called in `main()` — the same reason [_time] hand-rolls its meridiem.
  static String dayHeader(DateTime? day) {
    if (day == null) return '';
    final DateTime local = day.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime that = DateTime(local.year, local.month, local.day);

    // Digits stay Western, matching every other number in the app.
    final String dayNumber = NumberFormat('0', 'en').format(local.day);
    final String monthName = 'months.${local.month}'.tr();
    final String dateLabel = '\u2066$dayNumber\u2069 $monthName';

    if (that == today) {
      return '${'dashboard.today'.tr()}، $dateLabel';
    }
    if (that == today.subtract(const Duration(days: 1))) {
      return '${'dashboard.yesterday'.tr()}، $dateLabel';
    }
    return dateLabel;
  }

  /// The full date shown on the form's date row: "اليوم، 24 مايو 2025".
  ///
  /// Same construction as [dayHeader] plus the year, which the form needs
  /// because it can reach arbitrarily far back.
  static String fullDate(DateTime? day) {
    if (day == null) return '';
    final DateTime local = day.toLocal();
    final String year = NumberFormat('0000', 'en').format(local.year);
    return '${dayHeader(local)} \u2066$year\u2069';
  }

  // ---------------------------------------------------------------------------
  // Budgets feature. APPEND-ONLY, for the same reason as the block above:
  // nothing here changed, and these live alongside the existing formatters so
  // the three features can never drift apart on how a number or date is written.
  // ---------------------------------------------------------------------------

  /// The month selector's label: "مايو 2024".
  ///
  /// The month name comes from the translation files, and the year stays in
  /// Western digits inside an LTR isolate — the same construction as [dayHeader]
  /// and for the same reason (`initializeDateFormatting` is never called).
  static String monthYear(DateTime? month) {
    if (month == null) return '';
    final DateTime local = month.toLocal();
    final String monthName = 'months.${local.month}'.tr();
    final String year = NumberFormat('0000', 'en').format(local.year);
    return '$monthName \u2066$year\u2069';
  }

  /// A plain calendar date: "24 مايو 2025".
  ///
  /// Unlike [fullDate] this never prefixes "اليوم" or "أمس". The budget form's
  /// two date fields sit side by side, where a relative prefix would both
  /// overflow and read oddly against a period's start and end.
  static String plainDate(DateTime? day) {
    if (day == null) return '';
    final DateTime local = day.toLocal();
    final String dayNumber = NumberFormat('0', 'en').format(local.day);
    final String monthName = 'months.${local.month}'.tr();
    final String year = NumberFormat('0000', 'en').format(local.year);
    return '\u2066$dayNumber\u2069 $monthName \u2066$year\u2069';
  }

  /// "10:30 ص" — 12-hour clock with a localised meridiem.
  ///
  /// `DateFormat.jm()` is not used because its Arabic meridiem depends on
  /// locale data that is not guaranteed to be loaded here, and the design shows
  /// a specific "ص"/"م" form.
  static String _time(DateTime local) {
    final isAm = local.hour < 12;
    var hour = local.hour % 12;
    if (hour == 0) hour = 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final meridiem = isAm ? 'dashboard.am'.tr() : 'dashboard.pm'.tr();
    return '\u2066$hour:$minute\u2069 $meridiem';
  }
}
