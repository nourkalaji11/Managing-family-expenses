import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/accounts_screen.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/budgets_screen.dart';
import 'package:family_expense_management/presentation/pages/categories/presentation/categories_screen.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/home_screen.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/transactions_screen.dart';

class DashboardCubit extends Cubit<int> {
  DashboardCubit() : super(0);

  DateTime? currentBackPressTime;
  final PageController pageController = PageController(initialPage: 0);

  /// Order must match `MainTabs`, because the tab index is the page index.
  ///
  /// All five are real features now. `PlaceholderTab` — the stand-in the last
  /// two used to render — has been deleted along with its file.
  final List<Widget> tabs = const [
    HomeScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    AccountsScreen(),
    CategoriesScreen(),
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
