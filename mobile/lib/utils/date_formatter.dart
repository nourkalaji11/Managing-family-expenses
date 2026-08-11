import 'package:easy_localization/easy_localization.dart';

extension DateFormatter on DateTime {
  String formatDate({String format = 'yyyy/MM/dd'}) {
    return DateFormat(format, "en").format(toLocal());
  }

  String formatDateTime() {
    String format = 'yyyy/MM/dd HH:mm';
    return DateFormat(format, "en").format(toLocal());
  }

  String formatTime() {
    return DateFormat("HH:mm", "en").format(toLocal()).toLowerCase();
  }

  String formatTimeToUTC() {
    return DateFormat("HH:mm", "en").format(toUtc()).toLowerCase();
  }

  bool isSameDay(DateTime dateTime) {
    return dateTime.day == day &&
        dateTime.year == year &&
        dateTime.month == month;
  }

  bool isTwoMinutesBeforePassed(String time) {
    final parts = time.split(':');
    final targetTime = DateTime(
      year,
      month,
      day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // Subtract 2 minutes from the target time
    final twoMinutesBefore = targetTime.subtract(Duration(minutes: 2));

    // Compare current time with two minutes before

    return DateTime.now().toUtc().isAfter(twoMinutesBefore);
  }

  bool hasTimePassed(String timeString) {
    final parts = timeString.split(":");
    final inputTime = DateTime.utc(
      year,
      month,
      day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    return DateTime.now().toUtc().isAfter(inputTime);
  }

  getLastDayOfMonth() {
    final beginningOfNextMonth = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return beginningOfNextMonth.subtract(const Duration(days: 1));
  }

  int getRemainingSeconds() {
    final nowUtc = DateTime.now().toUtc();

    final diff = difference(nowUtc);

    return diff.inSeconds;
  }
}
