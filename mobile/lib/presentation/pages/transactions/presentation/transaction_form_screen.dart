import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/presentation/pages/transactions/bloc/transaction_form_bloc.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/amount_display.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/amount_keypad.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/form_selector_tile.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/picker_sheet.dart';
import 'package:family_expense_management/presentation/pages/transactions/presentation/widgets/transaction_type_toggle.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Route arguments for both Add and Edit.
///
/// [transaction] null means Add. [accounts] and [categories] are passed down
/// from the list screen's loaded state so the form's pickers are populated
/// without a second load.
class TransactionFormArgs {
  final TransactionModel? transaction;
  final List<Account> accounts;
  final List<Category> categories;

  const TransactionFormArgs({
    required this.transaction,
    required this.accounts,
    required this.categories,
  });
}

/// Add and Edit, in one screen.
///
/// The mode comes from whether [TransactionFormArgs.transaction] is null. There
/// is deliberately no second, near-identical form widget: the layout, the
/// validation and the save path are the same, and only the title, the seeded
/// values and the repository call differ.
///
/// Pushed as a full-screen route with a back arrow and no bottom navigation.
/// The design shows both a back arrow and the tab bar, which cannot coexist on
/// a pushed route.
///
/// There is no delete action and no overflow menu: the design defines neither,
/// and the `more_vert` glyph in the mockup has no menu behind it.
class TransactionFormScreen extends StatefulWidget {
  /// Optional. When null the arguments are read from the route settings, which
  /// is how `AppRoutes` builds this screen.
  final TransactionFormArgs? args;

  const TransactionFormScreen({super.key, this.args});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  static const double _pagePadding = 20;

  late final TransactionFormBloc _bloc;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _bloc = TransactionFormBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route arguments are only available once there is a context, so the form
    // is seeded here rather than in `initState`. The flag keeps it to one seed.
    if (_started) return;
    _started = true;

