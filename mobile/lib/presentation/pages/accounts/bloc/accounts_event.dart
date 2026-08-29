part of 'accounts_bloc.dart';

sealed class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the full-screen loader.
class OnLoadAccounts extends AccountsEvent {
  const OnLoadAccounts();
}

/// Pull-to-refresh, and what the screen dispatches after a successful add,
/// edit or delete. Keeps the current cards on screen while reloading.
class OnRefreshAccounts extends AccountsEvent {
  const OnRefreshAccounts();
}

/// The search field changed. Re-filters the loaded accounts; no network call.
class OnAccountsQueryChanged extends AccountsEvent {
  final String query;

  const OnAccountsQueryChanged(this.query);

  @override
  List<Object?> get props => <Object?>[query];
}
