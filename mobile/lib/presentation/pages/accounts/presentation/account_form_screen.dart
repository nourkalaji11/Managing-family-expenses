import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/presentation/pages/accounts/bloc/account_form_bloc.dart';
import 'package:family_expense_management/presentation/widgets/labelled_text_field.dart';
import 'package:family_expense_management/presentation/pages/accounts/presentation/widgets/account_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Route arguments for both Add and Edit.
///
/// [account] null means Add. [transactionCount] is passed down from the list's
/// already-loaded counts, so the delete button can warn before the server
/// refuses rather than after.
class AccountFormArgs {
  final Account? account;
  final int transactionCount;

  const AccountFormArgs({required this.account, this.transactionCount = 0});
}

/// Add and Edit, in one screen.
///
/// The mode comes from whether [AccountFormArgs.account] is null, exactly like
/// `BudgetFormScreen`. Pushed as a full-screen route with a back arrow and no
/// bottom navigation — the design shows both a back arrow and the tab bar,
/// which cannot coexist on a pushed route.
///
/// Three elements of the design are deliberately absent, each because nothing
/// on the server could hold them:
///   * The "بيانات الحساب البنكي" banner illustration, which is a photographic
///     asset — this repository ships no `assets/images/`.
///   * The "نوع الحساب" selector (جاري / ادخار / بطاقة ائتمانية / نقد).
///     TODO(backend): `accounts` has no `type` column, so a choice made there
///     could not survive a reload. `AccountVisuals` infers the row glyph from
///     the name instead, and the form previews that inference live.
///   * The "آمن ومشفر" and "مزامنة فورية" badges. The first is a security claim
///     this app is in no position to make — the API is reached over plain HTTP
///     in development, and no field is encrypted at rest — and the second
///     describes a sync feature that does not exist. Rendering either would be
///     telling the user something untrue about their money.
class AccountFormScreen extends StatefulWidget {
  /// Optional. When null the arguments are read from the route settings, which
  /// is how `AppRoutes` builds this screen.
  final AccountFormArgs? args;

  const AccountFormScreen({super.key, this.args});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  static const double _pagePadding = 20;

  late final AccountFormBloc _bloc;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _bloc = AccountFormBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route arguments are only available once there is a context, so the form
    // is seeded here rather than in `initState`. The flag keeps it to one seed.
    if (_started) return;
    _started = true;

    final AccountFormArgs args = _resolveArgs();
    _bloc.add(
      OnAccountFormStarted(
        account: args.account,
        transactionCount: args.transactionCount,
      ),
    );
  }

  AccountFormArgs _resolveArgs() {
    final AccountFormArgs? direct = widget.args;
    if (direct != null) return direct;

    final Object? routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is AccountFormArgs) return routeArgs;

    // A route pushed without arguments renders an empty Add form.
    return const AccountFormArgs(account: null);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Confirms before deleting.
  ///
  /// The dialog is not a formality: `accounts.user_id` cascades, so a delete the
  /// server *did* accept is unrecoverable from inside the app. When the account
  /// still holds transactions the server refuses outright, and the dialog says
  /// so up front rather than sending the user to press a button that cannot
  /// work.
  Future<void> _confirmDelete(AccountFormState state) async {
    final bool blocked = state.hasTransactions;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorsApp.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'accounts.delete_title'.tr(),
          style: TextStyleApp.dashboardSectionTitle,
        ),
        content: Text(
          blocked
              ? 'accounts.delete_blocked_body'.plural(state.transactionCount)
              : 'accounts.delete_body'.tr(),
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
          // The confirm action is withheld entirely when the server would
          // refuse, so the dialog cannot end in an error the user could have
          // been spared.
          if (!blocked)
            TextButton(
              key: const Key('account_delete_confirm'),
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
      _bloc.add(const OnDeleteAccount());
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<AccountFormBloc, AccountFormState>(
      bloc: _bloc,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case AccountFormStatus.success:
            EasyLoading.showToast(
              state.isEditing
                  ? 'accounts.updated'.tr()
                  : 'accounts.created'.tr(),
              toastPosition: EasyLoadingToastPosition.bottom,
            );
            // `true` is the signal the list refreshes on.
            Navigator.of(context).pop(true);
          case AccountFormStatus.deleted:
            EasyLoading.showToast(
              'accounts.deleted'.tr(),
              toastPosition: EasyLoadingToastPosition.bottom,
            );
            Navigator.of(context).pop(true);
          case AccountFormStatus.failure:
            // The server's own message is preferred: for a 409 it names the
            // exact number of transactions blocking the delete, which nothing
            // this app could phrase would match.
            EasyLoading.showToast(
              state.failure?.message ?? 'errorglobal'.tr(),
              toastPosition: EasyLoadingToastPosition.bottom,
            );
          case AccountFormStatus.editing:
          case AccountFormStatus.submitting:
          case AccountFormStatus.deleting:
            break;
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
                  ? 'accounts.edit_title'.tr()
                  : 'accounts.add_title'.tr(),
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
                      _PreviewHeader(state: state),
                      SizedBox(height: 20.h),
                      _FormCard(
                        state: state,
                        onNameChanged: (v) =>
                            _bloc.add(OnAccountNameChanged(v)),
                        onBalanceChanged: (v) =>
                            _bloc.add(OnAccountBalanceChanged(v)),
                      ),
                    ],
                  ),
                ),
                _SaveBar(
                  state: state,
                  horizontalPadding: horizontal,
                  onSave: () => _bloc.add(const OnSubmitAccountForm()),
                  onDelete: state.isEditing
                      ? () => _confirmDelete(state)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Live preview of the glyph the row will carry and the balance it will show.
///
/// This is what replaces the design's banner illustration. It earns its space:
/// `AccountVisuals` infers the icon from the name, and that inference is
/// invisible until the account is saved — showing it here means the user finds
/// out while they can still change the name.
class _PreviewHeader extends StatelessWidget {
  final AccountFormState state;

  const _PreviewHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final num? balance = state.balance;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: AccountVisuals.tintFor(balance),
              borderRadius: BorderRadius.circular(20.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              AccountVisuals.iconFor(state.name),
              size: 30.r,
              color: AccountVisuals.inkFor(balance),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            state.name.trim().isEmpty
                ? 'accounts.preview_placeholder'.tr()
                : state.name.trim(),
            style: TextStyleApp.dashboardSectionTitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            '${DashboardFormatter.isolatedAmount(balance)} '
            '${'dashboard.currency_sar'.tr()}',
            style: TextStyleApp.budgetsPreviewValue.copyWith(
              color: AccountVisuals.amountColorFor(balance),
            ),
          ),
        ],
      ),
    );
  }
}

