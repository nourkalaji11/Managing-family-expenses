import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:family_expense_management/core/default_settings.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/presentation/pages/dashboard/bloc/dashboard_cubit.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/main_bottom_nav_bar.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/utils/analytics_controller.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    AnalyticsController.setUserId(LocalsApp.user!.id.toString());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(),
      child: BlocBuilder<DashboardCubit, int>(
        builder: (context, state) {
          final cubit = context.read<DashboardCubit>();
          // `WillPopScope` is deprecated; `PopScope` is its replacement. The
          // behaviour is unchanged: on a non-home tab, back returns to the home
          // tab; on the home tab, back must be pressed twice within 2 seconds
          // to leave the app.
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;

              if (state != 0) {
                cubit.changeTab(MainTabs.home);
                return;
              }

              final now = DateTime.now();
              if (cubit.currentBackPressTime == null ||
                  now.difference(cubit.currentBackPressTime!) >
                      const Duration(seconds: 2)) {
                cubit.currentBackPressTime = now;
                EasyLoading.showToast(
                  "exit_warning".tr(),
                  toastPosition: EasyLoadingToastPosition.bottom,
                );
                return;
              }

              // Second press within the window: actually leave.
              SystemNavigator.pop();
            },
            child: SafeArea(
              top: false,
              right: false,
              left: false,
              bottom: Platform.isIOS ? false : true,
              child: Scaffold(
                key: DefaultSettings.scaffoldDashboardKey,
                backgroundColor: ColorsApp.dashboardBackground,
                extendBodyBehindAppBar: true,
                drawerEnableOpenDragGesture: false,
                bottomNavigationBar: MainBottomNavBar(
                  selectedIndex: cubit.state,
                  onTabChange: (tab) =>
                      context.read<DashboardCubit>().changeTab(tab),
                ),
                body: PageView(
                  controller: cubit.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: cubit.tabs,
                  onPageChanged: (value) {
                    MainTabs tab = MainTabs.values
                        .where((element) => element.index == value)
                        .first;
                    context.read<DashboardCubit>().changeTab(tab);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
