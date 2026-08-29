part of 'accounts_bloc.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => <Object?>[];
}

class AccountsInitial extends AccountsState {
  const AccountsInitial();
}

class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

class AccountsLoaded extends AccountsState {
  /// Everything the repository returned, unfiltered. [visible] is always
  /// derived from this, so clearing the query never has to re-fetch.
  final AccountsData data;

  /// The current search text, exactly as typed.
  final String query;

  /// What the list renders: the accounts whose name matches [query].
  final List<Account> visible;

  /// True while a refresh is in flight over already-visible content.
  final bool isRefreshing;

  const AccountsLoaded({
    required this.data,
    required this.query,
    required this.visible,
    this.isRefreshing = false,
  });

  /// Σ of **every** account's balance, not just the visible ones.
  ///
  /// Deliberate: the hero card is labelled "إجمالي الأرصدة", and a total that
  /// shrank while the user typed a search term would be reporting something
  /// nobody asked for.
  num get totalBalance => data.totalBalance;

  /// True when the family genuinely has no accounts.
  bool get isEmpty => data.accounts.isEmpty;

  /// True when accounts exist but none matches the query — a different message
  /// from "no accounts yet", and a different next action.
  bool get isFilteredEmpty => visible.isEmpty && data.accounts.isNotEmpty;

  AccountsLoaded copyWith({
    AccountsData? data,
    String? query,
    List<Account>? visible,
    bool? isRefreshing,
  }) => AccountsLoaded(
    data: data ?? this.data,
    query: query ?? this.query,
    visible: visible ?? this.visible,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  // `visible` is rebuilt as a new list on every projection, so identity is what
  // distinguishes two states here — same reasoning as `BudgetsLoaded`.
  @override
  List<Object?> get props => <Object?>[
    data.accounts,
    data.transactionCounts,
    query,
    visible,
    isRefreshing,
  ];
}

class AccountsFailure extends AccountsState {
  final Failure error;

  const AccountsFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
