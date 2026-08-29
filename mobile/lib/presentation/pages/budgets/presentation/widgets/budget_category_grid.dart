import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The form's three-column category picker.
///
/// The design draws a fixed grid of six tiles rather than the dropdown the
/// transaction form uses, so that is what this reproduces. It renders whatever
/// categories the repository returned — the six names in the mockup are the
/// designer's sample data, not a fixed set, and `categories` has no "other" row
/// to fall back on.
class BudgetCategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  /// Validation message key, rendered under the grid when non-null.
  final String? errorKey;

  const BudgetCategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.errorKey,
  });

  /// Rows of three, matching the design's `grid-cols-3`.
  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    // Ids are what a budget stores, so a category without one cannot be chosen.
    final List<Category> selectable = <Category>[
      for (final c in categories)
        if (c.id != null) c,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.select_category'.tr(),
          style: TextStyleApp.budgetsFormSectionLabel,
        ),
        SizedBox(height: 12.h),
        if (selectable.isEmpty)
          Text(
            'budgets.no_categories'.tr(),
            style: TextStyleApp.dashboardStatLabel,
          )
        else
          GridView.builder(
            // Inside a scrolling form, so it must size to its content and not
            // scroll on its own.
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: selectable.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              // Slightly wider than tall, which keeps a two-word category name
              // on one line at the design's tile size.
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final Category category = selectable[index];
              return _CategoryTile(
                category: category,
                selected: category.id == selectedId,
                onTap: () => onSelected(category.id!),
              );
            },
          ),
        if (errorKey != null) ...[
          SizedBox(height: 8.h),
          Text(errorKey!.tr(), style: TextStyleApp.transactionsFieldError),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(16.r);
    final Color ink = selected
        ? ColorsApp.primaryGreenPressed
        : ColorsApp.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? ColorsApp.primaryGreenPressed.withValues(alpha: 0.06)
            : ColorsApp.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? ColorsApp.primaryGreenPressed
                    : ColorsApp.outlineVariant.withValues(alpha: 0.6),
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CategoryVisuals.iconFor(category.id),
                    size: 22.r,
                    color: ink,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    category.name ?? 'unknown'.tr(),
                    style: TextStyleApp.budgetsCategoryTile.copyWith(
                      color: ink,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