/// The white card holding the two fields.
class _FormCard extends StatelessWidget {
  final AccountFormState state;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBalanceChanged;

  const _FormCard({
    required this.state,
    required this.onNameChanged,
    required this.onBalanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool showErrors = state.showErrors;

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
            key: const Key('account_form_name'),
            label: 'accounts.name_label'.tr(),
            hint: 'accounts.name_hint'.tr(),
            initialValue: state.name,
            onChanged: onNameChanged,
            errorKey: showErrors ? state.errors.name : null,
            icon: Icons.account_balance_outlined,
            maxLength: AccountFormBloc.maxNameLength,
          ),
          SizedBox(height: 24.h),
          LabelledTextField(
            key: const Key('account_form_balance'),
            label: 'accounts.balance_label'.tr(),
            hint: '0.00',
            initialValue: state.balanceInput,
            onChanged: onBalanceChanged,
            errorKey: showErrors ? state.errors.balance : null,
            icon: Icons.payments_outlined,
            suffixText: 'dashboard.currency_sar'.tr(),
            // `signed` so an overdrawn card can actually be typed; `decimal`
            // for the two fractional digits the column stores.
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                AccountFormBloc.balanceInputPattern,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'accounts.balance_hint'.tr(),
            style: TextStyleApp.dashboardCaption,
          ),
        ],
      ),
    );
  }
}

/// The pinned save button, with the delete action beside it in Edit mode.
class _SaveBar extends StatelessWidget {
  final AccountFormState state;
  final double horizontalPadding;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _SaveBar({
    required this.state,
    required this.horizontalPadding,
    required this.onSave,
    this.onDelete,
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
      child: Row(
        children: [
          if (onDelete != null) ...[
            _DeleteButton(
              isDeleting: state.isDeleting,
              // Both buttons disable together while either write is in flight,
              // so a delete cannot race a save.
              onPressed: state.isBusy ? null : onDelete,
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: SizedBox(
              // 56px clears the 44px minimum touch target with room to spare.
              height: 56.h,
              child: ElevatedButton(
                key: const Key('account_form_save'),
                onPressed: state.isBusy ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsApp.primaryGreenPressed,
                  disabledBackgroundColor: ColorsApp.primaryGreenPressed
                      .withValues(alpha: 0.5),
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
                        state.isEditing
                            ? 'accounts.save_changes'.tr()
                            : 'accounts.save_new'.tr(),
                        style: TextStyleApp.transactionsSaveButton,
                        maxLines: 1,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The square trash button from the design, left of the save button.
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
        key: const Key('account_form_delete'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorsApp.errorRed,
          side: BorderSide(
            color: ColorsApp.errorRed.withValues(alpha: 0.4),
          ),
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
