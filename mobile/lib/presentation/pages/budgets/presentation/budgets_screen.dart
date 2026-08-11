import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/presentation/pages/budgets/bloc/budgets_bloc.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/budget_form_screen.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_card.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_month_header.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_summary_grid.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budgets_empty_state.dart';
import 'package:family_expense_management/presentation/widgets/main_tab_app_bar.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Tab 2 — the budgets list.
///
/// Owns its own `BudgetsBloc`, exactly like `TransactionsScreen` owns its
/// `TransactionsBloc`, so the shell does not have to know about either.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  /// The design's 20px viewport margin (`container-padding: 1.25rem`).
  static const double _pagePadding = 20;

  late final BudgetsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BudgetsBloc()..add(const OnLoadBudgets());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _showSoon() {
    EasyLoading.showToast(
      'dashboard.coming_soon'.tr(),
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }

  /// Opens Add, then refreshes on success.
  ///
  /// The refresh is what makes the new card appear: the form wrote it to the
  /// shared `MockStore`, and reloading re-reads that store.
  Future<void> _openAdd(BudgetsLoaded state) async {
    await _openForm(
      budget: null,
      categories: state.categories,
      month: state.month,
    );
  }

  Future<void> _openEdit(BudgetsLoaded state, BudgetModel budget) async {
    await _openForm(
      budget: budget,
      categories: state.categories,
      month: state.month,
    );
  }

  Future<void> _openForm({
    required BudgetModel? budget,
    required List<Category> categories,
    required DateTime month,
  }) async {
    final Object? result = await Navigator.of(context).pushNamed(
      budget == null ? AppRoutes.addBudget : AppRoutes.editBudget,
      arguments: BudgetFormArgs(
        budget: budget,
        categories: categories,
        month: month,
      ),
    );

    // The form pops `true` only after a successful save.
    if (result == true && mounted) {
      _bloc.add(const OnRefreshBudgets());
    }
  }

  void _stepMonth(BudgetsLoaded state, int delta) {
    _bloc.add(
      OnBudgetMonthChanged(
        DateTime(state.month.year, state.month.month + delta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.dashboardBackground,
      floatingActionButton: BlocBuilder<BudgetsBloc, BudgetsState>(
        bloc: _bloc,
        builder: (context, state) {
          // The FAB would have nothing to hand the form before the categories
          // have loaded, so it appears with the content.
          if (state is! BudgetsLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            key: const Key('budgets_add_fab'),
            onPressed: () => _openAdd(state),
            backgroundColor: ColorsApp.primaryGreenPressed,
            foregroundColor: ColorsApp.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            tooltip: 'budgets.add_title'.tr(),
            child: Icon(Icons.add, size: 28.r),
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MainTabAppBar(
              titleKey: 'tabs.budgets',
              onNotificationsPressed: _showSoon,
            ),
            Expanded(
              child: BlocBuilder<BudgetsBloc, BudgetsState>(
                bloc: _bloc,
                builder: (context, state) {
                  return switch (state) {
                    BudgetsInitial() ||
                    BudgetsLoading() => const AppLoadingView(),
                    BudgetsFailure(:final error) => AppFailureView(
                      failure: error,
                      retryKey: const Key('budgets_retry'),
                      onRetry: () => _bloc.add(const OnLoadBudgets()),
                    ),
                    BudgetsLoaded() => _LoadedView(
                      state: state,
                      pagePadding: _pagePadding,
                      onRefresh: () async =>
                          _bloc.add(const OnRefreshBudgets()),
                      onPreviousMonth: () => _stepMonth(state, -1),
                      onNextMonth: () => _stepMonth(state, 1),
                      onGoToCurrentMonth: () =>
                          _bloc.add(OnBudgetMonthChanged(DateTime.now())),
                      onBudgetTap: (b) => _openEdit(state, b),
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
  final BudgetsLoaded state;
  final double pagePadding;
  final Future<void> Function() onRefresh;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onGoToCurrentMonth;
  final void Function(BudgetModel) onBudgetTap;

  const _LoadedView({
    required this.state,
    required this.pagePadding,
    required this.onRefresh,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onGoToCurrentMonth,
    required this.onBudgetTap,
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
          BudgetMonthHeader(
            month: state.month,
            totalLimit: state.summary.totalLimit,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
          SizedBox(height: 16.h),
          BudgetSummaryGrid(
            totalSpent: state.summary.totalSpent,
            totalRemaining: state.summary.totalRemaining,
          ),
          SizedBox(height: 24.h),
          if (state.visible.isEmpty)
            BudgetsEmptyState(
              isMonthFiltered: state.isFilteredEmpty,
              onGoToCurrentMonth: state.isFilteredEmpty
                  ? onGoToCurrentMonth
                  : null,
            )
          else ...[
            Text(
              'budgets.by_category'.tr(),
              style: TextStyleApp.budgetsSectionLabel,
            ),
            SizedBox(height: 12.h),
            for (int i = 0; i < state.visible.length; i++) ...[
              if (i > 0) SizedBox(height: 16.h),
              BudgetCard(
                budget: state.visible[i],
                onTap: () => onBudgetTap(state.visible[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
