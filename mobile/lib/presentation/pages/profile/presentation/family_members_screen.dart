import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/presentation/pages/profile/bloc/family_bloc.dart';
import 'package:family_expense_management/presentation/widgets/labelled_text_field.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The family members list, with each member's spending ceiling.
///
/// Reached from the profile screen, and offered to a parent only — a member's
/// own `GET /users` returns just themselves.
///
/// There is deliberately no "add member" action. A new member joins by
/// registering their own account; there is no invite endpoint, and no way for
/// one user to create credentials for another.
class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  static const double _pagePadding = 20;

  late final FamilyBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = FamilyBloc()..add(const OnLoadFamily());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Collects a child's details and creates the account.
  ///
  /// A bottom sheet rather than a route: it is four fields, and it belongs to
  /// the list it adds to — closing it should put the parent back in front of
  /// the family, which a sheet does without a navigation stack.
  ///
  /// The allowance is optional here. A parent who has decided sets it now and
  /// the child starts capped; a parent who has not can add the child and decide
  /// later, and until they do the child is uncapped rather than silently frozen
  /// at zero.
  Future<void> _addMember() async {
    final result = await showModalBottomSheet<_NewMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _AddMemberSheet(),
    );

    if (result == null || !mounted) return;

    _bloc.add(
      OnAddFamilyMember(
        name: result.name,
        email: result.email,
        password: result.password,
        spendingLimit: result.spendingLimit,
      ),
    );
  }

  /// Asks for the new ceiling in a dialog rather than pushing a screen: it is a
  /// single number, and a full route for one field would be heavier than the
  /// task.
  Future<void> _editLimit(User member) async {
    final int? id = member.id;
    if (id == null) return;

    String input = _limitToInput(member.spendingLimit);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorsApp.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'profile.set_limit_title'.tr(),
          style: TextStyleApp.dashboardSectionTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.set_limit_body'.tr(
                namedArgs: {'name': member.name ?? ''},
              ),
              style: TextStyleApp.dashboardStatLabel,
            ),
            SizedBox(height: 16.h),
            LabelledTextField(
              key: const Key('family_limit_field'),
              label: 'profile.limit_label'.tr(),
              hint: '0.00',
              initialValue: input,
              onChanged: (v) => input = v,
              suffixText: 'dashboard.currency_sar'.tr(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                // No leading minus: a negative ceiling is meaningless, and the
                // server rejects it with `min:0`.
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,13}(\.\d{0,2})?$'),
                ),
              ],
            ),
          ],
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
            key: const Key('family_limit_save'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'accounts.save_changes'.tr(),
              style: TextStyleApp.dashboardSectionAction,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final num? limit = num.tryParse(input.trim());
    if (limit == null || limit < 0) {
      EasyLoading.showToast(
        'profile.error_limit_invalid'.tr(),
        toastPosition: EasyLoadingToastPosition.bottom,
      );
      return;
    }

    _bloc.add(OnSetSpendingLimit(userId: id, limit: limit));
  }

  /// Renders an existing ceiling back into the field, dropping a trailing
  /// ".00" so a whole amount opens as "300" rather than "300.00".
  static String _limitToInput(num? value) {
    if (value == null) return '';
    if (value % 1 == 0) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<FamilyBloc, FamilyState>(
      bloc: _bloc,
      listenWhen: (previous, current) {
        if (current is! FamilyLoaded) return false;
        if (current.writeFailure != null) return true;
        // A newly added child, identified by the id changing rather than by a
        // flag — a flag would re-fire on every later rebuild.
        return previous is FamilyLoaded &&
            previous.lastAddedMemberId != current.lastAddedMemberId &&
            current.lastAddedMemberId != null;
      },
      listener: (context, state) {
        final loaded = state as FamilyLoaded;

        if (loaded.writeFailure != null) {
          // The server's own message: it is the only side that can decide 403
          // (not a parent), 422 (target is a parent) or a duplicate email.
          EasyLoading.showToast(
            loaded.writeFailure?.message ?? 'errorglobal'.tr(),
            toastPosition: EasyLoadingToastPosition.bottom,
          );
          return;
        }

        EasyLoading.showToast(
          'profile.member_added'.tr(),
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
              'profile.family_title'.tr(),
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
              FamilyInitial() || FamilyLoading() => const AppLoadingView(),
              FamilyFailure(:final error) => AppFailureView(
                failure: error,
                retryKey: const Key('family_retry'),
                onRetry: () => _bloc.add(const OnLoadFamily()),
              ),
              FamilyLoaded() => _LoadedView(
                state: state,
                horizontal: horizontal,
                onRefresh: () async => _bloc.add(const OnRefreshFamily()),
                onEditLimit: _editLimit,
              ),
            },
          ),
          // Offered only to a parent, matching what the server will accept. A
          // member who tapped it would get a 403 and no explanation of why the
          // app showed them a button that cannot work.
          floatingActionButton: (state is FamilyLoaded && state.canManage)
              ? FloatingActionButton.extended(
                  key: const Key('family_add_member'),
                  onPressed: state.isAddingMember ? null : _addMember,
                  backgroundColor: ColorsApp.primaryGreenPressed,
                  foregroundColor: ColorsApp.white,
                  icon: state.isAddingMember
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: const CircularProgressIndicator(
                            color: ColorsApp.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(Icons.person_add_alt_1, size: 20.r),
                  label: Text(
                    'profile.add_member'.tr(),
                    style: TextStyleApp.dashboardSectionAction.copyWith(
                      color: ColorsApp.white,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final FamilyLoaded state;
  final double horizontal;
  final Future<void> Function() onRefresh;
  final void Function(User) onEditLimit;

  const _LoadedView({
    required this.state,
    required this.horizontal,
    required this.onRefresh,
    required this.onEditLimit,
  });

  @override
  Widget build(BuildContext context) {
    final List<User> parents = state.parents;
    final List<User> members = state.manageableMembers;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 20.h, horizontal, 32.h),
        children: [
          if (parents.isNotEmpty) ...[
            Text(
              'profile.parents_section'.tr(),
              style: TextStyleApp.budgetsSectionLabel,
            ),
            SizedBox(height: 12.h),
            for (int i = 0; i < parents.length; i++) ...[
              if (i > 0) SizedBox(height: 12.h),
              _MemberCard(
                key: ValueKey<int?>(parents[i].id),
                member: parents[i],
                // A parent carries no ceiling, so there is nothing to edit.
                onEditLimit: null,
                isSaving: false,
              ),
            ],
            SizedBox(height: 24.h),
          ],
          Text(
            'profile.members_section'.tr(),
            style: TextStyleApp.budgetsSectionLabel,
          ),
          SizedBox(height: 12.h),
          if (members.isEmpty)
            const _NoMembers()
          else
            for (int i = 0; i < members.length; i++) ...[
              if (i > 0) SizedBox(height: 12.h),
              _MemberCard(
                key: ValueKey<int?>(members[i].id),
                member: members[i],
                onEditLimit: state.canManage
                    ? () => onEditLimit(members[i])
                    : null,
                isSaving: state.isSaving(members[i].id),
              ),
            ],
        ],
      ),
    );
  }
}

/// One member: monogram, name, email, and their ceiling with an edit action.
class _MemberCard extends StatelessWidget {
  final User member;
  final VoidCallback? onEditLimit;
  final bool isSaving;

  const _MemberCard({
    super.key,
    required this.member,
    required this.onEditLimit,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (member.name ?? '').trim();
    final String initial = name.isEmpty ? '؟' : name.characters.first;
    final bool isParent = member.isParent;
    final Color ink = isParent
        ? ColorsApp.dashboardBlue
        : ColorsApp.primaryGreenPressed;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: ColorsApp.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ink.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyleApp.transactionsRowTitle.copyWith(color: ink),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'profile.unnamed'.tr() : name,
                      style: TextStyleApp.transactionsRowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      member.email ?? '',
                      style: TextStyleApp.transactionsRowSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isParent ? 'auth.parent'.tr() : 'auth.family_member'.tr(),
                  style: TextStyleApp.budgetsPreviewBadge.copyWith(color: ink),
                ),
              ),
            ],
          ),
          if (!isParent) ...[
            SizedBox(height: 14.h),
            Divider(
              height: 1,
              color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.limit_label'.tr(),
                        style: TextStyleApp.budgetsCardCaption,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        // A null ceiling is "not capped", not "capped at
                        // zero" — and `isolatedAmount` renders null as 0.00,
                        // which reads as the opposite of what it means. The
                        // server sends null for a member no parent has set a
                        // limit for yet, which is where every member starts.
                        member.spendingLimit == null
                            ? 'profile.no_limit'.tr()
                            : '${DashboardFormatter.isolatedAmount(member.spendingLimit)} '
                                  '${'dashboard.currency_sar'.tr()}',
                        style: TextStyleApp.budgetsCardFooterValue,
                      ),
                    ],
                  ),
                ),
                if (isSaving)
                  SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(
                      color: ColorsApp.primaryGreenPressed,
                      strokeWidth: 2.5,
                    ),
                  )
                else if (onEditLimit != null)
                  TextButton(
                    key: ValueKey<String>('family_edit_limit_${member.id}'),
                    onPressed: onEditLimit,
                    child: Text(
                      'profile.edit_limit'.tr(),
                      style: TextStyleApp.dashboardSectionAction,
                    ),
                  ),
              ],
            ),
            // Draws itself away to nothing when there is no ceiling, so the
            // card stays the "no limit set" shape rather than showing an empty
            // bar that implies one exists.
            _UsageBar(member: member),
          ],
        ],
      ),
    );
  }
}

