import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/presentation/widgets/labelled_text_field.dart';
import 'package:family_expense_management/presentation/pages/categories/bloc/category_form_bloc.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Route arguments for both Add and Edit.
///
/// [category] null means Add. [usageCount] is the number of transactions and
/// budgets referencing it, passed down from the grid's already-loaded counts so
/// the delete button can warn before the server refuses rather than after.
class CategoryFormArgs {
  final Category? category;
  final int usageCount;

  const CategoryFormArgs({required this.category, this.usageCount = 0});
}

/// Add and Edit, in one screen.
///
/// The mode comes from whether [CategoryFormArgs.category] is null, exactly like
/// `AccountFormScreen` and `BudgetFormScreen`.
///
/// The design's icon grid ("اختر الأيقونة المناسبة") and colour swatches ("لون
/// الفئة المميز") are deliberately **not** rendered as pickers.
/// TODO(backend): `categories` is `(id, name, created_at, updated_at)` — there
/// is no `icon` and no `color` column, so a pick made there would be discarded
/// the moment the screen reloaded. A control that silently forgets is worse
/// than an absent one. The app already derives both client-side in
/// `CategoryVisuals`, and this screen shows that derived pair as a live preview
/// instead, so the user still sees the identity their category will carry.
/// Adding the two columns is what makes the design's pickers implementable.
class CategoryFormScreen extends StatefulWidget {
  /// Optional. When null the arguments are read from the route settings, which
  /// is how `AppRoutes` builds this screen.
  final CategoryFormArgs? args;

  const CategoryFormScreen({super.key, this.args});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  static const double _pagePadding = 20;

  late final CategoryFormBloc _bloc;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _bloc = CategoryFormBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final CategoryFormArgs args = _resolveArgs();
    _bloc.add(
      OnCategoryFormStarted(
        category: args.category,
        usageCount: args.usageCount,
      ),
    );
  }

  CategoryFormArgs _resolveArgs() {
    final CategoryFormArgs? direct = widget.args;
    if (direct != null) return direct;

    final Object? routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is CategoryFormArgs) return routeArgs;

    return const CategoryFormArgs(category: null);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Confirms before deleting.
  ///
  /// Categories are **global** — the table has no `user_id` — so a delete
  /// removes the category for every family, not just this one. The dialog says
  /// so. When the category is still referenced the server refuses outright, and
  /// the confirm action is withheld entirely.
  Future<void> _confirmDelete(CategoryFormState state) async {
    final bool blocked = state.isInUse;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorsApp.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'categories.delete_title'.tr(),
          style: TextStyleApp.dashboardSectionTitle,
        ),
        content: Text(
          blocked
              ? 'categories.delete_blocked_body'.plural(state.usageCount)
              : 'categories.delete_body'.tr(),
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
          if (!blocked)
            TextButton(
              key: const Key('category_delete_confirm'),
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
      _bloc.add(const OnDeleteCategory());
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<CategoryFormBloc, CategoryFormState>(
      bloc: _bloc,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case CategoryFormStatus.success:
            EasyLoading.showToast(
              state.isEditing
                  ? 'categories.updated'.tr()
                  : 'categories.created'.tr(),
              toastPosition: EasyLoadingToastPosition.bottom,
            );
            Navigator.of(context).pop(true);
          case CategoryFormStatus.deleted:
            EasyLoading.showToast(
              'categories.deleted'.tr(),
              toastPosition: EasyLoadingToastPosition.bottom,
            );
            Navigator.of(context).pop(true);
          case CategoryFormStatus.failure:
            // The server's own message is preferred: it is the only side that
            // can decide a duplicate name (422) or a category still in use
            // (409), and both messages are already Arabic.
            EasyLoading.showToast(
              state.failure?.message ?? 'errorglobal'.tr(),
              toastPosition: EasyLoadingToastPosition.bottom,
            );
          case CategoryFormStatus.editing:
          case CategoryFormStatus.submitting:
          case CategoryFormStatus.deleting:
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
                  ? 'categories.edit_title'.tr()
                  : 'categories.add_title'.tr(),
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
                      24.h,
                      horizontal,
                      20.h,
                    ),
                    children: [
                      _PreviewAvatar(state: state),
                      SizedBox(height: 24.h),
                      _FormCard(
                        state: state,
                        onNameChanged: (v) =>
                            _bloc.add(OnCategoryNameChanged(v)),
                      ),
                    ],
                  ),
                ),
                _SaveBar(
                  state: state,
                  horizontalPadding: horizontal,
                  onSave: () => _bloc.add(const OnSubmitCategoryForm()),
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

/// The circular preview from the design, showing the glyph and colour the
/// category will actually carry in the grid and on the dashboard chart.
///
/// In Add mode the identity is not known yet — `CategoryVisuals` is keyed by id,
/// and the id is assigned by the server — so the preview shows the neutral
/// fallback and says so.
class _PreviewAvatar extends StatelessWidget {
  final CategoryFormState state;

  const _PreviewAvatar({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color ink = CategoryVisuals.colorFor(state.id);
    final String name = state.trimmedName;

    return Column(
      children: [
        Container(
          width: 96.r,
          height: 96.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ink.withValues(alpha: 0.12),
          ),
          alignment: Alignment.center,
          child: Icon(
            CategoryVisuals.iconFor(state.id),
            size: 40.r,
            color: ink,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          name.isEmpty ? 'categories.preview_placeholder'.tr() : name,
          style: TextStyleApp.dashboardSectionTitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Text(
          'categories.preview_caption'.tr(),
          style: TextStyleApp.dashboardCaption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// The white card holding the single name field.
class _FormCard extends StatelessWidget {
  final CategoryFormState state;
  final ValueChanged<String> onNameChanged;

  const _FormCard({required this.state, required this.onNameChanged});

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
          LabelledTextField(
            key: const Key('category_form_name'),
            label: 'categories.name_label'.tr(),
            hint: 'categories.name_hint'.tr(),
            initialValue: state.name,
            onChanged: onNameChanged,
            errorKey: state.showErrors ? state.errors.name : null,
            icon: Icons.label_outline,
            maxLength: CategoryFormBloc.maxNameLength,
          ),
          SizedBox(height: 12.h),
          Text(
            'categories.name_helper'.tr(),
            style: TextStyleApp.dashboardCaption,
          ),
        ],
      ),
    );
  }
}

/// The pinned save button, with the delete action beside it in Edit mode.
///
/// Structurally identical to the accounts form's save bar; the two are kept
/// separate because their states are different types, and folding them into one
/// generic widget would need a shared interface neither bloc has.
class _SaveBar extends StatelessWidget {
  final CategoryFormState state;
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
            SizedBox(
              width: 56.h,
              height: 56.h,
              child: OutlinedButton(
                key: const Key('category_form_delete'),
                onPressed: state.isBusy ? null : onDelete,
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
                child: state.isDeleting
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
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: SizedBox(
              height: 56.h,
              child: ElevatedButton(
                key: const Key('category_form_save'),
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
                            ? 'categories.save_changes'.tr()
                            : 'categories.save_new'.tr(),
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
