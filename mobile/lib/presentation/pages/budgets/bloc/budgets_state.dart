part of 'budgets_bloc.dart';

/// The three figures in the design's header and bento grid: "إجمالي الميزانية",
/// "تم صرفه" and "المتبقي".
///
/// Computed over the budgets currently visible, so the totals always describe
/// the month on screen rather than every budget ever created.
class BudgetsSummary extends Equatable {
  final num totalLimit;
  final num totalSpent;

  const BudgetsSummary({required this.totalLimit, required this.totalSpent});

  /// Can go negative when the visible budgets are collectively overspent, which
  /// is the truthful figure — the widget decides how to colour it.
  num get totalRemaining => totalLimit - totalSpent;

  @override
  List<Object?> get props => <Object?>[totalLimit, totalSpent];
}

sealed class BudgetsState extends Equatable {
  const BudgetsState();

  @override
  List<Object?> get props => <Object?>[];
}

class BudgetsInitial extends BudgetsState {
  const BudgetsInitial();
}

class BudgetsLoading extends BudgetsState {
  const BudgetsLoading();
}

class BudgetsLoaded extends BudgetsState {
  /// Every loaded budget, unfiltered. [visible] is always derived from this, so
  /// changing the month never discards rows.
  final List<BudgetModel> all;

  /// Picker options for the add/edit form, loaded alongside the budgets so
  /// opening the form never blocks on a second request.
  final List<Category> categories;

  /// The month being viewed, normalised to its first day at midnight.
  final DateTime month;

  /// What the screen renders: the budgets whose period overlaps [month].
  final List<BudgetModel> visible;

  /// Totals over [visible].
  final BudgetsSummary summary;

  /// True while a refresh is in flight over already-visible content.
  final bool isRefreshing;

  const BudgetsLoaded({
    required this.all,
    required this.categories,
    required this.month,
    required this.visible,
    required this.summary,
    this.isRefreshing = false,
  });

  /// True when there is genuinely nothing to show.
  bool get isEmpty => all.isEmpty;

  /// True when budgets exist but none of them covers the selected month — a
  /// different message from "no budgets yet", and a different next action.
  bool get isFilteredEmpty => visible.isEmpty && all.isNotEmpty;

  BudgetsLoaded copyWith({
    List<BudgetModel>? all,
    List<Category>? categories,
    DateTime? month,
    List<BudgetModel>? visible,
    BudgetsSummary? summary,
    bool? isRefreshing,
  }) => BudgetsLoaded(
    all: all ?? this.all,
    categories: categories ?? this.categories,
    month: month ?? this.month,
    visible: visible ?? this.visible,
    summary: summary ?? this.summary,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  // `visible` is rebuilt as a new list on every projection, so identity is what
  // distinguishes two states here — the same reasoning as `TransactionsLoaded`.
  @override
  List<Object?> get props => <Object?>[
    all,
    categories,
    month,
    visible,
    summary,
    isRefreshing,
  ];
}

class BudgetsFailure extends BudgetsState {
  final Failure error;

  const BudgetsFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