    final TransactionFormArgs args = _resolveArgs();
    _bloc.add(
      OnFormStarted(
        transaction: args.transaction,
        accounts: args.accounts,
        categories: args.categories,
      ),
    );
  }

  TransactionFormArgs _resolveArgs() {
    final TransactionFormArgs? direct = widget.args;
    if (direct != null) return direct;

    final Object? routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is TransactionFormArgs) return routeArgs;

    // A route pushed without arguments renders an Add form that loads its own
    // account and category options — this is the path the dashboard's "إضافة
    // معاملة" quick action takes. See `TransactionFormBloc._loadOptions`.
    return const TransactionFormArgs(
      transaction: null,
      accounts: <Account>[],
      categories: <Category>[],
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Confirms before deleting.
  ///
  /// Not a formality: the row is gone for good, and the account balance moves
  /// with it. There is no "in use" guard to warn about here, unlike accounts
  /// and categories — nothing references a transaction — so the only thing to
  /// say is that it cannot be undone.
  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorsApp.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'transactions.delete_title'.tr(),
          style: TextStyleApp.dashboardSectionTitle,
        ),
        content: Text(
          'transactions.delete_body'.tr(),
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
            key: const Key('transaction_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'accounts.delete_confirm'.tr(),
              style: TextStyleApp.dashboardSectionAction.copyWith(
                color: ColorsApp.errorRed,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _bloc.add(const OnDeleteTransaction());
    }
  }

  Future<void> _pickDate(TransactionFormState state) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.date.isAfter(today) ? today : state.date,
      // Ten years back is arbitrary but bounded; the schema imposes no limit.
      firstDate: DateTime(today.year - 10),
      // The decision: a transaction cannot be recorded in the future.
      lastDate: today,
    );

    if (picked != null && mounted) {
      _bloc.add(OnDateChanged(DateTime(picked.year, picked.month, picked.day)));
    }
  }

  Future<void> _pickAccount(TransactionFormState state) async {
    if (state.accounts.isEmpty) {
      EasyLoading.showToast(
        'transactions.no_accounts'.tr(),
        toastPosition: EasyLoadingToastPosition.bottom,
      );
      return;
    }

    final int? picked = await PickerSheet.show<int>(
      context: context,
      title: 'transactions.select_account'.tr(),
      selected: state.accountId,
      options: <PickerOption<int>>[
        for (final a in state.accounts)
          if (a.id != null)
            PickerOption<int>(
              value: a.id!,
              label: a.name ?? 'unknown'.tr(),
              subtitle:
                  '${DashboardFormatter.amount(a.balance)} '
                  '${'dashboard.currency_sar'.tr()}',
              icon: Icons.account_balance_wallet_outlined,
            ),
      ],
    );

    if (picked != null && mounted) _bloc.add(OnAccountChanged(picked));
  }

  Future<void> _pickCategory(TransactionFormState state) async {
    if (state.categories.isEmpty) {
      EasyLoading.showToast(
        'transactions.no_categories'.tr(),
        toastPosition: EasyLoadingToastPosition.bottom,
      );
      return;
    }

    final int? picked = await PickerSheet.show<int>(
      context: context,
      title: 'transactions.select_category'.tr(),
      selected: state.categoryId,
      options: <PickerOption<int>>[
        for (final c in state.categories)
          if (c.id != null)
            PickerOption<int>(
              value: c.id!,
              label: c.name ?? 'unknown'.tr(),
              icon: CategoryVisuals.iconFor(c.id),
            ),
      ],
    );

    if (picked != null && mounted) _bloc.add(OnCategoryChanged(picked));
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<TransactionFormBloc, TransactionFormState>(
      bloc: _bloc,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == TransactionFormStatus.success) {
          EasyLoading.showToast(
            state.isEditing
                ? 'transactions.updated'.tr()
                : 'transactions.created'.tr(),
            toastPosition: EasyLoadingToastPosition.bottom,
          );
          // `true` is the signal the list and the dashboard refresh on.
          Navigator.of(context).pop(true);
        } else if (state.status == TransactionFormStatus.failure) {
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
              state.isEditing
                  ? 'transactions.edit_title'.tr()
                  : 'transactions.add_title'.tr(),
              style: TextStyleApp.dashboardAppBarTitle,
            ),
            // The default leading is a back arrow that already mirrors itself
            // for RTL, which is exactly the design's behaviour.
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
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      20.h,
                      horizontal,
                      20.h,
                    ),
                    children: [
                      AmountDisplay(
                        amountInput: state.amountInput,
                        errorKey: state.showErrors ? state.errors.amount : null,
                      ),
                      SizedBox(height: 24.h),
                      TransactionTypeToggle(
                        value: state.type,
                        onChanged: (t) => _bloc.add(OnTypeChanged(t)),
                      ),
                      SizedBox(height: 16.h),
                      _FormCard(
                        state: state,
                        onPickAccount: () => _pickAccount(state),
                        onPickCategory: () => _pickCategory(state),
                        onPickDate: () => _pickDate(state),
                        onDescriptionChanged: (v) =>
                            _bloc.add(OnDescriptionChanged(v)),
                      ),
                      SizedBox(height: 20.h),
                      AmountKeypad(
                        onDigit: (d) => _bloc.add(OnAmountDigitPressed(d)),
                        onBackspace: () => _bloc.add(const OnAmountBackspace()),
                      ),
                    ],
                  ),
                ),
                _SaveBar(
                  state: state,
                  horizontalPadding: horizontal,
                  onPressed: () => _bloc.add(const OnSubmitForm()),
                  // Edit mode only: an unsaved draft has nothing to delete.
                  onDelete: state.isEditing ? _confirmDelete : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The white card holding the account, category, date and description rows.
class _FormCard extends StatelessWidget {
  final TransactionFormState state;
  final VoidCallback onPickAccount;
  final VoidCallback onPickCategory;
  final VoidCallback onPickDate;
  final ValueChanged<String> onDescriptionChanged;

  const _FormCard({
    required this.state,
    required this.onPickAccount,
    required this.onPickCategory,
    required this.onPickDate,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool showErrors = state.showErrors;

    return Container(
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      // `clipBehavior` so the InkWell ripples respect the rounded corners.
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          FormSelectorTile(
            key: const Key('transaction_form_account'),
            leadingIcon: Icons.account_balance_wallet_outlined,
            label: 'transactions.account'.tr(),
            value: state.selectedAccount?.name,
            placeholder: 'transactions.select_account'.tr(),
            errorKey: showErrors ? state.errors.account : null,
            onTap: onPickAccount,
          ),
          const _RowDivider(),
          FormSelectorTile(
            key: const Key('transaction_form_category'),
            leadingIcon: CategoryVisuals.iconFor(state.categoryId),
            label: 'transactions.category'.tr(),
            value: state.selectedCategory?.name,
            placeholder: 'transactions.select_category'.tr(),
            errorKey: showErrors ? state.errors.category : null,
            onTap: onPickCategory,
          ),
          const _RowDivider(),
          FormSelectorTile(
            key: const Key('transaction_form_date'),
            leadingIcon: Icons.calendar_today_outlined,
            trailingIcon: Icons.calendar_month_outlined,
            label: 'transactions.date'.tr(),
            value: DashboardFormatter.fullDate(state.date),
            placeholder: 'transactions.select_date'.tr(),
            errorKey: showErrors ? state.errors.date : null,
            onTap: onPickDate,
          ),
          const _RowDivider(),
          _DescriptionField(
            initialValue: state.description,
            errorKey: showErrors ? state.errors.description : null,
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: ColorsApp.outlineVariant.withValues(alpha: 0.25),
    );
  }
}

/// The free-text note row.
///
/// Stateful only to own its controller; the value lives in the bloc.
class _DescriptionField extends StatefulWidget {
  final String initialValue;
  final String? errorKey;
  final ValueChanged<String> onChanged;

  const _DescriptionField({
    required this.initialValue,
    required this.errorKey,
    required this.onChanged,
  });

  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_outlined, size: 18.r, color: ColorsApp.outline),
              SizedBox(width: 10.w),
              Text(
                'transactions.description'.tr(),
                style: TextStyleApp.transactionsFieldLabel,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          TextField(
            key: const Key('transaction_form_description'),
            controller: _controller,
            onChanged: widget.onChanged,
            style: TextStyleApp.transactionsFieldInput,
            // The column is `nullable|string|max:255`; the counter is hidden
            // because the design has none, but the limit is still enforced,
            // both here and in the bloc's validation.
            maxLength: 255,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'transactions.description_hint'.tr(),
              hintStyle: TextStyleApp.transactionsFieldHint,
            ),
          ),
          if (widget.errorKey != null) ...[
            SizedBox(height: 6.h),
            Text(
              widget.errorKey!.tr(),
              style: TextStyleApp.transactionsFieldError,
            ),
          ],
        ],
      ),
    );
  }
}