/// How much of a member's allowance is gone.
///
/// The bar is the point of the screen for a parent: a ceiling on its own only
/// says what is permitted, and the question being asked here is how much of it
/// is left. Drawn only for a member who has one — a parent has no ceiling, and
/// an empty bar beside their name would invent a limit they do not have.
class _UsageBar extends StatelessWidget {
  final User member;

  const _UsageBar({required this.member});

  /// Where the bar turns amber. Matches the ratio at which the server sends the
  /// "running out" warning, so the colour and the notification agree instead of
  /// telling the parent two different stories.
  static const double warnRatio = 0.8;

  @override
  Widget build(BuildContext context) {
    final double? usage = FamilyLoaded.usageOf(member);
    if (usage == null) return const SizedBox.shrink();

    final num spent = member.spent ?? 0;
    final num limit = member.spendingLimit ?? 0;
    final bool over = spent > limit;

    final Color ink = over
        ? ColorsApp.errorRed
        : (usage >= warnRatio
              ? ColorsApp.dashboardAmber
              : ColorsApp.primaryGreenPressed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: usage,
            minHeight: 6.h,
            backgroundColor: ColorsApp.surfaceContainerLow,
            valueColor: AlwaysStoppedAnimation<Color>(ink),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          over
              ? 'profile.over_limit'.tr()
              : (spent == 0
                    ? 'profile.no_spending_yet'.tr()
                    : 'profile.usage_of_limit'.tr(
                        namedArgs: {
                          'spent': DashboardFormatter.isolatedAmount(spent),
                          'limit': DashboardFormatter.isolatedAmount(limit),
                        },
                      )),
          style: TextStyleApp.budgetsCardCaption.copyWith(
            color: over ? ColorsApp.errorRed : null,
          ),
        ),
      ],
    );
  }
}

