import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/repos/transactions_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/transactions/domain/transactions_domain.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

/// Owns the transaction list: loading, searching, filtering and day grouping.
///
/// All derivation happens here, never in a widget. The screen renders
/// `TransactionsLoaded.groups` and nothing else.
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  /// The abstract contract from `domain/transactions_domain.dart`. Injectable so
  /// tests can supply a fake without touching the mock store or GetIt.
  final TransactionsDomain _repo;

  TransactionsBloc({TransactionsDomain? repo})
    : _repo = repo ?? TransactionsRepo(),
      super(const TransactionsInitial()) {
    on<TransactionsEvent>((event, emit) async {
      if (event is OnLoadTransactions) {
        emit(const TransactionsLoading());
        await _load(emit);
      } else if (event is OnRefreshTransactions) {
        // Keep the current content visible while reloading instead of dropping
        // back to a full-screen loader.
        final current = state;
        if (current is TransactionsLoaded) {
          emit(current.copyWith(isRefreshing: true));
        }
        await _load(emit);
      } else if (event is OnSearchChanged) {
        _reproject(emit, query: event.query);
      } else if (event is OnTypeFilterChanged) {
        _reproject(emit, typeFilter: event.filter);
      } else if (event is OnPeriodFilterChanged) {
        _reproject(emit, periodFilter: event.filter);
      }
    });
  }

  Future<void> _load(Emitter<TransactionsState> emit) async {
    // Filters survive a refresh: reloading must not silently reset what the
    // user selected.
    final TransactionsState current = state;
    final String query = current is TransactionsLoaded ? current.query : '';
    final TransactionTypeFilter typeFilter = current is TransactionsLoaded
        ? current.typeFilter
        : TransactionTypeFilter.all;
    final TransactionPeriodFilter periodFilter = current is TransactionsLoaded
        ? current.periodFilter
        : TransactionPeriodFilter.all;

    final result = await _repo.getTransactions();
    result.fold((failure) => emit(TransactionsFailure(failure)), (data) {
      emit(
        TransactionsLoaded(
          all: data.transactions,
          accounts: data.accounts,
          categories: data.categories,
          query: query,
          typeFilter: typeFilter,
          periodFilter: periodFilter,
          groups: buildGroups(
            data.transactions,
            query: query,
            typeFilter: typeFilter,
            periodFilter: periodFilter,
          ),
        ),
      );
    });
  }

  /// Recomputes the visible groups after a filter or search change, without
  /// hitting the repository again.
  void _reproject(
    Emitter<TransactionsState> emit, {
    String? query,
    TransactionTypeFilter? typeFilter,
    TransactionPeriodFilter? periodFilter,
  }) {
    final TransactionsState current = state;
    if (current is! TransactionsLoaded) return;

    final String nextQuery = query ?? current.query;
    final TransactionTypeFilter nextType = typeFilter ?? current.typeFilter;
    final TransactionPeriodFilter nextPeriod =
        periodFilter ?? current.periodFilter;

    emit(
      current.copyWith(
        query: nextQuery,
        typeFilter: nextType,
        periodFilter: nextPeriod,
        // Always rebuilt from `all`, so the three criteria compose instead of
        // one resetting another.
        groups: buildGroups(
          current.all,
          query: nextQuery,
          typeFilter: nextType,
          periodFilter: nextPeriod,
        ),
      ),
    );
  }

  /// The date a row belongs to.
  ///
  /// Prefers `date`, the transaction's own calendar day, over `created_at`,
  /// which is only the insert timestamp. This is the opposite preference to
  /// `TransactionModel.displayedAt`, and deliberately so: a back-dated row must
  /// group under the day it happened, not the day it was typed in.
  static DateTime? effectiveDate(TransactionModel t) => t.date ?? t.createdAt;

  /// Applies search + type + period, then groups the survivors by day.
  ///
  /// Never mutates [source]: it is copied before sorting.
  static List<TransactionDayGroup> buildGroups(
    List<TransactionModel> source, {
    required String query,
    required TransactionTypeFilter typeFilter,
    required TransactionPeriodFilter periodFilter,
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();
    final String needle = query.trim().toLowerCase();

    final List<TransactionModel> matches = <TransactionModel>[];
    for (final t in source) {
      if (!_matchesType(t, typeFilter)) continue;
      if (!_matchesPeriod(t, periodFilter, today)) continue;
      if (!_matchesQuery(t, needle)) continue;
      matches.add(t);
    }

    // Newest first, by the same field the rows are grouped on, so a row can
    // never appear above a day header it does not belong to. `created_at`
    // breaks ties within a day, which is the only field carrying a time.
    matches.sort((a, b) {
      final DateTime? da = effectiveDate(a);
      final DateTime? db = effectiveDate(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      final int byDate = db.compareTo(da);
      if (byDate != 0) return byDate;

      final DateTime? ca = a.createdAt;
      final DateTime? cb = b.createdAt;
      if (ca == null || cb == null) return 0;
      return cb.compareTo(ca);
    });

    final List<TransactionDayGroup> groups = <TransactionDayGroup>[];
    for (final t in matches) {
      final DateTime? d = effectiveDate(t);
      // Rows with no date at all still render, in a trailing undated group,
      // rather than being dropped from a list the user expects to be complete.
      final DateTime? day = d == null
          ? null
          : DateTime(d.year, d.month, d.day);

      if (groups.isNotEmpty && _sameDay(groups.last.day, day)) {
        groups.last.transactions.add(t);
      } else {
        groups.add(
          TransactionDayGroup(
            day: day,
            transactions: <TransactionModel>[t],
          ),
        );
      }
    }
    return groups;
  }

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _matchesType(TransactionModel t, TransactionTypeFilter filter) {
    return switch (filter) {
      TransactionTypeFilter.all => true,
      TransactionTypeFilter.income => t.type == TransactionType.income,
      TransactionTypeFilter.expense => t.type == TransactionType.expense,
    };
  }

  /// "هذا الشهر" is the current calendar month of the current year.
  static bool _matchesPeriod(
    TransactionModel t,
    TransactionPeriodFilter filter,
    DateTime now,
  ) {
    if (filter == TransactionPeriodFilter.all) return true;
    final DateTime? d = effectiveDate(t);
    if (d == null) return false;
    return d.year == now.year && d.month == now.month;
  }

  /// Matches the information the row actually shows: the description, the
  /// category name and the account name. Case-insensitive.
  static bool _matchesQuery(TransactionModel t, String needle) {
    if (needle.isEmpty) return true;
    final Iterable<String> haystack = <String?>[
      t.description,
      t.category?.name,
      t.account?.name,
    ].whereType<String>();

    for (final field in haystack) {
      if (field.toLowerCase().contains(needle)) return true;
    }
    return false;
  }
}
