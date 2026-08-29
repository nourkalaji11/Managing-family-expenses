import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The full-screen loader used while a feature's first load is in flight.
///
/// Deliberately not `DefaultLoader`: that shared widget depends on
/// `flutter_spinkit`, which is not declared in pubspec.yaml.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: ColorsApp.primaryGreenPressed,
        strokeWidth: 3,
      ),
    );
  }
}

/// The full-screen error state, with a retry action.
///
/// Deliberately not the shared `ErrorMessage`: it renders `assets/images/*.svg`,
/// and this repository ships no `assets/images/`.
///
/// The transactions screen carries private copies of both views; they predate
/// this file, and folding them in is a separate cleanup rather than a change to
/// a finished feature.
class AppFailureView extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  /// Distinguishes this view's retry button in widget tests.
  final Key? retryKey;

  const AppFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.retryKey,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40.r,
              color: ColorsApp.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              failure.message,
              style: TextStyleApp.dashboardStatLabel,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton(
              key: retryKey,
              onPressed: onRetry,
              child: Text(
                'dashboard.retry'.tr(),
                style: TextStyleApp.dashboardSectionAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
