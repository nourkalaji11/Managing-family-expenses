import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/budgets_screen.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/home_screen.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/placeholder_tab.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/transactions_screen.dart';

class DashboardCubit extends Cubit<int> {
  DashboardCubit() : super(0);

  DateTime? currentBackPressTime;
  final PageController pageController = PageController(initialPage: 0);

  /// Order must match `MainTabs`, because the tab index is the page index.
  ///
  /// `HomeScreen`, `TransactionsScreen` and `BudgetsScreen` are real features;
  /// the remaining two are stubs until their features are built.
  final List<Widget> tabs = const [
    HomeScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    PlaceholderTab(titleKey: "tabs.accounts"),
    PlaceholderTab(titleKey: "tabs.categories"),
  ];

  void changeTab(MainTabs tab) {
    pageController.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 1),
      curve: Curves.easeInOut,
    );
    emit(tab.index);
  }
}
