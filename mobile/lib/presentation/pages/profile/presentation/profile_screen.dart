import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/app_routes.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/presentation/pages/profile/bloc/profile_bloc.dart';
import 'package:family_expense_management/presentation/pages/profile/presentation/widgets/profile_action_tile.dart';
import 'package:family_expense_management/presentation/pages/profile/presentation/widgets/profile_header.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The profile screen, pushed from the avatar in every main tab's app bar.
///
/// Three actions: edit the account, manage the family, sign out. The family
/// action is shown to a parent only — a member's `GET /users` returns just
/// themselves, so the screen would be a list of one.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _pagePadding = 20;

  late final ProfileBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ProfileBloc()..add(const OnLoadProfile());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _openEdit(User user) async {
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.editProfile, arguments: user);

    // The form pops the saved user, so the header updates without a round trip.
    if (result is User && mounted) {
      _bloc.add(OnProfileUpdated(result));
    }
  }

  Future<void> _openFamily() async {
    await Navigator.of(context).pushNamed(AppRoutes.familyMembers);
    // A ceiling may have been changed for this very user, so the header is
    // re-read on return.
    if (mounted) _bloc.add(const OnRefreshProfile());
  }

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorsApp.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'profile.logout_title'.tr(),
          style: TextStyleApp.dashboardSectionTitle,
        ),
        content: Text(
          'profile.logout_body'.tr(),
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
            key: const Key('profile_logout_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'profile.logout_confirm'.tr(),
              style: TextStyleApp.dashboardSectionAction.copyWith(
                color: ColorsApp.errorRed,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _bloc.add(const OnLogout());
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<ProfileBloc, ProfileState>(
      bloc: _bloc,
      listenWhen: (previous, current) => current is ProfileLoggedOut,
      listener: (context, state) {
        // The whole stack is replaced, not popped: leaving the dashboard behind
        // a signed-out session would let the back gesture return to screens
        // that will now only answer 401.
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
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
              'profile.title'.tr(),
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
              ProfileInitial() ||
              ProfileLoading() ||
              // Terminal, and the listener is already navigating away — a
              // loader avoids one frame of an empty scaffold.
              ProfileLoggedOut() => const AppLoadingView(),
              ProfileFailure(:final error) => AppFailureView(
                failure: error,
                retryKey: const Key('profile_retry'),
                onRetry: () => _bloc.add(const OnLoadProfile()),
              ),
              ProfileLoaded() => _LoadedView(
                state: state,
                horizontal: horizontal,
                onRefresh: () async => _bloc.add(const OnRefreshProfile()),
                onEdit: () => _openEdit(state.user),
                onFamily: _openFamily,
                onLogout: _confirmLogout,
              ),
            },
          ),
        );
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final ProfileLoaded state;
  final double horizontal;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onFamily;
  final VoidCallback onLogout;

  const _LoadedView({
    required this.state,
    required this.horizontal,
    required this.onRefresh,
    required this.onEdit,
    required this.onFamily,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final User user = state.user;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 20.h, horizontal, 32.h),
        children: [
          ProfileHeader(user: user),
          SizedBox(height: 24.h),
          Text(
            'profile.account_section'.tr(),
            style: TextStyleApp.budgetsSectionLabel,
          ),
          SizedBox(height: 12.h),
          ProfileActionTile(
            key: const Key('profile_edit'),
            icon: Icons.edit_outlined,
            label: 'profile.edit_title'.tr(),
            subtitle: 'profile.edit_subtitle'.tr(),
            onTap: onEdit,
          ),
          // Shown to a parent only: a member's own `GET /users` returns just
          // themselves, so the screen would list one row — their own.
          if (user.isParent) ...[
            SizedBox(height: 12.h),
            ProfileActionTile(
              key: const Key('profile_family'),
              icon: Icons.family_restroom_outlined,
              label: 'profile.family_title'.tr(),
              subtitle: 'profile.family_subtitle'.tr(),
              onTap: onFamily,
            ),
          ],
          SizedBox(height: 24.h),
          Text(
            'profile.session_section'.tr(),
            style: TextStyleApp.budgetsSectionLabel,
          ),
          SizedBox(height: 12.h),
          ProfileActionTile(
            key: const Key('profile_logout'),
            icon: Icons.logout_outlined,
            label: 'profile.logout_title'.tr(),
            destructive: true,
            busy: state.isLoggingOut,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
