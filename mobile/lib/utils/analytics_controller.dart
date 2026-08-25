import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsController {
  /// `Firebase.initializeApp` is allowed to fail at startup (see `main`), so a
  /// default app is not guaranteed to exist. Touching `FirebaseAnalytics
  /// .instance` without one throws `[core/no-app]`, and because the first call
  /// site is `DashboardScreen.initState` that surfaces as an unhandled
  /// exception during a widget build. Analytics is non-essential, so every
  /// entry point degrades to a no-op instead.
  static bool get _available => Firebase.apps.isNotEmpty;

  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_available) return;
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  static Future<void> setUserId(String userId) async {
    if (!_available) return;
    await FirebaseAnalytics.instance.setUserId(id: userId);
  }
}