/// The sheet that collects a child's details.
///
/// Validates the same rules the server does — a name, a valid email, at least
/// eight characters of password — so the common mistakes are caught before a
/// round trip. The server still validates: this is a courtesy, not the
/// authority. Uniqueness of the email is deliberately NOT checked here, because
/// only the server can know it.
class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet();

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  static const int _minPasswordLength = 8;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _limit = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _limit.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _name.text.trim();
    final String email = _email.text.trim();
    final String password = _password.text;

    if (name.isEmpty) {
      setState(() => _error = 'profile.error_name_required'.tr());
      return;
    }
    // Deliberately loose: a stricter pattern rejects addresses that are
    // perfectly valid, and the server has the authoritative rule anyway.
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'profile.error_email_invalid'.tr());
      return;
    }
    if (password.length < _minPasswordLength) {
      setState(() => _error = 'profile.error_password_short'.tr());
      return;
    }

    // Blank means "no allowance decided yet", which is a different thing from
    // an allowance of zero — so it is sent as null, not as 0.
    final String limitText = _limit.text.trim();
    num? limit;
    if (limitText.isNotEmpty) {
      limit = num.tryParse(limitText);
      if (limit == null || limit < 0) {
        setState(() => _error = 'profile.error_limit_invalid'.tr());
        return;
      }
    }

    Navigator.of(context).pop(
      _NewMember(
        name: name,
        email: email,
        password: password,
        spendingLimit: limit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet clear of the keyboard, which otherwise covers the very
      // fields being typed into.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorsApp.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: ColorsApp.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'profile.add_member_title'.tr(),
                style: TextStyleApp.dashboardSectionTitle,
              ),
              SizedBox(height: 6.h),
              Text(
                'profile.add_member_body'.tr(),
                style: TextStyleApp.dashboardStatLabel,
              ),
              SizedBox(height: 18.h),
              _SheetField(
                fieldKey: const Key('add_member_name'),
                controller: _name,
                label: 'profile.member_name'.tr(),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12.h),
              _SheetField(
                fieldKey: const Key('add_member_email'),
                controller: _email,
                label: 'profile.member_email'.tr(),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12.h),
              _SheetField(
                fieldKey: const Key('add_member_password'),
                controller: _password,
                label: 'profile.member_password'.tr(),
                obscure: true,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12.h),
              _SheetField(
                fieldKey: const Key('add_member_limit'),
                controller: _limit,
                label: 'profile.member_limit_optional'.tr(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
              ),
              if (_error != null) ...[
                SizedBox(height: 12.h),
                Text(
                  _error!,
                  style: TextStyleApp.dashboardStatLabel.copyWith(
                    color: ColorsApp.errorRed,
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  key: const Key('add_member_submit'),
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsApp.primaryGreenPressed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'profile.add_member'.tr(),
                    style: TextStyleApp.transactionsSaveButton,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _SheetField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: TextStyleApp.budgetsCardFooterValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyleApp.dashboardStatLabel,
        filled: true,
        fillColor: ColorsApp.dashboardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}

/// What the sheet hands back. A plain carrier so the sheet stays free of the
/// bloc, and the screen decides what to dispatch.
class _NewMember {
  final String name;
  final String email;
  final String password;
  final num? spendingLimit;

  const _NewMember({
    required this.name,
    required this.email,
    required this.password,
    this.spendingLimit,
  });
}

class _NoMembers extends StatelessWidget {
  const _NoMembers();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 32.h),
      child: Column(
        children: [
          Icon(
            Icons.person_add_alt,
            size: 40.r,
            color: ColorsApp.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'profile.no_members_title'.tr(),
            style: TextStyleApp.transactionsEmptyTitle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            'profile.no_members_body'.tr(),
            style: TextStyleApp.dashboardStatLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
