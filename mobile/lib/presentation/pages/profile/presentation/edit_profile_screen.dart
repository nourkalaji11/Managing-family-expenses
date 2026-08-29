import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/presentation/pages/profile/bloc/edit_profile_bloc.dart';
import 'package:family_expense_management/presentation/widgets/labelled_text_field.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Edits the signed-in user's name, email and — optionally — password.
///
/// The role is deliberately not editable. Promoting yourself to parent is a
/// privilege change, not a profile edit, and the server ignores the field
/// entirely.
class EditProfileScreen extends StatefulWidget {
  /// Optional. When null the user is read from the route arguments, falling
  /// back to the cached session.
  final User? user;

  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const double _pagePadding = 20;

  late final EditProfileBloc _bloc;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _bloc = EditProfileBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _bloc.add(OnEditProfileStarted(_resolveUser()));
  }

  User _resolveUser() {
    final User? direct = widget.user;
    if (direct != null) return direct;

    final Object? routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is User) return routeArgs;

    // Reached only if the route was pushed bare. The cached session is the
    // right fallback: this screen is unreachable without one.
    return LocalsApp.user ?? User();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<EditProfileBloc, EditProfileState>(
      bloc: _bloc,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == EditProfileStatus.success) {
          EasyLoading.showToast(
            'profile.updated'.tr(),
            toastPosition: EasyLoadingToastPosition.bottom,
          );
          // The saved user is handed back so the profile screen can update its
          // header without a round trip.
          Navigator.of(context).pop(state.saved);
        } else if (state.status == EditProfileStatus.failure) {
          // The server's own message is preferred: it is the only side that can
          // decide a duplicate email or a wrong current password.
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
              'profile.edit_title'.tr(),
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
                      _DetailsCard(
                        state: state,
                        onNameChanged: (v) => _bloc.add(OnEditNameChanged(v)),
                        onEmailChanged: (v) => _bloc.add(OnEditEmailChanged(v)),
                      ),
                      SizedBox(height: 20.h),
                      _PasswordCard(
                        state: state,
                        onToggle: () =>
                            _bloc.add(const OnTogglePasswordSection()),
                        onCurrentChanged: (v) =>
                            _bloc.add(OnEditCurrentPasswordChanged(v)),
                        onPasswordChanged: (v) =>
                            _bloc.add(OnEditPasswordChanged(v)),
                        onConfirmChanged: (v) =>
                            _bloc.add(OnEditConfirmPasswordChanged(v)),
                      ),
                    ],
                  ),
                ),
                _SaveBar(
                  isSubmitting: state.isSubmitting,
                  horizontalPadding: horizontal,
                  onPressed: () => _bloc.add(const OnSubmitEditProfile()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final EditProfileState state;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onEmailChanged;

  const _DetailsCard({
    required this.state,
    required this.onNameChanged,
    required this.onEmailChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        LabelledTextField(
          key: const Key('edit_profile_name'),
          label: 'auth.full_name'.tr(),
          hint: 'auth.full_name_hint'.tr(),
          initialValue: state.name,
          onChanged: onNameChanged,
          errorKey: state.showErrors ? state.errors.name : null,
          icon: Icons.person_outline,
          maxLength: EditProfileBloc.maxNameLength,
        ),
        SizedBox(height: 24.h),
        LabelledTextField(
          key: const Key('edit_profile_email'),
          label: 'auth.email'.tr(),
          hint: 'auth.email_hint'.tr(),
          initialValue: state.email,
          onChanged: onEmailChanged,
          errorKey: state.showErrors ? state.errors.email : null,
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          maxLength: EditProfileBloc.maxNameLength,
        ),
      ],
    );
  }
}

/// The password section, collapsed until the user asks for it.
///
/// Collapsed by default because changing a password is the rare case: expanding
/// it always would put three empty required-looking fields in front of someone
/// who only wanted to fix a typo in their name.
class _PasswordCard extends StatelessWidget {
  final EditProfileState state;
  final VoidCallback onToggle;
  final ValueChanged<String> onCurrentChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmChanged;

  const _PasswordCard({
    required this.state,
    required this.onToggle,
    required this.onCurrentChanged,
    required this.onPasswordChanged,
    required this.onConfirmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'profile.change_password'.tr(),
                style: TextStyleApp.dashboardSectionTitle,
              ),
            ),
            Switch(
              key: const Key('edit_profile_password_toggle'),
              value: state.changingPassword,
              onChanged: (_) => onToggle(),
              activeThumbColor: ColorsApp.white,
              activeTrackColor: ColorsApp.primaryGreenPressed,
            ),
          ],
        ),
        if (state.changingPassword) ...[
          SizedBox(height: 8.h),
          Text(
            'profile.change_password_hint'.tr(),
            style: TextStyleApp.dashboardCaption,
          ),
          SizedBox(height: 20.h),
          LabelledTextField(
            key: const Key('edit_profile_current_password'),
            label: 'profile.current_password'.tr(),
            hint: 'auth.password_hint'.tr(),
            initialValue: state.currentPassword,
            onChanged: onCurrentChanged,
            errorKey: state.showErrors ? state.errors.currentPassword : null,
            obscureText: true,
          ),
          SizedBox(height: 20.h),
          LabelledTextField(
            key: const Key('edit_profile_new_password'),
            label: 'profile.new_password'.tr(),
            hint: 'auth.password_hint'.tr(),
            initialValue: state.password,
            onChanged: onPasswordChanged,
            errorKey: state.showErrors ? state.errors.password : null,
            obscureText: true,
          ),
          SizedBox(height: 20.h),
          LabelledTextField(
            key: const Key('edit_profile_confirm_password'),
            label: 'auth.confirm_password'.tr(),
            hint: 'auth.password_hint'.tr(),
            initialValue: state.confirmPassword,
            onChanged: onConfirmChanged,
            errorKey: state.showErrors ? state.errors.confirmPassword : null,
            obscureText: true,
          ),
        ],
      ],
    );
  }
}

/// The white rounded container both sections sit in.
class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

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
        children: children,
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  final bool isSubmitting;
  final double horizontalPadding;
  final VoidCallback onPressed;

  const _SaveBar({
    required this.isSubmitting,
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
          key: const Key('edit_profile_save'),
          onPressed: isSubmitting ? null : onPressed,
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
          child: isSubmitting
              ? SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: const CircularProgressIndicator(
                    color: ColorsApp.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'accounts.save_changes'.tr(),
                  style: TextStyleApp.transactionsSaveButton,
                  maxLines: 1,
                ),
        ),
      ),
    );
  }
}
