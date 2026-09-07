part of 'categories_bloc.dart';

sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => <Object?>[];
}

class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  /// Everything the repository returned, unfiltered. [visible] is always
  /// derived from this.
  final CategoriesData data;

  /// The current search text, exactly as typed.
  final String query;

  /// The tab in view: `income`, `expense` or `debt`.
  final String type;

  /// What the list renders: the categories in [type] whose name matches
  /// [query], groups and children together and in planted order.
  final List<Category> visible;

  /// True while a refresh is in flight over already-visible content.
  final bool isRefreshing;

  const CategoriesLoaded({
    required this.data,
    required this.query,
    required this.visible,
    this.type = Category.typeExpense,
    this.isRefreshing = false,
  });

  /// [visible] as sections: each group followed by the children beneath it.
  ///
  /// Built here rather than in the widget so the screen renders a list it is
  /// handed, and the tree is assembled in one place.
  List<CategorySection> get sections {
    final Map<int, List<Category>> childrenOf = {};
    for (final c in visible) {
      if (c.parentId == null) continue;
      childrenOf.putIfAbsent(c.parentId!, () => <Category>[]).add(c);
    }

    return [
      for (final c in visible)
        if (c.parentId == null)
          CategorySection(
            group: c,
            children: childrenOf[c.id] ?? const <Category>[],
          ),
    ];
  }

  /// True when there are genuinely no categories.
  bool get isEmpty => data.categories.isEmpty;

  /// True when categories exist but none matches the query.
  bool get isFilteredEmpty => visible.isEmpty && data.categories.isNotEmpty;

  CategoriesLoaded copyWith({
    CategoriesData? data,
    String? query,
    String? type,
    List<Category>? visible,
    bool? isRefreshing,
  }) => CategoriesLoaded(
    data: data ?? this.data,
    query: query ?? this.query,
    type: type ?? this.type,
    visible: visible ?? this.visible,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => <Object?>[
    data.categories,
    data.transactionCounts,
    data.budgetCounts,
    query,
    type,
    visible,
    isRefreshing,
  ];
}

/// A group and the categories filed under it.
class CategorySection {
  final Category group;
  final List<Category> children;

  const CategorySection({required this.group, required this.children});
}

class CategoriesFailure extends CategoriesState {
  final Failure error;

  const CategoriesFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
