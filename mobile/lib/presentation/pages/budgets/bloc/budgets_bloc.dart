import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/repos/budgets_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/budgets/domain/budgets_domain.dart';

part 'budgets_event.dart';
part 'budgets_state.dart';

/// Owns the budget list: loading, month selection and the header totals.
///
/// All derivation happens here, never in a widget. The screen renders
/// `BudgetsLoaded.visible` and `BudgetsLoaded.summary` and nothing else.
class BudgetsBloc extends Bloc<BudgetsEvent, BudgetsState> {
  /// The abstract contract from `domain/budgets_domain.dart`. Injectable so
  /// tests can supply a fake without touching the mock store or GetIt.
  final BudgetsDomain _repo;

  BudgetsBloc({BudgetsDomain? repo})
    : _repo = repo ?? BudgetsRepo(),
      super(const BudgetsInitial()) {
    on<BudgetsEvent>((event, emit) async {
      if (event is OnLoadBudgets) {
        emit(const BudgetsLoading());
        await _load(emit);
      } else if (event is OnRefreshBudgets) {
        // Keep the current content visible while reloading instead of dropping
        // back to a full-screen loader.
        final current = state;
        if (current is BudgetsLoaded) {
          emit(current.copyWith(isRefreshing: true));
        }
        await _load(emit);
      } else if (event is OnBudgetMonthChanged) {
        _reproject(emit, month: monthOf(event.month));
      }
    });
  }

  Future<void> _load(Emitter<BudgetsState> emit) async {
    // The selected month survives a refresh: reloading must not silently jump
    // the user back to today.
    final BudgetsState current = state;
    final DateTime month = current is BudgetsLoaded
        ? current.month
        : monthOf(DateTime.now());

    final result = await _repo.getBudgets();
    result.fold((failure) => emit(BudgetsFailure(failure)), (data) {
      final List<BudgetModel> visible = visibleFor(data.budgets, month);
      emit(
        BudgetsLoaded(
          all: data.budgets,
          categories: data.categories,
          month: month,
          visible: visible,
          summary: summaryOf(visible),
        ),
      );
    });
  }

  /// Recomputes the visible budgets after a month change, without hitting the
  /// repository again.
  void _reproject(Emitter<BudgetsState> emit, {required DateTime month}) {
    final BudgetsState current = state;
    if (current is! BudgetsLoaded) return;

    // Always rebuilt from `all`, so moving back to a previous month restores
    // exactly what it showed before.
    final List<BudgetModel> visible = visibleFor(current.all, month);
    emit(
      current.copyWith(
        month: month,
        visible: visible,
        summary: summaryOf(visible),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Projection helpers. Static and pure, so they are directly testable and can
  // never read state they were not given.
  // ---------------------------------------------------------------------------

  /// Normalises any day to the first of its month at midnight.
  static DateTime monthOf(DateTime day) => DateTime(day.year, day.month);

  /// The last day of [month] at midnight. Day 0 of the following month, which
  /// is correct for every month length without a lookup table.
  static DateTime endOfMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);

  /// The budgets whose period overlaps [month] at all.
  ///
  /// A budget spanning a quarter therefore appears in each of its three months,
  /// which is the truthful reading of `start_date`/`end_date`. Ordering is left
  /// exactly as the repository returned it.
  static List<BudgetModel> visibleFor(
    List<BudgetModel> source,
    DateTime month,
  ) {
    final DateTime from = monthOf(month);
    final DateTime to = endOfMonth(from);

    final List<BudgetModel> matches = <BudgetModel>[];
    for (final b in source) {
      if (b.overlapsRange(from, to)) matches.add(b);
    }
    return matches;
  }

  /// Sums the limits and the derived spending of [budgets].
  static BudgetsSummary summaryOf(List<BudgetModel> budgets) {
    num limit = 0;
    num spent = 0;
    for (final b in budgets) {
      limit += b.limit;
      spent += b.spent;
    }
    return BudgetsSummary(totalLimit: limit, totalSpent: spent);
  }
}
