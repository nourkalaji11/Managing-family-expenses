import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/presentation/pages/categories/bloc/categories_bloc.dart';
import 'package:family_expense_management/presentation/pages/categories/presentation/category_form_screen.dart';
import 'package:family_expense_management/presentation/pages/categories/presentation/widgets/categories_empty_state.dart';
import 'package:family_expense_management/presentation/pages/categories/presentation/widgets/category_tile.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transaction_search_field.dart';
import 'package:family_expense_management/presentation/widgets/main_tab_app_bar.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Tab 4 — the categories grid.
///
/// Owns its own `CategoriesBloc`, exactly like the other three feature tabs.
///
/// One element of the design is deliberately absent: the "رؤية ذكية" insight
/// card ("لقد أنفقت العائلة ٤٠٪ من الميزانية على الطعام هذا الشهر. حاول تقليل
/// الطلبات الخارجية"). Its first half is a figure this screen could compute, but
/// its second half is advice, and nothing in this app or on the server generates
/// advice. Rendering a fixed sentence dressed as an insight would be putting
/// invented financial guidance in front of the user.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const double _pagePadding = 20;

  late final CategoriesBloc _bloc;

  /// Rebuilt when the query is cleared from the empty state, so the text field
  /// re-seeds itself with the new (empty) value.
  Key _searchKey = const ValueKey<int>(0);

  @override
  void initState() {
    super.initState();
    _bloc = CategoriesBloc()..add(const OnLoadCategories());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _clearSearch() {
    _bloc.add(const OnCategoriesQueryChanged(''));
    setState(() {
      _searchKey = ValueKey<int>(DateTime.now().microsecondsSinceEpoch);
    });
  }

  Future<void> _openForm({
    required Category? category,
    required int usageCount,
  }) async {
    final Object? result = await Navigator.of(context).pushNamed(
      category == null ? AppRoutes.addCategory : AppRoutes.editCategory,
      arguments: CategoryFormArgs(category: category, usageCount: usageCount),
    );

    if (result == true && mounted) {
      _bloc.add(const OnRefreshCategories());
    }
  }

  /// Transactions plus budgets referencing [id] — what the server counts when
  /// it decides whether a delete may go through.
  int _usageOf(CategoriesLoaded state, int? id) {
    if (id == null) return 0;
    return (state.data.transactionCounts[id] ?? 0) +
        (state.data.budgetCounts[id] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.dashboardBackground,
      floatingActionButton: BlocBuilder<CategoriesBloc, CategoriesState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is! CategoriesLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            key: const Key('categories_add_fab'),
            onPressed: () => _openForm(category: null, usageCount: 0),
            backgroundColor: ColorsApp.primaryGreenPressed,
            foregroundColor: ColorsApp.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            tooltip: 'categories.add_title'.tr(),
            child: Icon(Icons.add, size: 28.r),
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const MainTabAppBar(titleKey: 'tabs.categories'),
            Expanded(
              child: BlocBuilder<CategoriesBloc, CategoriesState>(
                bloc: _bloc,
                builder: (context, state) {
                  return switch (state) {
                    CategoriesInitial() ||
                    CategoriesLoading() => const AppLoadingView(),
                    CategoriesFailure(:final error) => AppFailureView(
                      failure: error,
                      retryKey: const Key('categories_retry'),
                      onRetry: () => _bloc.add(const OnLoadCategories()),
                    ),
                    CategoriesLoaded() => _LoadedView(
                      state: state,
                      searchKey: _searchKey,
                      pagePadding: _pagePadding,
                      onRefresh: () async =>
                          _bloc.add(const OnRefreshCategories()),
                      onQueryChanged: (q) =>
                          _bloc.add(OnCategoriesQueryChanged(q)),
                      onClearSearch: _clearSearch,
                      onAdd: () => _openForm(category: null, usageCount: 0),
                      onCategoryTap: (c) => _openForm(
                        category: c,
                        usageCount: _usageOf(state, c.id),
                      ),
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final CategoriesLoaded state;
  final Key searchKey;
  final double pagePadding;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onAdd;
  final void Function(Category) onCategoryTap;

  const _LoadedView({
    required this.state,
    required this.searchKey,
    required this.pagePadding,
    required this.onRefresh,
    required this.onQueryChanged,
    required this.onClearSearch,
    required this.onAdd,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontal = pagePadding.w;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 20.h, horizontal, 96.h),
        children: [
          Text(
            'categories.subtitle'.tr(),
            style: TextStyleApp.dashboardStatLabel,
          ),
          SizedBox(height: 16.h),
          TransactionSearchField(
            key: searchKey,
            initialValue: state.query,
            onChanged: onQueryChanged,
            hintKey: 'categories.search_hint',
          ),
          SizedBox(height: 20.h),
          // The filtered-empty case gets a message rather than a lone add tile:
          // offering "new category" as the only answer to "nothing matched your
          // search" would be answering a different question.
          if (state.isFilteredEmpty)
            CategoriesEmptyState(isFiltered: true, onClearSearch: onClearSearch)
          else
            _Grid(
              state: state,
              onAdd: onAdd,
              onCategoryTap: onCategoryTap,
            ),
        ],
      ),
    );
  }
}

/// The two-column grid, with the add tile always last.
class _Grid extends StatelessWidget {
  final CategoriesLoaded state;
  final VoidCallback onAdd;
  final void Function(Category) onCategoryTap;

  const _Grid({
    required this.state,
    required this.onAdd,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Inside a ListView, so the grid must not scroll or size itself.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        // Slightly taller than wide, which is what the design's tiles are: a
        // 52px icon over two lines of text does not fit a square at small text
        // scales.
        childAspectRatio: 0.95,
      ),
      // Exactly as many cells as there is content for, plus the add tile. No
      // blank filler cell is ever emitted.
      itemCount: state.visible.length + 1,
      itemBuilder: (context, index) {
        if (index == state.visible.length) {
          return CategoryAddTile(key: const Key('category_add_tile'), onTap: onAdd);
        }

        final Category category = state.visible[index];
        return CategoryTile(
          // Keyed by id so Flutter reuses the right element when the grid is
          // re-filtered rather than re-associating state by position.
          key: ValueKey<int?>(category.id),
          category: category,
          index: index,
          transactionCount: state.data.countFor(category.id),
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }
}
