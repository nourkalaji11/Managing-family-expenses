import 'package:flutter/material.dart';

enum LoginProvider { email, phone, google, apple, twitter, facebook }

enum UserRole {
  user("User"),
  expert("Expert");

  final String type;

  const UserRole(this.type);
}

extension UserRoleHelper on Iterable<UserRole> {
  UserRole tryFrom(String? value) {
    if (value != null) {
      for (var item in this) {
        if (item.type == value) {
          return item;
        }
      }
    }
    return UserRole.user;
  }
}

enum Gender { female, male, other }

/// Role of a member inside the family account.
///
/// The database column is `role` (NOT `account_type`). [apiValue] holds the
/// value sent to the backend, so the Arabic UI labels are never transmitted.
/// See `AuthRepo.register`.
enum AccountRole {
  parent("parent"),
  member("member");

  final String apiValue;

  const AccountRole(this.apiValue);
}

/// Type of a transaction.
///
/// Mirrors the `transactions.type` column, which is `ENUM('income','expense')`.
/// [apiValue] is what goes on the wire, so Arabic UI labels are never
/// transmitted — same convention as [AccountRole].
enum TransactionType {
  income("income"),
  expense("expense");

  final String apiValue;

  const TransactionType(this.apiValue);
}

extension TransactionTypeHelper on Iterable<TransactionType> {
  TransactionType tryFrom(String? value) {
    if (value != null) {
      for (var item in this) {
        if (item.apiValue == value) {
          return item;
        }
      }
    }
    return TransactionType.expense;
  }
}

/// The five tabs of the main bottom navigation bar.
///
/// Order defines the tab index and therefore the `PageView` page order. In RTL
/// the bar lays them out right-to-left, so [home] sits on the right — matching
/// `docs/stitch_family_finance_tracker/dashboard_screen_minimal_redesign`.
///
/// Two icon representations coexist on purpose:
///   * [iconData] / [activeIcon] are what `MainBottomNavBar` renders. Material
///     icons are used because this repository ships no icon assets — `assets/`
///     contains only `translations/`.
///   * [icon] is the legacy SVG path consumed by the unused
///     `presentation/widgets/bottom_bar/` widgets (`button.dart` feeds it to
///     `SvgPicture.asset`). Those files are kept compiling until the old bar is
///     removed in a separate cleanup step; the paths they point at do not
///     exist, which is why nothing renders them any more.
enum MainTabs {
  home(
    "tabs.home",
    "assets/icons/nav_bar/home.svg",
    Icons.home_outlined,
    Icons.home,
  ),
  transactions(
    "tabs.transactions",
    "assets/icons/nav_bar/transactions.svg",
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
  budgets(
    "tabs.budgets",
    "assets/icons/nav_bar/budgets.svg",
    Icons.query_stats,
    Icons.query_stats,
  ),
  accounts(
    "tabs.accounts",
    "assets/icons/nav_bar/accounts.svg",
    Icons.account_balance_outlined,
    Icons.account_balance,
  ),
  categories(
    "tabs.categories",
    "assets/icons/nav_bar/categories.svg",
    Icons.grid_view_outlined,
    Icons.grid_view,
  );

  /// Translation key, resolved with `.tr()` at render time.
  final String text;

  /// Legacy SVG path — see the class doc. Not used by `MainBottomNavBar`.
  final String icon;

  final IconData iconData;
  final IconData activeIcon;

  const MainTabs(this.text, this.icon, this.iconData, this.activeIcon);
}
