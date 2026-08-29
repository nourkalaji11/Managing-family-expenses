part of 'category_form_bloc.dart';

sealed class CategoryFormEvent extends Equatable {
  const CategoryFormEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Seeds the form.
///
/// [category] null means Add; non-null means Edit and pre-fills the name.
class OnCategoryFormStarted extends CategoryFormEvent {
  final Category? category;

  /// How many transactions and budgets reference the category being edited,
  /// handed down from the grid's already-loaded counts. Used to warn before a
  /// delete the server would refuse.
  final int usageCount;

  const OnCategoryFormStarted({required this.category, this.usageCount = 0});

  @override
  List<Object?> get props => <Object?>[category?.id, usageCount];
}

class OnCategoryNameChanged extends CategoryFormEvent {
  final String name;

  const OnCategoryNameChanged(this.name);

  @override
  List<Object?> get props => <Object?>[name];
}

/// Validates, then saves. Ignored while a save or delete is already in flight.
class OnSubmitCategoryForm extends CategoryFormEvent {
  const OnSubmitCategoryForm();
}

/// Deletes the category being edited. Ignored in Add mode, and while a save or
/// delete is already in flight.
///
/// The screen confirms with the user before dispatching this.
class OnDeleteCategory extends CategoryFormEvent {
  const OnDeleteCategory();
}
