part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the full-screen loader.
class OnLoadTransactions extends TransactionsEvent {
  const OnLoadTransactions();
}

/// Pull-to-refresh, and what the screen dispatches after a successful add or
/// edit. Keeps the current rows on screen while reloading.
class OnRefreshTransactions extends TransactionsEvent {
  const OnRefreshTransactions();
}

/// The search field changed. Re-projects the loaded rows; no network call.
class OnSearchChanged extends TransactionsEvent {
  final String query;

  const OnSearchChanged(this.query);

  @override
  List<Object?> get props => <Object?>[query];
}

/// "الكل" / "الدخل" / "المصاريف" changed.
class OnTypeFilterChanged extends TransactionsEvent {
  final TransactionTypeFilter filter;

  const OnTypeFilterChanged(this.filter);

  @override
  List<Object?> get props => <Object?>[filter];
}

/// "هذا الشهر" toggled. Independent of [OnTypeFilterChanged] — the design
/// prototype treated all four chips as one radio group, which conflates two
/// unrelated axes.
class OnPeriodFilterChanged extends TransactionsEvent {
  final TransactionPeriodFilter filter;

  const OnPeriodFilterChanged(this.filter);

  @override
  List<Object?> get props => <Object?>[filter];
}
