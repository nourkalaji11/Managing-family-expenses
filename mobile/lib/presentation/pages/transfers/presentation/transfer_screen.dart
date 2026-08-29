import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/widgets/account_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/picker_sheet.dart';
import 'package:family_expense_management/presentation/pages/transfers/bloc/transfer_bloc.dart';
import 'package:family_expense_management/presentation/widgets/labelled_text_field.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Moves money between two of the family's accounts.
///
/// Pushed from the dashboard's "تحويل" quick action, which until now showed a
/// "coming soon" toast.
///
/// The transfer is stored as two linked transaction rows, so it appears in the
/// transactions list and both balances move — but it is excluded from the
/// income and expense totals, because nothing entered or left the family. See
/// `DashboardSummary.from`.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  static const double _pagePadding = 20;

  late final TransferBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TransferBloc()..add(const OnTransferFormStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _pickAccount({
    required TransferState state,
    required bool isSource,
  }) async {
    // The account already chosen on the *other* side is excluded from the list
    // rather than left in to be rejected: the server's `different` rule makes
    // it invalid, and offering an option that can only produce an error is
    // worse than not offering it.
    final int? otherId = isSource ? state.toAccountId : state.fromAccountId;

    final int? picked = await PickerSheet.show<int>(
      context: context,
      title: isSource ? 'transfers.from'.tr() : 'transfers.to'.tr(),
      selected: isSource ? state.fromAccountId : state.toAccountId,
      options: [
        for (final a in state.accounts)
          if (a.id != null && a.id != otherId)
            PickerOption<int>(
              value: a.id!,
              label: a.name ?? '',
              subtitle:
                  '${DashboardFormatter.isolatedAmount(a.balance)} '
                  '${'dashboard.currency_sar'.tr()}',
              icon: AccountVisuals.iconFor(a.name),
            ),
      ],
    );

    if (picked == null || !mounted) return;

    _bloc.add(
      isSource ? OnTransferFromChanged(picked) : OnTransferToChanged(picked),
    );
  }

  Future<void> _pickCategory(TransferState state) async {
    final int? picked = await PickerSheet.show<int>(
      context: context,
      title: 'transactions.select_category'.tr(),
      selected: state.categoryId,
      options: [
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
    _bloc.add(OnTransferCategoryChanged(picked));
  }

  /// Opens the history, and forwards its "something changed" answer.
  ///
  /// An undo in there moves two balances, so the dashboard this screen was
  /// pushed from has to reload — the same signal a successful transfer sends.
  Future<void> _openHistory() async {
    final Object? changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.transfersHistory);

    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickDate(TransferState state) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(now.year - 5),
      // A transfer cannot happen in the future, same rule the transaction form
      // applies to its own date.
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked != null && mounted) {
      _bloc.add(OnTransferDateChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<TransferBloc, TransferState>(
      bloc: _bloc,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == TransferStatus.success) {
          EasyLoading.showToast(
            'transfers.done'.tr(),
            toastPosition: EasyLoadingToastPosition.bottom,
          );
          // `true` tells the dashboard to refresh: both balances moved.
          Navigator.of(context).pop(true);
        } else if (state.status == TransferStatus.failure) {
          EasyLoading.showToast(
            state.failure?.message ?? 'errorglobal'.tr(),
            toastPosition: EasyLoadingToastPosition.bottom,
          );
        }
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
              'dashboard.transfer'.tr(),
              style: TextStyleApp.dashboardAppBarTitle,
            ),
            iconTheme: const IconThemeData(color: ColorsApp.onSurface),
            actions: [
              // The history is reached from here rather than from a tab of its
              // own: transfers are an occasional slice of the ledger, and this
              // is the only screen where the user is already thinking about
              // them.
              IconButton(
                key: const Key('transfer_history'),
                onPressed: _openHistory,
                iconSize: 22.r,
                tooltip: 'transfers.history_title'.tr(),
                icon: const Icon(Icons.history),
              ),
            ],
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
            child: _body(state, horizontal),
          ),
        );
      },
    );
  }

  Widget _body(TransferState state, double horizontal) {
    if (state.isLoading) return const AppLoadingView();

    if (state.status == TransferStatus.loadFailure) {
      return AppFailureView(
        failure: state.failure!,
        retryKey: const Key('transfer_retry'),
        onRetry: () => _bloc.add(const OnTransferFormStarted()),
      );
    }

    // A transfer needs somewhere to come from and somewhere to go. Showing the
    // form with one account would be offering a control that cannot be
    // completed.
    if (state.hasTooFewAccounts) {
      return _NotEnoughAccounts(horizontal: horizontal);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 20.h, horizontal, 20.h),
            children: [
              _AmountCard(
                state: state,
                onChanged: (v) => _bloc.add(OnTransferAmountChanged(v)),
              ),
              SizedBox(height: 20.h),
              _RouteCard(
                state: state,
                onPickFrom: () => _pickAccount(state: state, isSource: true),
                onPickTo: () => _pickAccount(state: state, isSource: false),
                onSwap: () => _bloc.add(const OnTransferSwapAccounts()),
              ),
              SizedBox(height: 20.h),
              _DetailsCard(
                state: state,
                onPickCategory: () => _pickCategory(state),
                onPickDate: () => _pickDate(state),
                onDescriptionChanged: (v) =>
                    _bloc.add(OnTransferDescriptionChanged(v)),
              ),
            ],
          ),
        ),
        _SubmitBar(
          state: state,
          horizontalPadding: horizontal,
          onPressed: () => _bloc.add(const OnSubmitTransfer()),
        ),
      ],
    );
  }
}

