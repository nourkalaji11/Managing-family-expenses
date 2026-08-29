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

  /// The family, for the "whose spending" filter. Empty for a member, who is
  /// only ever shown their own rows and must not be handed a roster of the
  /// others.
  final List<User> members;

  final String query;
  final TransactionTypeFilter typeFilter;
  final TransactionPeriodFilter periodFilter;

  /// Whose rows to show, or null for everyone's. An id rather than a `User` so
  /// that a rename mid-session cannot leave the filter pointing at a stale copy.
  final int? personFilter;

  /// Which category to show, or null for all of them.
  final int? categoryFilter;

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
    this.members = const <User>[],
    this.personFilter,
    this.categoryFilter,
    this.isRefreshing = false,
  });

  /// True when this screen may offer a "whose spending" filter.
  ///
  /// Two or more people, which for a member is never: the server hands them
  /// only themselves.
  bool get canFilterByPerson => members.length > 1;

  /// The person currently selected, or null when the filter is off or the id
  /// matches nobody.
  User? get selectedPerson {
    final id = personFilter;
    if (id == null) return null;
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Category? get selectedCategory {
    final id = categoryFilter;
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// True when the user has loaded rows but the current criteria match none —
  /// the "no results" empty state, which reads differently from "no data yet".
  bool get isFilteredEmpty => groups.isEmpty && all.isNotEmpty;

  /// True when there is genuinely nothing to show.
  bool get isEmpty => all.isEmpty;

  /// True when any criterion is narrowing the list.
  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      typeFilter != TransactionTypeFilter.all ||
      periodFilter != TransactionPeriodFilter.all ||
      personFilter != null ||
      categoryFilter != null;

  TransactionsLoaded copyWith({
    List<TransactionModel>? all,
    List<Account>? accounts,
    List<Category>? categories,
    List<User>? members,
    String? query,
    TransactionTypeFilter? typeFilter,
    TransactionPeriodFilter? periodFilter,
    int? personFilter,
    int? categoryFilter,
    List<TransactionDayGroup>? groups,
    bool? isRefreshing,

    /// Explicit clears: `null` in a `??`-based copyWith means "keep", so
    /// without these there would be no way to turn either filter back off.
    bool clearPersonFilter = false,
    bool clearCategoryFilter = false,
  }) => TransactionsLoaded(
    all: all ?? this.all,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    members: members ?? this.members,
    query: query ?? this.query,
    typeFilter: typeFilter ?? this.typeFilter,
    periodFilter: periodFilter ?? this.periodFilter,
    personFilter: clearPersonFilter
        ? null
        : (personFilter ?? this.personFilter),
    categoryFilter: clearCategoryFilter
        ? null
        : (categoryFilter ?? this.categoryFilter),
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
    members,
    query,
    typeFilter,
    periodFilter,
    personFilter,
    categoryFilter,
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
