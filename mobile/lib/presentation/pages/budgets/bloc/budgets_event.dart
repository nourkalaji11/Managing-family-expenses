part of 'budgets_bloc.dart';

sealed class BudgetsEvent extends Equatable {
  const BudgetsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the full-screen loader.
class OnLoadBudgets extends BudgetsEvent {
  const OnLoadBudgets();
}

/// Pull-to-refresh, and what the screen dispatches after a successful add or
/// edit. Keeps the current cards on screen while reloading.
class OnRefreshBudgets extends BudgetsEvent {
  const OnRefreshBudgets();
}

/// The month selector moved. Re-projects the loaded budgets; no network call.
class OnBudgetMonthChanged extends BudgetsEvent {
  /// Any day inside the target month; the bloc normalises it to the first.
  final DateTime month;

  const OnBudgetMonthChanged(this.month);

  @override
  List<Object?> get props => <Object?>[month];
}
