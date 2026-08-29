part of 'categories_bloc.dart';

sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the full-screen loader.
class OnLoadCategories extends CategoriesEvent {
  const OnLoadCategories();
}

/// Pull-to-refresh, and what the screen dispatches after a successful add,
/// edit or delete.
class OnRefreshCategories extends CategoriesEvent {
  const OnRefreshCategories();
}

/// The search field changed. Re-filters the loaded categories; no network call.
class OnCategoriesQueryChanged extends CategoriesEvent {
  final String query;

  const OnCategoriesQueryChanged(this.query);

  @override
  List<Object?> get props => <Object?>[query];
}
