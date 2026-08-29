import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/picker_sheet.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/transactions/bloc/transactions_bloc.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/transaction_form_screen.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transaction_day_header.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transaction_filter_chips.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transaction_row.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transaction_search_field.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transactions_app_bar.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transactions_empty_state.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Tab 1 — the transactions list.
///
/// Owns its own `TransactionsBloc`, exactly like `HomeScreen` owns its
/// `DashboardBloc`, so the shell does not have to know about either.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  /// The design's 20px viewport margin (`container-padding: 1.25rem`).
  static const double _pagePadding = 20;

  late final TransactionsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TransactionsBloc()..add(const OnLoadTransactions());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Opens Add, then refreshes on success.
  ///
  /// The refresh is what makes the new row appear: the form wrote it to the
  /// shared `MockStore`, and reloading re-reads that store.
  Future<void> _openAdd(TransactionsLoaded state) async {
    await _openForm(
      transaction: null,
      accounts: state.accounts,
      categories: state.categories,
    );
  }

  Future<void> _openEdit(
    TransactionsLoaded state,
    TransactionModel transaction,
  ) async {
    await _openForm(
      transaction: transaction,
      accounts: state.accounts,
      categories: state.categories,
    );
  }

  Future<void> _openForm({
    required TransactionModel? transaction,
    required List<Account> accounts,
    required List<Category> categories,
  }) async {
    final Object? result = await Navigator.of(context).pushNamed(
      transaction == null
          ? AppRoutes.addTransaction
          : AppRoutes.editTransaction,
      arguments: TransactionFormArgs(
        transaction: transaction,
        accounts: accounts,
        categories: categories,
      ),
    );

    // The form pops `true` only after a successful save.
    if (result == true && mounted) {
      _bloc.add(const OnRefreshTransactions());
    }
  }

  void _clearFilters() {
    _bloc
      ..add(const OnSearchChanged(''))
      ..add(const OnTypeFilterChanged(TransactionTypeFilter.all))
      ..add(const OnPeriodFilterChanged(TransactionPeriodFilter.all))
      ..add(const OnPersonFilterChanged(null))
      ..add(const OnCategoryFilterChanged(null));
  }

  /// Id standing for "no filter" inside a picker.
  ///
  /// `PickerSheet` resolves to null when the sheet is dismissed, which would
  /// otherwise be indistinguishable from choosing "everyone". No real row
  /// carries id 0, so it is unambiguous.
  static const int _clearedId = 0;

  Future<void> _pickPerson(TransactionsLoaded state) async {
    final int? picked = await PickerSheet.show<int>(
      context: context,
      title: 'transactions.pick_person'.tr(),
      selected: state.personFilter ?? _clearedId,
      options: [
        PickerOption<int>(
          value: _clearedId,
          label: 'transactions.filter_everyone'.tr(),
          icon: Icons.groups_outlined,
        ),
        for (final m in state.members)
          if (m.id != null)
            PickerOption<int>(
              value: m.id!,
              label: m.name ?? '',
              // The role, so a parent can tell their children apart from the
              // other parent at a glance.
              subtitle: m.isParent
                  ? 'auth.parent'.tr()
                  : 'auth.family_member'.tr(),
              icon: m.isParent ? Icons.shield_outlined : Icons.person_outline,
            ),
      ],
    );

    if (picked == null || !mounted) return;
    _bloc.add(OnPersonFilterChanged(picked == _clearedId ? null : picked));
  }

  Future<void> _pickCategory(TransactionsLoaded state) async {
    final int? picked = await PickerSheet.show<int>(
      context: context,
      title: 'transactions.pick_category'.tr(),
      selected: state.categoryFilter ?? _clearedId,
      options: [
        PickerOption<int>(
          value: _clearedId,
          label: 'transactions.filter_all_categories'.tr(),
          icon: Icons.apps_outlined,
        ),
        for (final c in state.categories)
          if (c.id != null)
            PickerOption<int>(
              value: c.id!,
              label: c.name ?? '',
              icon: CategoryVisuals.iconFor(c.id),
            ),
      ],
    );

    if (picked == null || !mounted) return;
    _bloc.add(OnCategoryFilterChanged(picked == _clearedId ? null : picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.dashboardBackground,
      floatingActionButton: BlocBuilder<TransactionsBloc, TransactionsState>(
        bloc: _bloc,
        builder: (context, state) {
          // The FAB would have nothing to hand the form before the accounts and
          // categories have loaded, so it appears with the content.
          if (state is! TransactionsLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            key: const Key('transactions_add_fab'),
            onPressed: () => _openAdd(state),
            backgroundColor: ColorsApp.primaryGreenPressed,
            foregroundColor: ColorsApp.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            tooltip: 'dashboard.add_transaction'.tr(),
            child: Icon(Icons.add, size: 28.r),
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TransactionsAppBar(),
            Expanded(
              child: BlocBuilder<TransactionsBloc, TransactionsState>(
                bloc: _bloc,
                builder: (context, state) {
                  return switch (state) {
                    TransactionsInitial() ||
                    TransactionsLoading() => const _LoadingView(),
                    TransactionsFailure(:final error) => _FailureView(
                      failure: error,
                      onRetry: () => _bloc.add(const OnLoadTransactions()),
                    ),
                    TransactionsLoaded() => _LoadedView(
                      state: state,
                      pagePadding: _pagePadding,
                      onRefresh: () async =>
                          _bloc.add(const OnRefreshTransactions()),
                      onSearchChanged: (q) => _bloc.add(OnSearchChanged(q)),
                      onTypeChanged: (f) => _bloc.add(OnTypeFilterChanged(f)),
                      onPeriodChanged: (f) =>
                          _bloc.add(OnPeriodFilterChanged(f)),
                      onClearFilters: _clearFilters,
                      // Offered only when there is more than one person to
                      // choose between, which for a member is never: the
                      // server hands them only themselves.
                      onPickPerson: state.canFilterByPerson
                          ? () => _pickPerson(state)
                          : null,
                      onPickCategory: state.categories.isEmpty
                          ? null
                          : () => _pickCategory(state),
                      onTransactionTap: (t) => _openEdit(state, t),
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
  final TransactionsLoaded state;
  final double pagePadding;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TransactionTypeFilter> onTypeChanged;
  final ValueChanged<TransactionPeriodFilter> onPeriodChanged;
  final VoidCallback? onPickPerson;
  final VoidCallback? onPickCategory;
  final VoidCallback onClearFilters;
  final void Function(TransactionModel) onTransactionTap;

  const _LoadedView({
    required this.state,
    required this.pagePadding,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onPeriodChanged,
    this.onPickPerson,
    this.onPickCategory,
    required this.onClearFilters,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontal = pagePadding.w;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 20.h, bottom: 96.h),
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: horizontal),
            child: TransactionSearchField(
              initialValue: state.query,
              onChanged: onSearchChanged,
            ),
          ),
          SizedBox(height: 20.h),
          // Full-bleed: the chips scroll edge to edge and apply the margin
          // inside their own scroll view.
          TransactionFilterChips(
            typeFilter: state.typeFilter,
            periodFilter: state.periodFilter,
            onTypeChanged: onTypeChanged,
            onPeriodChanged: onPeriodChanged,
            selectedPerson: state.selectedPerson,
            selectedCategory: state.selectedCategory,
            onPickPerson: onPickPerson,
            onPickCategory: onPickCategory,
            horizontalPadding: horizontal,
          ),
          SizedBox(height: 8.h),
          if (state.groups.isEmpty)
            TransactionsEmptyState(
              isFiltered: state.isFilteredEmpty,
              onClearFilters: state.hasActiveFilters ? onClearFilters : null,
            )
          else
            for (final group in state.groups) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  16.h,
                  horizontal,
                  12.h,
                ),
                child: TransactionDayHeader(day: group.day),
              ),
              for (int i = 0; i < group.transactions.length; i++) ...[
                if (i > 0) SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: horizontal,
                  ),
                  child: TransactionRow(
                    transaction: group.transactions[i],
                    onTap: () => onTransactionTap(group.transactions[i]),
                    // The row names the spender only when it is somebody other
                    // than the reader.
                    viewerId: LocalsApp.user?.id,
                  ),
                ),
              ],
            ],
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    // Deliberately not `DefaultLoader`: that shared widget depends on
    // `flutter_spinkit`, which is not declared in pubspec.yaml.
    return const Center(
      child: CircularProgressIndicator(
        color: ColorsApp.primaryGreenPressed,
        strokeWidth: 3,
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const _FailureView({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Deliberately not the shared `ErrorMessage`: it renders
    // `assets/images/*.svg`, and this repository ships no `assets/images/`.
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40.r,
              color: ColorsApp.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              failure.message,
              style: TextStyleApp.dashboardStatLabel,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton(
              key: const Key('transactions_retry'),
              onPressed: onRetry,
              child: Text(
                'dashboard.retry'.tr(),
                style: TextStyleApp.dashboardSectionAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
