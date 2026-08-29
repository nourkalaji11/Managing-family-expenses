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

  /// What the grid renders: the categories whose name matches [query].
  final List<Category> visible;

  /// True while a refresh is in flight over already-visible content.
  final bool isRefreshing;

  const CategoriesLoaded({
    required this.data,
    required this.query,
    required this.visible,
    this.isRefreshing = false,
  });

  /// True when there are genuinely no categories.
  bool get isEmpty => data.categories.isEmpty;

  /// True when categories exist but none matches the query.
  bool get isFilteredEmpty => visible.isEmpty && data.categories.isNotEmpty;

  CategoriesLoaded copyWith({
    CategoriesData? data,
    String? query,
    List<Category>? visible,
    bool? isRefreshing,
  }) => CategoriesLoaded(
    data: data ?? this.data,
    query: query ?? this.query,
    visible: visible ?? this.visible,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => <Object?>[
    data.categories,
    data.transactionCounts,
    data.budgetCounts,
    query,
    visible,
    isRefreshing,
  ];
}

class CategoriesFailure extends CategoriesState {
  final Failure error;

  const CategoriesFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
