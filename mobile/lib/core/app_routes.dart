import 'package:flutter/material.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/account_form_screen.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/login_screen.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/register_screen.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/budget_form_screen.dart';
import 'package:family_expense_management/presentation/pages/categories/presentation/category_form_screen.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/dashboard.dart';
import 'package:family_expense_management/presentation/pages/notifications/presentation/notifications.dart';
import 'package:family_expense_management/presentation/pages/profile/presentation/edit_profile_screen.dart';
import 'package:family_expense_management/presentation/pages/profile/presentation/family_members_screen.dart';
import 'package:family_expense_management/presentation/pages/profile/presentation/profile_screen.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/transaction_form_screen.dart';
import 'package:family_expense_management/presentation/pages/transfers/presentation/transfer_screen.dart';
import 'package:family_expense_management/presentation/pages/transfers/presentation/transfers_history_screen.dart';

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

  /// Accounts follow the same one-screen-two-names arrangement. Both expect an
  /// `AccountFormArgs` as the route `arguments`; the screen falls back to an
  /// empty Add form if none is supplied, rather than throwing.
  static const String addAccount = '/accounts/add';
  static const String editAccount = '/accounts/edit';

  /// Categories, likewise, with a `CategoryFormArgs`.
  static const String addCategory = '/categories/add';
  static const String editCategory = '/categories/edit';

  /// Pushed from the avatar in every main tab's app bar.
  static const String profile = '/profile';

  /// Expects the `User` being edited as the route `arguments`; falls back to
  /// the cached session if pushed bare.
  static const String editProfile = '/profile/edit';

  /// Parent-only in practice: a member's `GET /users` returns only themselves,
  /// so the profile screen offers this to a parent alone.
  static const String familyMembers = '/profile/family';

  /// Pushed from the bell in every main tab's app bar.
  static const String notifications = '/notifications';

  /// Pushed from the dashboard's "تحويل" quick action. Pops `true` after a
  /// successful transfer, so the dashboard knows both balances moved.
  static const String transfer = '/transfer';

  /// Past transfers, pushed from the history action in the transfer form's app
  /// bar. Pops `true` when a transfer was undone — an undo moves two balances,
  /// so that signal has to reach the dashboard.
  static const String transfersHistory = '/transfer/history';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    dashboard: (_) => const Dashboard(),
    addTransaction: (_) => const TransactionFormScreen(),
    editTransaction: (_) => const TransactionFormScreen(),
    addBudget: (_) => const BudgetFormScreen(),
    editBudget: (_) => const BudgetFormScreen(),
    addAccount: (_) => const AccountFormScreen(),
    editAccount: (_) => const AccountFormScreen(),
    addCategory: (_) => const CategoryFormScreen(),
    editCategory: (_) => const CategoryFormScreen(),
    profile: (_) => const ProfileScreen(),
    editProfile: (_) => const EditProfileScreen(),
    familyMembers: (_) => const FamilyMembersScreen(),
    notifications: (_) => const Notifications(),
    transfer: (_) => const TransferScreen(),
    transfersHistory: (_) => const TransfersHistoryScreen(),
  };
}
