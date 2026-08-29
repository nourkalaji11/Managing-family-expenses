import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/transfer_data.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/widgets/account_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/presentation/pages/transfers/bloc/transfers_list_bloc.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Past transfers, with an undo on each.
///
/// Reached from the history action in the transfer form's app bar. It is not a
/// tab of its own: transfers are a small, occasional slice of the ledger, and
/// they already appear individually in the transactions list — this screen
/// exists because that list shows the two halves separately, with no way to see
/// that they belong together or to reverse them as a pair.
///
/// Undo is the only write. There is no edit: changing one leg would leave the
/// other on its old amount and one balance wrong, which the server refuses
/// (422). Reversing and re-entering is the honest operation, and it is what the
/// undo does.
class TransfersHistoryScreen extends StatefulWidget {
  const TransfersHistoryScreen({super.key});

  @override
  State<TransfersHistoryScreen> createState() => _TransfersHistoryScreenState();
}

class _TransfersHistoryScreenState extends State<TransfersHistoryScreen> {
  static const double _pagePadding = 20;

  late final TransfersListBloc _bloc;

  /// Set when at least one transfer was undone, so the screen can tell the
  /// caller that balances moved and the dashboard needs a reload.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _bloc = TransfersListBloc()..add(const OnLoadTransfers());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Confirms before reversing.
  ///
  /// Not a formality: an undo moves two real balances, and the transfer cannot
  /// be restored from inside the app — it has to be entered again by hand.
  Future<void> _confirmUndo(TransferModel transfer) async {
    final String? groupId = transfer.groupId;
    if (groupId == null) return;

    final String amount =
        '${DashboardFormatter.isolatedAmount(transfer.amount)} '
        '${'dashboard.currency_sar'.tr()}';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorsApp.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'transfers.undo_title'.tr(),
          style: TextStyleApp.dashboardSectionTitle,
        ),
        content: Text(
          'transfers.undo_body'.tr(
            namedArgs: {
              'amount': amount,
              'from': transfer.fromAccount?.name ?? '',
              'to': transfer.toAccount?.name ?? '',
            },
          ),
          style: TextStyleApp.dashboardStatLabel,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'accounts.cancel'.tr(),
              style: TextStyleApp.dashboardSectionAction,
            ),
          ),
          TextButton(
            key: const Key('transfer_undo_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'transfers.undo_confirm'.tr(),
              style: TextStyleApp.dashboardSectionAction.copyWith(
                color: ColorsApp.errorRed,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _bloc.add(OnUndoTransfer(groupId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // `true` only when something actually changed, so the caller does not
        // reload on a screen the user merely looked at.
        Navigator.of(context).pop(_changed);
      },
      child: BlocConsumer<TransfersListBloc, TransfersListState>(
        bloc: _bloc,
        listenWhen: (previous, current) =>
            current is TransfersListLoaded &&
            (current.writeFailure != null ||
                (previous is TransfersListLoaded &&
                    previous.undoneGroupId != current.undoneGroupId)),
        listener: (context, state) {
          final loaded = state as TransfersListLoaded;
          if (loaded.writeFailure != null) {
            EasyLoading.showToast(
              loaded.writeFailure!.message,
              toastPosition: EasyLoadingToastPosition.bottom,
            );
            return;
          }
          _changed = true;
          EasyLoading.showToast(
            'transfers.undone'.tr(),
            toastPosition: EasyLoadingToastPosition.bottom,
          );
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: ColorsApp.dashboardBackground,
            appBar: AppBar(
              backgroundColor: ColorsApp.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleSpacing: 0,
              title: Text(
                'transfers.history_title'.tr(),
                style: TextStyleApp.dashboardAppBarTitle,
              ),
              iconTheme: const IconThemeData(color: ColorsApp.onSurface),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: switch (state) {
                TransfersListInitial() ||
                TransfersListLoading() => const AppLoadingView(),
                TransfersListFailure(:final error) => AppFailureView(
                  failure: error,
                  retryKey: const Key('transfers_history_retry'),
                  onRetry: () => _bloc.add(const OnLoadTransfers()),
                ),
                TransfersListLoaded() => _LoadedView(
                  state: state,
                  horizontal: horizontal,
                  onRefresh: () async => _bloc.add(const OnRefreshTransfers()),
                  onUndo: _confirmUndo,
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final TransfersListLoaded state;
  final double horizontal;
  final Future<void> Function() onRefresh;
  final void Function(TransferModel) onUndo;

  const _LoadedView({
    required this.state,
    required this.horizontal,
    required this.onRefresh,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: state.isEmpty
          // Scrollable even when empty, so pull-to-refresh still works.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [SizedBox(height: 120.h), const _EmptyState()],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(horizontal, 20.h, horizontal, 32.h),
              itemCount: state.transfers.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final TransferModel transfer = state.transfers[index];
                return _TransferCard(
                  key: ValueKey<String?>(transfer.groupId),
                  transfer: transfer,
                  isUndoing: state.isUndoing(transfer.groupId),
                  onUndo: () => onUndo(transfer),
                );
              },
            ),
    );
  }
}

/// One transfer: amount, the two accounts with an arrow between them, the date,
/// and the undo action.
class _TransferCard extends StatelessWidget {
  final TransferModel transfer;
  final bool isUndoing;
  final VoidCallback onUndo;

  const _TransferCard({
    super.key,
    required this.transfer,
    required this.isUndoing,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final String? note = transfer.description?.trim();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: ColorsApp.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.swap_horiz,
                  size: 22.r,
                  color: ColorsApp.primaryGreenPressed,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DashboardFormatter.isolatedAmount(transfer.amount)} '
                      '${'dashboard.currency_sar'.tr()}',
                      style: TextStyleApp.transactionsRowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      DashboardFormatter.plainDate(transfer.date),
                      style: TextStyleApp.transactionsRowSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUndoing)
                SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                    color: ColorsApp.errorRed,
                    strokeWidth: 2.5,
                  ),
                )
              else
                IconButton(
                  key: ValueKey<String>('transfer_undo_${transfer.groupId}'),
                  onPressed: onUndo,
                  iconSize: 20.r,
                  color: ColorsApp.errorRed,
                  tooltip: 'transfers.undo_title'.tr(),
                  icon: const Icon(Icons.undo),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          _Route(
            from: transfer.fromAccount?.name,
            to: transfer.toAccount?.name,
          ),
          if (note != null && note.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              note,
              style: TextStyleApp.dashboardCaption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// "from → to", where the arrow points the way the money went.
///
/// `arrow_forward` mirrors itself under an RTL directionality, so the direction
/// reads correctly in both languages without a second glyph.
class _Route extends StatelessWidget {
  final String? from;
  final String? to;

  const _Route({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: ColorsApp.inputBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(child: _AccountChip(name: from)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Icon(
              Icons.arrow_forward,
              size: 16.r,
              color: ColorsApp.outline,
            ),
          ),
          Expanded(child: _AccountChip(name: to)),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String? name;

  const _AccountChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          AccountVisuals.iconFor(name),
          size: 16.r,
          color: ColorsApp.onSurfaceVariant,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            // A deleted account leaves its transfers behind with a null
            // relation, so this is a real case rather than defensive padding.
            name ?? 'accounts.untitled'.tr(),
            style: TextStyleApp.transactionsRowSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_horiz,
            size: 40.r,
            color: ColorsApp.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'transfers.empty_title'.tr(),
            style: TextStyleApp.transactionsEmptyTitle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            'transfers.empty_body'.tr(),
            style: TextStyleApp.dashboardStatLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
