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
      listenWhen: (previous, current) =>
          current is FamilyLoaded && current.writeFailure != null,
      listener: (context, state) {
        final failure = (state as FamilyLoaded).writeFailure;
        // The server's own message: it is the only side that can decide 403
        // (not a parent) or 422 (target is a parent).
        EasyLoading.showToast(
          failure?.message ?? 'errorglobal'.tr(),
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
          ],
        ],
      ),
    );
  }
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
