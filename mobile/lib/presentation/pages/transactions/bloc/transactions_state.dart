part of 'transactions_bloc.dart';

/// The transaction-type chips. Independent of [TransactionPeriodFilter].
enum TransactionTypeFilter { all, income, expense }

/// The period chip. Only two states exist because the design shows exactly one
/// period control ("هذا الشهر"); [all] is it being off.
enum TransactionPeriodFilter { all, thisMonth }

/// One "اليوم، 24 مايو" section and the rows under it.
///
/// [day] is midnight-normalised, or null for rows carrying no date at all,
/// which the list renders in a trailing untitled group instead of dropping.
class TransactionDayGroup {
  final DateTime? day;
  final List<TransactionModel> transactions;

  TransactionDayGroup({required this.day, required this.transactions});
}

sealed class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => <Object?>[];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsLoaded extends TransactionsState {
  /// Every loaded row, unfiltered. [groups] is always derived from this, so the
  /// filters compose rather than one narrowing the input of the next.
  final List<TransactionModel> all;

  /// Picker options for the add/edit form, loaded alongside the rows so opening
  /// the form never blocks on a second request.
  final List<Account> accounts;
  final List<Category> categories;

  final String query;
  final TransactionTypeFilter typeFilter;
  final TransactionPeriodFilter periodFilter;

  /// What the screen renders: filtered, sorted and grouped by day.
  final List<TransactionDayGroup> groups;

  /// True while a refresh is in flight over already-visible content.
  final bool isRefreshing;

  const TransactionsLoaded({
    required this.all,
    required this.accounts,
    required this.categories,
    required this.query,
    required this.typeFilter,
    required this.periodFilter,
    required this.groups,
    this.isRefreshing = false,
  });

  /// True when the user has loaded rows but the current criteria match none —
  /// the "no results" empty state, which reads differently from "no data yet".
  bool get isFilteredEmpty => groups.isEmpty && all.isNotEmpty;

  /// True when there is genuinely nothing to show.
  bool get isEmpty => all.isEmpty;

  /// True when any criterion is narrowing the list.
  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      typeFilter != TransactionTypeFilter.all ||
      periodFilter != TransactionPeriodFilter.all;

  TransactionsLoaded copyWith({
    List<TransactionModel>? all,
    List<Account>? accounts,
    List<Category>? categories,
    String? query,
    TransactionTypeFilter? typeFilter,
    TransactionPeriodFilter? periodFilter,
    List<TransactionDayGroup>? groups,
    bool? isRefreshing,
  }) => TransactionsLoaded(
    all: all ?? this.all,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    query: query ?? this.query,
    typeFilter: typeFilter ?? this.typeFilter,
    periodFilter: periodFilter ?? this.periodFilter,
    groups: groups ?? this.groups,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  // `groups` is rebuilt as a new list on every projection, so identity is what
  // distinguishes two states here — the same reasoning as `DashboardLoaded`.
  @override
  List<Object?> get props => <Object?>[
    all,
    accounts,
    categories,
    query,
    typeFilter,
    periodFilter,
    groups,
    isRefreshing,
  ];
}

class TransactionsFailure extends TransactionsState {
  final Failure error;

  const TransactionsFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