/// The amount, as the screen's hero — the one number the whole action is about.
class _AmountCard extends StatelessWidget {
  final TransferState state;
  final ValueChanged<String> onChanged;

  const _AmountCard({required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final String? errorKey = state.showErrors ? state.errors.amount : null;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelledTextField(
            key: const Key('transfer_amount'),
            label: 'transfers.amount_label'.tr(),
            hint: '0.00',
            initialValue: state.amountInput,
            onChanged: onChanged,
            errorKey: errorKey,
            suffixText: 'dashboard.currency_sar'.tr(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                TransferBloc.amountInputPattern,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// From-account, swap button, to-account — plus the balance each would be left
/// with, so the consequence is visible before committing.
class _RouteCard extends StatelessWidget {
  final TransferState state;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;

  const _RouteCard({
    required this.state,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountRow(
            fieldKey: const Key('transfer_from'),
            label: 'transfers.from'.tr(),
            account: state.fromAccount,
            projected: state.projectedFromBalance,
            errorKey: state.showErrors ? state.errors.fromAccount : null,
            onTap: onPickFrom,
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.center,
            child: IconButton(
              key: const Key('transfer_swap'),
              onPressed: onSwap,
              tooltip: 'transfers.swap'.tr(),
              iconSize: 22.r,
              color: ColorsApp.primaryGreenPressed,
              icon: const Icon(Icons.swap_vert),
            ),
          ),
          SizedBox(height: 8.h),
          _AccountRow(
            fieldKey: const Key('transfer_to'),
            label: 'transfers.to'.tr(),
            account: state.toAccount,
            projected: state.projectedToBalance,
            errorKey: state.showErrors ? state.errors.toAccount : null,
            onTap: onPickTo,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final Account? account;
  final num? projected;
  final String? errorKey;
  final VoidCallback onTap;

  const _AccountRow({
    required this.fieldKey,
    required this.label,
    required this.account,
    required this.projected,
    required this.errorKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorKey != null;
    final BorderRadius radius = BorderRadius.circular(14.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyleApp.transactionsFieldLabel),
        SizedBox(height: 8.h),
        Material(
          color: ColorsApp.inputBackground,
          borderRadius: radius,
          child: InkWell(
            key: fieldKey,
            onTap: onTap,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: hasError
                      ? ColorsApp.errorRed
                      : ColorsApp.outlineVariant,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 14.h,
                  horizontal: 16.w,
                ),
                child: Row(
                  children: [
                    Icon(
                      AccountVisuals.iconFor(account?.name),
                      size: 20.r,
                      color: ColorsApp.primaryGreenPressed,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account?.name ?? 'transactions.select_account'.tr(),
                            style: TextStyleApp.transactionsFieldValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (projected != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              'transfers.after_balance'.tr(
                                namedArgs: {
                                  'amount':
                                      '${DashboardFormatter.isolatedAmount(projected)} '
                                      '${'dashboard.currency_sar'.tr()}',
                                },
                              ),
                              style: TextStyleApp.dashboardCaption.copyWith(
                                // A projected negative balance is allowed — an
                                // overdrawn card is real — but it is worth
                                // seeing before the tap, not after.
                                color: (projected ?? 0) < 0
                                    ? ColorsApp.errorRed
                                    : ColorsApp.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.expand_more,
                      size: 20.r,
                      color: ColorsApp.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(errorKey!.tr(), style: TextStyleApp.transactionsFieldError),
        ],
      ],
    );
  }
}

/// Category, date and an optional note.
class _DetailsCard extends StatelessWidget {
  final TransferState state;
  final VoidCallback onPickCategory;
  final VoidCallback onPickDate;
  final ValueChanged<String> onDescriptionChanged;

  const _DetailsCard({
    required this.state,
    required this.onPickCategory,
    required this.onPickDate,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TapRow(
            fieldKey: const Key('transfer_category'),
            label: 'transactions.category'.tr(),
            value: state.category?.name ??
                'transactions.select_category'.tr(),
            icon: Icons.label_outline,
            errorKey: state.showErrors ? state.errors.category : null,
            onTap: onPickCategory,
          ),
          SizedBox(height: 8.h),
          // The category is filler, and saying so is better than letting the
          // user wonder why an internal move needs one.
          Text(
            'transfers.category_hint'.tr(),
            style: TextStyleApp.dashboardCaption,
          ),
          SizedBox(height: 20.h),
          _TapRow(
            fieldKey: const Key('transfer_date'),
            label: 'transactions.date'.tr(),
            value: DashboardFormatter.fullDate(state.date),
            icon: Icons.calendar_today_outlined,
            errorKey: null,
            onTap: onPickDate,
          ),
          SizedBox(height: 20.h),
          LabelledTextField(
            key: const Key('transfer_description'),
            label: 'transactions.description'.tr(),
            hint: 'transactions.description_hint'.tr(),
            initialValue: state.description,
            onChanged: onDescriptionChanged,
            icon: Icons.notes_outlined,
            // Backend rule: `nullable|string|max:255`.
            maxLength: 255,
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final String value;
  final IconData icon;
  final String? errorKey;
  final VoidCallback onTap;

  const _TapRow({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.icon,
    required this.errorKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorKey != null;
    final BorderRadius radius = BorderRadius.circular(14.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyleApp.transactionsFieldLabel),
        SizedBox(height: 8.h),
        Material(
          color: ColorsApp.inputBackground,
          borderRadius: radius,
          child: InkWell(
            key: fieldKey,
            onTap: onTap,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: hasError
                      ? ColorsApp.errorRed
                      : ColorsApp.outlineVariant,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 16.h,
                  horizontal: 16.w,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyleApp.transactionsFieldValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(icon, size: 20.r, color: ColorsApp.outline),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(errorKey!.tr(), style: TextStyleApp.transactionsFieldError),
        ],
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final TransferState state;
  final double horizontalPadding;
  final VoidCallback onPressed;

  const _SubmitBar({
    required this.state,
    required this.horizontalPadding,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12.h,
        horizontalPadding,
        16.h,
      ),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        border: Border(
          top: BorderSide(
            color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          key: const Key('transfer_submit'),
          onPressed: state.isSubmitting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsApp.primaryGreenPressed,
            disabledBackgroundColor: ColorsApp.primaryGreenPressed.withValues(
              alpha: 0.5,
            ),
            foregroundColor: ColorsApp.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: state.isSubmitting
              ? SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: const CircularProgressIndicator(
                    color: ColorsApp.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'transfers.submit'.tr(),
                  style: TextStyleApp.transactionsSaveButton,
                  maxLines: 1,
                ),
        ),
      ),
    );
  }
}

class _NotEnoughAccounts extends StatelessWidget {
  final double horizontal;

  const _NotEnoughAccounts({required this.horizontal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal + 12.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 40.r,
              color: ColorsApp.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              'transfers.need_two_title'.tr(),
              style: TextStyleApp.transactionsEmptyTitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'transfers.need_two_body'.tr(),
              style: TextStyleApp.dashboardStatLabel,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
