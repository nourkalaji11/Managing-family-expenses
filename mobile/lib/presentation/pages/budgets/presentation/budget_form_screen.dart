import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/presentation/pages/budgets/bloc/budget_form_bloc.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_category_grid.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_date_field.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_form_hint_card.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_limit_field.dart';
import 'package:family_expense_management/presentation/pages/budgets/presentation/widgets/budget_preview_card.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Route arguments for both Add and Edit.
///
/// [budget] null means Add. [categories] is passed down from the list screen's
/// loaded state so the form's grid is populated without a second load, and
/// [month] is the month the list was showing, which Add uses to default its
/// period.
class BudgetFormArgs {
  final BudgetModel? budget;
  final List<Category> categories;
  final DateTime? month;

  const BudgetFormArgs({
    required this.budget,
    required this.categories,
    this.month,
  });
}

/// Add and Edit, in one screen.
///
/// The mode comes from whether [BudgetFormArgs.budget] is null. There is
/// deliberately no second, near-identical form widget: the layout, the
/// validation and the save path are the same, and only the title, the seeded
/// values and the repository call differ.
///
/// Pushed as a full-screen route with a back arrow and no bottom navigation.
/// The design shows both a back arrow and the tab bar, which cannot coexist on
/// a pushed route.
///
/// Two elements of the design are deliberately absent:
///   * The "تنبيه تخطي الميزانية" toggle. TODO(backend): the `budgets` table has
///     no alert, threshold or notification column, and nothing on
///     `origin/souad-backend` sends a budget notification — a switch that
///     silently discarded its own value would be worse than no switch.
///   * A delete action. The design defines none, and `BudgetController` has no
///     `destroy` method to call.
class BudgetFormScreen extends StatefulWidget {
  /// Optional. When null the arguments are read from the route settings, which
  /// is how `AppRoutes` builds this screen.
  final BudgetFormArgs? args;

  const BudgetFormScreen({super.key, this.args});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  static const double _pagePadding = 20;

  late final BudgetFormBloc _bloc;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _bloc = BudgetFormBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route arguments are only available once there is a context, so the form
    // is seeded here rather than in `initState`. The flag keeps it to one seed.
    if (_started) return;
    _started = true;

    final BudgetFormArgs args = _resolveArgs();
    _bloc.add(
      OnBudgetFormStarted(
        budget: args.budget,
        categories: args.categories,
        month: args.month,
      ),
    );
  }

  BudgetFormArgs _resolveArgs() {
    final BudgetFormArgs? direct = widget.args;
    if (direct != null) return direct;

    final Object? routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is BudgetFormArgs) return routeArgs;

    // A route pushed without arguments renders an Add form that loads its own
    // category options. See `BudgetFormBloc._loadOptions`.
    return const BudgetFormArgs(budget: null, categories: <Category>[]);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // A budget may legitimately be set for a past or a future period — unlike
      // a transaction, which cannot happen in the future — so the range is wide
      // and merely bounded. The schema imposes no limit of its own.
      firstDate: DateTime(initial.year - 10),
      lastDate: DateTime(initial.year + 10, 12, 31),
    );

    if (picked != null && mounted) {
      onPicked(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return BlocConsumer<BudgetFormBloc, BudgetFormState>(
      bloc: _bloc,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == BudgetFormStatus.success) {
          EasyLoading.showToast(
            state.isEditing
                ? 'budgets.updated'.tr()
                : 'budgets.created'.tr(),
            toastPosition: EasyLoadingToastPosition.bottom,
          );
          // `true` is the signal the list refreshes on.
          Navigator.of(context).pop(true);
        } else if (state.status == BudgetFormStatus.failure) {
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
                  ? 'budgets.edit_title'.tr()
                  : 'budgets.add_title'.tr(),
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
                      const BudgetFormHintCard(),
                      SizedBox(height: 20.h),
                      _FormCard(
                        state: state,
                        onCategorySelected: (id) =>
                            _bloc.add(OnBudgetCategoryChanged(id)),
                        onLimitChanged: (v) =>
                            _bloc.add(OnBudgetLimitChanged(v)),
                        onPickStartDate: () => _pickDate(
                          initial: state.startDate,
                          onPicked: (d) =>
                              _bloc.add(OnBudgetStartDateChanged(d)),
                        ),
                        onPickEndDate: () => _pickDate(
                          initial: state.endDate,
                          onPicked: (d) =>
                              _bloc.add(OnBudgetEndDateChanged(d)),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      BudgetPreviewCard(
                        limitAmount: state.limitAmount,
                        categoryName: state.selectedCategory?.name,
                        startDate: state.startDate,
                        endDate: state.endDate,
                      ),
                    ],
                  ),
                ),
                _SaveBar(
                  isSubmitting: state.isSubmitting,
                  horizontalPadding: horizontal,
                  onPressed: () => _bloc.add(const OnSubmitBudgetForm()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The white card holding the category grid, the limit and the two dates.
class _FormCard extends StatelessWidget {
  final BudgetFormState state;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<String> onLimitChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;

  const _FormCard({
    required this.state,
    required this.onCategorySelected,
    required this.onLimitChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
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
          BudgetCategoryGrid(
            key: const Key('budget_form_categories'),
            categories: state.categories,
            selectedId: state.categoryId,
            onSelected: onCategorySelected,
            errorKey: showErrors ? state.errors.category : null,
          ),
          SizedBox(height: 24.h),
          BudgetLimitField(
            initialValue: state.limitInput,
            errorKey: showErrors ? state.errors.limitAmount : null,
            onChanged: onLimitChanged,
          ),
          SizedBox(height: 24.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BudgetDateField(
                  key: const Key('budget_form_start_date'),
                  label: 'budgets.start_date'.tr(),
                  value: state.startDate,
                  icon: Icons.calendar_today_outlined,
                  onTap: onPickStartDate,
                  errorKey: showErrors ? state.errors.startDate : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: BudgetDateField(
                  key: const Key('budget_form_end_date'),
                  label: 'budgets.end_date'.tr(),
                  value: state.endDate,
                  icon: Icons.event_outlined,
                  onTap: onPickEndDate,
                  errorKey: showErrors ? state.errors.endDate : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pinned "حفظ الميزانية" button.
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
      width: double.infinity,
      color: ColorsApp.dashboardBackground,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12.h,
        horizontalPadding,
        16.h,
      ),
      child: SizedBox(
        height: 56.h,
        child: ElevatedButton(
          key: const Key('budget_form_save'),
          // Null while saving: this is what blocks a double submission at the
          // UI layer. The bloc drops a duplicate event as well.
          onPressed: isSubmitting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsApp.primaryGreenPressed,
            disabledBackgroundColor: ColorsApp.primaryGreenPressed.withValues(
              alpha: 0.6,
            ),
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
                        'budgets.save'.tr(),
                        style: TextStyleApp.transactionsSaveButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.done_all,
                      size: 22.r,
                      color: ColorsApp.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
