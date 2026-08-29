import 'package:easy_localization/easy_localization.dart';

class StringFormatter {
  static price(num? price) {
    if (price == null) {
      return "unknown".tr();
    } else if (price == 0) {
      return "free".tr();
    } else {
      final formatter = NumberFormat.decimalPattern();
      return "${formatter.format(num.tryParse(price.toStringAsFixed(2)))} \$";
    }
  }

  static bool isFirstCharCapital(String s) {
    if (s.isEmpty) return false;
    return RegExp(r'^[A-Z]').hasMatch(s);
  }

  static String formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
