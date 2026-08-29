import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One category in the grid: tinted icon tile, name, transaction count.
///
/// Tapping it opens Edit, matching how `BudgetCard` and `AccountCard` behave.
///
/// The icon and its tint come from `CategoryVisuals`, which derives both from
/// the category id — `categories` is `(id, name)` with no `icon` or `color`
/// column. Renaming a category therefore keeps its colour, which is the correct
/// behaviour and the reason that lookup is keyed by id rather than by name.
class CategoryTile extends StatelessWidget {
  final Category category;

  /// Position in the grid, used only to pick a fallback colour for a category
  /// `CategoryVisuals` has no explicit entry for.
  final int index;

  final int transactionCount;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.category,
    required this.index,
    required this.transactionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(20.r);
    final Color ink = CategoryVisuals.colorFor(category.id, index: index);

    return Material(
      color: ColorsApp.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    // The category's own colour at low opacity, so every tile
                    // is distinguishable without shouting.
                    color: ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CategoryVisuals.iconFor(category.id),
                    size: 24.r,
                    color: ink,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  // A category with no name cannot happen server-side
                  // (`required`), so this only covers a malformed payload.
                  category.name?.trim().isNotEmpty == true
                      ? category.name!.trim()
                      : 'categories.untitled'.tr(),
                  style: TextStyleApp.transactionsRowTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'accounts.transactions_count'.plural(transactionCount),
                  style: TextStyleApp.dashboardStatLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dashed "فئة جديدة" tile that closes the grid.
///
/// It sits inside the grid rather than only on the FAB because the design puts
/// it there, and because an empty grid then still offers its own way forward.
class CategoryAddTile extends StatelessWidget {
  final VoidCallback onTap;

  const CategoryAddTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(20.r);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            // Flutter has no dashed border primitive and this repository ships
            // no painter for one. A solid hairline at reduced opacity reads as
            // the same "not a real card yet" affordance without hand-rolling a
            // custom painter for decoration alone.
            border: Border.all(
              color: ColorsApp.outlineVariant.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorsApp.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add,
                    size: 24.r,
                    color: ColorsApp.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'categories.new_tile'.tr(),
                  style: TextStyleApp.budgetsCategoryTile,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
