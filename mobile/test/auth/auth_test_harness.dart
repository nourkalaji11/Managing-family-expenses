import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/utils/service_locator.dart';

/// Shared setup for the authentication widget tests.
///
/// Note on assertions: `EasyLocalization` is not initialised in these tests, so
/// `"some.key".tr()` returns the key itself rather than the Arabic string. The
/// tests therefore assert on translation keys (e.g. `auth.error_email_required`)
/// and on widget keys, which keeps them independent of copy changes.
Widget wrapForTest(Widget child, {Map<String, WidgetBuilder>? routes}) {
  return ScreenUtilInit(
    designSize: const Size(412, 917),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(textDirection: TextDirection.rtl, child: child),
      routes: routes ?? AppRoutes.routes,
    ),
  );
}

/// GetIt throws on duplicate registration, so every test starts from a clean
/// container.
void resetLocator() {
  getIt.reset();
  setupServiceLocator();
}
