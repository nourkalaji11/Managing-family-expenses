import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

/// First screen of the app. Shows the brand while deciding where to go next.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Matches the splash delay in [_bootstrap] so the indicator completes
  /// exactly once before navigation happens.
  static const Duration _splashDuration = Duration(seconds: 2);

  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(_splashDuration);
    final String? token = await LocalStorage().getUser();
    if (!mounted) return;

    // TODO(backend): there is no `/me` (or equivalent) endpoint in
    // GlobalApiEndpoint that can turn a stored token back into a full `User`.
    // Dashboard dereferences `LocalsApp.user!.id`, and fabricating a
    // `User(token: token)` would either crash or ship fake user data, so a
    // stored session is deliberately NOT auto-restored yet: the user is sent to
    // the login screen instead. Once a profile endpoint exists, fetch it here,
    // assign `LocalsApp.user`, and route to `AppRoutes.dashboard` instead.
    if (token != null && token.isNotEmpty) {
      log(
        'A stored session token was found, but it cannot be restored until a '
        'profile endpoint exists. Routing to login.',
        name: 'SplashScreen',
      );
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorsApp.authBackground, Color(0xffEFF4FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Pushes the branding slightly below the exact centre, matching
              // the design.
              const Spacer(flex: 5),
              const _SplashBranding(),
              const Spacer(flex: 4),
              _SplashProgressBar(controller: _progressController),
              Spaces.height16,
              const _SplashTags(),
              Spaces.height50,
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashBranding extends StatelessWidget {
  const _SplashBranding();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 96.r,
          width: 96.r,
          decoration: BoxDecoration(
            color: ColorsApp.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14071A33),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 44.r,
            color: ColorsApp.navy,
          ),
        ),
        Spaces.height24,
        Text(
          "auth.splash_title".tr(),
          style: TextStyleApp.authSplashTitle,
          textAlign: TextAlign.center,
        ),
        Spaces.height4,
        Text(
          "auth.splash_subtitle".tr(),
          style: TextStyleApp.authSubtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Determinate indicator that fills once over the splash duration.
class _SplashProgressBar extends StatelessWidget {
  final AnimationController controller;

  const _SplashProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final double trackWidth = 140.w;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: trackWidth,
        height: 4.h,
        child: Stack(
          children: [
            Container(color: ColorsApp.progressTrack),
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Align(
                  // `centerStart` follows the ambient Directionality, so the
                  // bar grows from the right in RTL.
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: trackWidth * controller.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                height: 4.h,
                decoration: BoxDecoration(
                  color: ColorsApp.primaryGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashTags extends StatelessWidget {
  const _SplashTags();

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      height: 4.r,
      width: 4.r,
      decoration: const BoxDecoration(
        color: ColorsApp.primaryGreen,
        shape: BoxShape.circle,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("auth.splash_tag_secure".tr(), style: TextStyleApp.authSplashTag),
        Spaces.width12,
        dot,
        Spaces.width12,
        Text("auth.splash_tag_smart".tr(), style: TextStyleApp.authSplashTag),
        Spaces.width12,
        dot,
        Spaces.width12,
        Text("auth.splash_tag_family".tr(), style: TextStyleApp.authSplashTag),
      ],
    );
  }
}
