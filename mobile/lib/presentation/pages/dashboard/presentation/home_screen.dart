import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/mock/dashboard_mock_source.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/repos/dashboard_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/dashboard/bloc/dashboard_bloc.dart';
import 'package:family_expense_management/presentation/pages/dashboard/bloc/dashboard_cubit.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/balance_card.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_chart_card.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/financial_summary_strip.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/quick_actions.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/transaction_form_screen.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Tab 0 — the dashboard itself.
///
/// The shell (`presentation/dashboard.dart`) owns the bottom navigation; this
/// screen owns only the content of the home tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The design's 20px viewport margin (`container-padding: 1.25rem`).
  static const double _pagePadding = 20;

  late final DashboardBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = DashboardBloc()..add(const OnLoadDashboard());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Actions whose destination screens do not exist yet. Mirrors the toast
  /// pattern already used by `LoginScreen._showSoon`.
  void _showSoon() {
    EasyLoading.showToast(
      'dashboard.coming_soon'.tr(),
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }

  /// Opens the shared Add Transaction screen, then reloads on success.
  ///
  /// Pushed without route arguments on purpose: the form loads its own account
  /// and category options in that case, so the dashboard does not have to
  /// duplicate any part of the add flow. The refresh is what updates the
  /// balance card's totals, the summary strip, the spending donut and the
  /// recent-transactions list — all of which are derived from the same
  /// `MockStore` the form just wrote to.
  Future<void> _openAddTransaction() async {
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.addTransaction);

    if (result == true && mounted) {
      _bloc.add(const OnRefreshDashboard());
    }
  }

  /// Opens a recent-transactions row in the shared Edit Transaction screen.
  ///
  /// The account and category lists are passed empty on purpose:
  /// `TransactionFormBloc` loads its own options when either is empty, so the
  /// dashboard does not have to hold a copy of them just to open the form.
  Future<void> _openEditTransaction(TransactionModel transaction) async {
    final Object? result = await Navigator.of(context).pushNamed(
      AppRoutes.editTransaction,
      arguments: TransactionFormArgs(
        transaction: transaction,
        accounts: const [],
        categories: const [],
      ),
    );

    if (result == true && mounted) {
      _bloc.add(const OnRefreshDashboard());
    }
  }

  /// "عرض الكل" and the transactions tab are the same destination, so this
  /// switches tabs inside the shell rather than pushing a route.
  void _openTransactionsTab() {
    // The cubit lives above this screen in the shell. When the screen is pumped
    // standalone (e.g. in a widget test) there is no provider, so `read` throws
    // `ProviderNotFoundException` — fall back to the toast instead of crashing.
    try {
      context.read<DashboardCubit>().changeTab(MainTabs.transactions);
    } on ProviderNotFoundException {
      _showSoon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.dashboardBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashboardAppBar(onNotificationsPressed: _showSoon),
            Expanded(
              child: BlocBuilder<DashboardBloc, DashboardState>(
                bloc: _bloc,
                builder: (context, state) {
                  return switch (state) {
                    DashboardInitial() ||
                    DashboardLoading() => const _LoadingView(),
                    DashboardFailure(:final error) => _FailureView(
                      failure: error,
                      onRetry: () => _bloc.add(const OnLoadDashboard()),
                    ),
                    DashboardLoaded(:final data) => _LoadedView(
                      data: data,
                      pagePadding: _pagePadding,
                      onRefresh: () async =>
                          _bloc.add(const OnRefreshDashboard()),
                      onAddTransaction: _openAddTransaction,
                      onTransfer: _showSoon,
                      onViewAll: _openTransactionsTab,
                      onTransactionTap: _openEditTransaction,
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
  final DashboardData data;
  final double pagePadding;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddTransaction;
  final VoidCallback onTransfer;
  final VoidCallback onViewAll;
  final void Function(TransactionModel) onTransactionTap;

  const _LoadedView({
    required this.data,
    required this.pagePadding,
    required this.onRefresh,
    required this.onAddTransaction,
    required this.onTransfer,
    required this.onViewAll,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = pagePadding.w;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Vertical padding only: the summary strip scrolls edge to edge and
        // applies the horizontal margin itself.
        padding: EdgeInsets.only(top: 24.h, bottom: 24.h),
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: horizontal),
            child: BalanceCard(
              summary: data.summary,
              // TODO(backend): the masked number has no schema backing. It is
              // read straight from the mock source so that the moment the repo
              // stops being mocked, this row disappears instead of silently
              // showing a fabricated account number.
              maskedAccountNumber: DashboardRepo.useMock
                  ? DashboardMockSource.maskedAccountNumber
                  : null,
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: horizontal),
            child: QuickActions(
              onAddTransaction: onAddTransaction,
              onTransfer: onTransfer,
            ),
          ),
          SizedBox(height: 24.h),
          FinancialSummaryStrip(
            summary: data.summary,
            horizontalPadding: horizontal,
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: horizontal),
            child: CategoryChartCard(summary: data.summary),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: horizontal),
            child: RecentTransactionsSection(
              transactions: data.recentTransactions,
              onViewAll: onViewAll,
              onTransactionTap: onTransactionTap,
            ),
          ),
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
    // `flutter_spinkit`, which is only a transitive dependency and is not
    // declared in pubspec.yaml.
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
              key: const Key('dashboard_retry'),
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
