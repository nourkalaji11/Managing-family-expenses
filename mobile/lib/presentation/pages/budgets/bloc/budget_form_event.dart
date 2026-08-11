part of 'budget_form_bloc.dart';

sealed class BudgetFormEvent extends Equatable {
  const BudgetFormEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Seeds the form.
///
/// [budget] null means Add; non-null means Edit and pre-fills every editable
/// field. [categories] comes from the list screen's already-loaded state, so the
/// form never blocks on its own request.
class OnBudgetFormStarted extends BudgetFormEvent {
  final BudgetModel? budget;
  final List<Category> categories;

  /// The month the list was showing when Add was tapped. Used only in Add mode,
  /// to default the period to that month instead of always to today's.
  final DateTime? month;

  const OnBudgetFormStarted({
    required this.budget,
    required this.categories,
    this.month,
  });

  @override
  List<Object?> get props => <Object?>[budget?.id, categories, month];
}

class OnBudgetCategoryChanged extends BudgetFormEvent {
  final int categoryId;

  const OnBudgetCategoryChanged(this.categoryId);

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// The raw text of the limit field, exactly as typed.
class OnBudgetLimitChanged extends BudgetFormEvent {
  final String limitInput;

  const OnBudgetLimitChanged(this.limitInput);

  @override
  List<Object?> get props => <Object?>[limitInput];
}

class OnBudgetStartDateChanged extends BudgetFormEvent {
  final DateTime date;

  const OnBudgetStartDateChanged(this.date);

  @override
  List<Object?> get props => <Object?>[date];
}

class OnBudgetEndDateChanged extends BudgetFormEvent {
  final DateTime date;

  const OnBudgetEndDateChanged(this.date);

  @override
  List<Object?> get props => <Object?>[date];
}

/// Validates, then saves. Ignored while a save is already in flight.
class OnSubmitBudgetForm extends BudgetFormEvent {
  const OnSubmitBudgetForm();
}
