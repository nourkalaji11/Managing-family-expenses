import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:family_expense_management/blocs/local_user_cubit.dart';
import 'package:family_expense_management/blocs/locale_cubit.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/core/default_settings.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/core/notification_manager.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/local_storage.dart';
import 'package:family_expense_management/firebase_options.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/splash_screen.dart';
import 'package:family_expense_management/presentation/pages/dashboard/bloc/dashboard_cubit.dart';
import 'package:family_expense_management/presentation/widgets/custom_easyloading.dart';
import 'package:family_expense_management/style/theme.dart';
import 'package:family_expense_management/utils/service_locator.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // `firebase_options.dart` ships with empty apiKey/projectId, so this throws
  // `ApiKey must be set.` before `runApp` and the app never leaves the native
  // splash. Firebase is not required for the app to function, so a failed init
  // degrades instead of blocking startup. Fill in the real options to restore
  // messaging and analytics.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  await EasyLocalization.ensureInitialized();
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Locale locale = await LocalStorage().getLanguage();

  await OneSignalNotificationManager.initialize();
  OneSignalNotificationManager.addClickListener();

  setupServiceLocator();
  runApp(
    EasyLocalization(
      startLocale: locale,
      supportedLocales: DefaultSettings.supportedLocales,
      path: 'assets/translations',
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
  static void restartApp(BuildContext context, {MainTabs? tab}) {
    context.findAncestorStateOfType<_MyAppState>()?.restartApp(tab);
  }
}

class _MyAppState extends State<MyApp> {
  void restartApp(MainTabs? tab) {
    setState(() {
      DefaultSettings.mainNavigatorKey = GlobalKey(
        debugLabel: "Main Navigator",
      );
      Future.delayed(Duration(seconds: 2), () {
        DefaultSettings.scaffoldDashboardKey.currentState?.context
            .read<DashboardCubit>()
            .changeTab(tab ?? MainTabs.home);
      });
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    LocalsApp.locale = context.locale;
    if (Platform.isAndroid) {
      LocalsApp.deviceOS = "android";
    } else if (Platform.isIOS) {
      LocalsApp.deviceOS = "ios";
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>.value(value: getIt<LocaleCubit>()),
        BlocProvider<LocalUserCubit>.value(value: getIt<LocalUserCubit>()),
      ],
      child: Builder(
        builder: (context) {
          final locale = context.watch<LocaleCubit>().state;
          return ScreenUtilInit(
            designSize: const Size(412, 917),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp(
                navigatorKey: DefaultSettings.mainNavigatorKey,
                title: "Family Expenses",
                debugShowCheckedModeBanner: false,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: locale,
                theme: Themes.theme,
                themeMode: ThemeMode.light,
                home: const SplashScreen(),
                // `AppRoutes.routes` intentionally has no '/' entry: MaterialApp
                // asserts when `home` and `routes['/']` are both provided.
                routes: AppRoutes.routes,
                builder: (context, widget) {
                  EasyLoading.init();
                  ScreenUtil.init(context);
                  CustomEasyLoading().configLoading();
                  double width = MediaQuery.of(context).size.width;

                  widget = MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(width < 600 ? 1.0 : 0.8),
                    ),
                    child: widget!,
                  );
                  widget = EasyLoading.init()(context, widget);
                  return ScrollConfiguration(
                    behavior: NoGlowScrollBehavior(),
                    child: widget,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, _) {
    return child; // Removes the glow effect
  }
}
