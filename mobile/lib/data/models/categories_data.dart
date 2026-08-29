import 'package:family_expense_management/data/models/category.dart';

/// Everything the categories feature loads in one call.
///
/// [transactionCounts] is derived, not a column — the design's tiles show
/// "12 معاملة" under each category name, and nothing on the server reports it.
///
/// TODO(backend): a `withCount('transactions')` on `CategoryController::index`
/// would replace this and remove the extra `GET /transactions` the repository
/// currently has to make.
class CategoriesData {
  /// Ordered by name ascending, mirroring `CategoryController::index`.
  final List<Category> categories;

  /// Number of transactions filed under each category, keyed by category id.
  /// A category with no transactions is absent rather than mapped to zero.
  final Map<int, int> transactionCounts;

  /// Number of budgets targeting each category, keyed by category id.
  ///
  /// Not rendered anywhere. It exists so the form can warn before a delete that
  /// the server will refuse: `CategoryController::destroy` answers 409 when the
  /// category is referenced by either table, and telling the user up front beats
  /// letting them press Delete and read an error.
  final Map<int, int> budgetCounts;

  const CategoriesData({
    required this.categories,
    this.transactionCounts = const <int, int>{},
    this.budgetCounts = const <int, int>{},
  });

  /// Transactions filed under [categoryId], or 0 when there are none.
  int countFor(int? categoryId) {
    if (categoryId == null) return 0;
    return transactionCounts[categoryId] ?? 0;
  }

  /// True when deleting [categoryId] would be refused by the server because
  /// something still references it.
  bool isInUse(int? categoryId) {
    if (categoryId == null) return false;
    return (transactionCounts[categoryId] ?? 0) > 0 ||
        (budgetCounts[categoryId] ?? 0) > 0;
  }
}

/// The editable half of a category: exactly the one field the form owns.
///
/// Mirrors what `CategoryController::store` and `update` validate:
///
///     'name' => 'required|string|max:50|unique:categories,name'
///
/// The design's icon grid and colour swatches are deliberately **not** modelled.
/// `categories` is `(id, name, created_at, updated_at)` — there is no `icon` and
/// no `color` column, so a pick made there could not survive a reload. The app
/// already derives both client-side in `CategoryVisuals`, and the form renders
/// that derived pair as a live preview rather than offering a picker that
/// silently forgets. Adding the two columns is what makes the design's pickers
/// implementable; see `CategoryVisuals` for the standing TODO.
class CategoryDraft {
  final String name;

  const CategoryDraft({required this.name});

  /// The exact JSON body the backend's validator accepts.
  Map<String, dynamic> toRequestJson() => {'name': name};
}