/// The pinned "حفظ المعاملة" button.
class _SaveBar extends StatelessWidget {
  final TransactionFormState state;
  final double horizontalPadding;
  final VoidCallback onPressed;

  /// Null in Add mode: an unsaved draft has nothing to delete.
  final VoidCallback? onDelete;

  const _SaveBar({
    required this.state,
    required this.horizontalPadding,
    required this.onPressed,
    this.onDelete,
  });

  bool get isSubmitting => state.isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColorsApp.dashboardBackground,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12.h,
        horizontalPadding,
        16.h,
      ),
      child: Row(
        children: [
          if (onDelete != null) ...[
            _DeleteButton(
              isDeleting: state.isDeleting,
              // Both disable together while either write is in flight, so a
              // delete cannot race a save.
              onPressed: state.isBusy ? null : onDelete,
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: SizedBox(
              height: 56.h,
              child: ElevatedButton(
                key: const Key('transaction_form_save'),
                // Null while saving: this is what blocks a double submission at the
                // UI layer. The bloc drops a duplicate event as well.
                onPressed: state.isBusy ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsApp.primaryGreenPressed,
                  disabledBackgroundColor: ColorsApp.primaryGreenPressed
                      .withValues(alpha: 0.6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(
                          color: ColorsApp.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'transactions.save'.tr(),
                              style: TextStyleApp.transactionsSaveButton,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.check_circle_outline,
                            size: 22.r,
                            color: ColorsApp.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The square trash button, left of Save in Edit mode.
///
/// Identical in shape to the one on the account and category forms — the four
/// edit forms are the same control in four places, so they look the same.
class _DeleteButton extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback? onPressed;

  const _DeleteButton({required this.isDeleting, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56.h,
      height: 56.h,
      child: OutlinedButton(
        key: const Key('transaction_form_delete'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorsApp.errorRed,
          side: BorderSide(color: ColorsApp.errorRed.withValues(alpha: 0.4)),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: isDeleting
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  color: ColorsApp.errorRed,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(Icons.delete_outline, size: 22.r),
      ),
    );
  }
}
