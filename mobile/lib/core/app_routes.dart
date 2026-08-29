import 'package:flutter/material.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/login_screen.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/register_screen.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/budget_form_screen.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/dashboard.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/transaction_form_screen.dart';

/// Named routes for the app.
///
/// `'/'` is deliberately absent: `SplashScreen` is wired as `MaterialApp.home`,
/// and MaterialApp asserts if `home` and `routes['/']` are both supplied.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';

  /// Add and Edit share one screen. Two names exist so the intent is explicit
  /// at the call site and in navigation logs; the mode is decided by whether
  /// `TransactionFormArgs.transaction` is null.
  ///
  /// Both expect a `TransactionFormArgs` as the route `arguments`. The screen
  /// falls back to an empty Add form if none is supplied, rather than throwing.
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/edit';

  /// Budgets follow the same one-screen-two-names arrangement as transactions.
  /// Both expect a `BudgetFormArgs` as the route `arguments`; the screen falls
  /// back to an empty Add form if none is supplied, rather than throwing.
  static const String addBudget = '/budgets/add';
  static const String editBudget = '/budgets/edit';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    dashboard: (_) => const Dashboard(),
    addTransaction: (_) => const TransactionFormScreen(),
    editTransaction: (_) => const TransactionFormScreen(),
    addBudget: (_) => const BudgetFormScreen(),
    editBudget: (_) => const BudgetFormScreen(),
  };
}
