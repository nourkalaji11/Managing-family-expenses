import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/presentation/pages/accounts/bloc/accounts_bloc.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/account_form_screen.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/widgets/account_card.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/widgets/accounts_empty_state.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/widgets/accounts_total_card.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transaction_search_field.dart';
import 'package:family_expense_management/presentation/widgets/main_tab_app_bar.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Tab 3 — the accounts list.
///
/// Owns its own `AccountsBloc`, exactly like `BudgetsScreen` owns its
/// `BudgetsBloc`, so the shell does not have to know about either.
///
/// Two elements of the design are deliberately absent:
///   * the "توزيع الثروة العائلية" promo banner, which is a photographic asset
///     and this repository ships no `assets/images/`;
///   * the filter button beside the search field, which the design gives no
///     filter criteria for — `accounts` has one text column and one number, and
///     a control that opens nothing is worse than an absent one. The same
///     reasoning already removed the menu button from `MainTabAppBar`.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  /// The design's 20px viewport margin, matching every other tab.
  static const double _pagePadding = 20;

  late final AccountsBloc _bloc;

  /// Rebuilt when the query is cleared from the empty state, so the text field
  /// re-seeds itself with the new (empty) value.
  Key _searchKey = const ValueKey<int>(0);

  @override
  void initState() {
    super.initState();
    _bloc = AccountsBloc()..add(const OnLoadAccounts());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _clearSearch() {
    _bloc.add(const OnAccountsQueryChanged(''));
    setState(() {
      _searchKey = ValueKey<int>(DateTime.now().microsecondsSinceEpoch);
    });
  }

  Future<void> _openForm({
    required Account? account,
    required int transactionCount,
  }) async {
    final Object? result = await Navigator.of(context).pushNamed(
      account == null ? AppRoutes.addAccount : AppRoutes.editAccount,
      arguments: AccountFormArgs(
        account: account,
        transactionCount: transactionCount,
      ),
    );

    // The form pops `true` after a successful save and after a successful
    // delete. Both need the same refresh, so they are not distinguished here.
    if (result == true && mounted) {
      _bloc.add(const OnRefreshAccounts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.dashboardBackground,
      floatingActionButton: BlocBuilder<AccountsBloc, AccountsState>(
        bloc: _bloc,
        builder: (context, state) {
          // Appears with the content: adding an account before the list has
          // loaded would drop the user back onto a screen still spinning.
          if (state is! AccountsLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            key: const Key('accounts_add_fab'),
            onPressed: () => _openForm(account: null, transactionCount: 0),
            backgroundColor: ColorsApp.primaryGreenPressed,
            foregroundColor: ColorsApp.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            tooltip: 'accounts.add_title'.tr(),
            child: Icon(Icons.add, size: 28.r),
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const MainTabAppBar(titleKey: 'tabs.accounts'),
            Expanded(
              child: BlocBuilder<AccountsBloc, AccountsState>(
                bloc: _bloc,
                builder: (context, state) {
                  return switch (state) {
                    AccountsInitial() ||
                    AccountsLoading() => const AppLoadingView(),
                    AccountsFailure(:final error) => AppFailureView(
                      failure: error,
                      retryKey: const Key('accounts_retry'),
                      onRetry: () => _bloc.add(const OnLoadAccounts()),
                    ),
                    AccountsLoaded() => _LoadedView(
                      state: state,
                      searchKey: _searchKey,
                      pagePadding: _pagePadding,
                      onRefresh: () async =>
                          _bloc.add(const OnRefreshAccounts()),
                      onQueryChanged: (q) =>
                          _bloc.add(OnAccountsQueryChanged(q)),
                      onClearSearch: _clearSearch,
                      onAccountTap: (a) => _openForm(
                        account: a,
                        transactionCount: state.data.countFor(a.id),
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
  final AccountsLoaded state;
  final Key searchKey;
  final double pagePadding;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearSearch;
  final void Function(Account) onAccountTap;

  const _LoadedView({
    required this.state,
    required this.searchKey,
    required this.pagePadding,
    required this.onRefresh,
    required this.onQueryChanged,
    required this.onClearSearch,
    required this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontal = pagePadding.w;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // 96px of bottom room so the last card clears the FAB.
        padding: EdgeInsets.fromLTRB(horizontal, 20.h, horizontal, 96.h),
        children: [
          AccountsTotalCard(total: state.totalBalance),
          SizedBox(height: 20.h),
          TransactionSearchField(
            key: searchKey,
            initialValue: state.query,
            onChanged: onQueryChanged,
            hintKey: 'accounts.search_hint',
          ),
          SizedBox(height: 20.h),
          if (state.visible.isEmpty)
            AccountsEmptyState(
              isFiltered: state.isFilteredEmpty,
              onClearSearch: state.isFilteredEmpty ? onClearSearch : null,
            )
          else ...[
            Text(
              'accounts.section_label'.tr(),
              style: TextStyleApp.budgetsSectionLabel,
            ),
            SizedBox(height: 12.h),
            for (int i = 0; i < state.visible.length; i++) ...[
              if (i > 0) SizedBox(height: 12.h),
              AccountCard(
                // Keyed by id so Flutter reuses the right element when the
                // list is re-filtered rather than re-associating state by
                // position.
                key: ValueKey<int?>(state.visible[i].id),
                account: state.visible[i],
                transactionCount: state.data.countFor(state.visible[i].id),
                onTap: () => onAccountTap(state.visible[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
