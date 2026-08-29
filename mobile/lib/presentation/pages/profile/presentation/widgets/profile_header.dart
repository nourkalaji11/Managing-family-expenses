import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The card at the top of the profile screen: initial, name, email, role pill,
/// and — for a member — their spending ceiling.
///
/// The avatar is the name's first letter rather than a photo. `users` has no
/// avatar column and this repository ships no `assets/images/`, so a photo
/// would have to be either a placeholder face or a generic silhouette; a
/// monogram is honest and reads better at 80px.
class ProfileHeader extends StatelessWidget {
  final User user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String name = (user.name ?? '').trim();
    final String initial = name.isEmpty ? '؟' : name.characters.first;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: ColorsApp.primaryGreenPressed,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          // Tinted to the card's own hue rather than pure black, matching
          // `AccountsTotalCard`.
          BoxShadow(
            color: ColorsApp.primaryGreenPressed.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorsApp.white.withValues(alpha: 0.18),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyleApp.dashboardBalance.copyWith(
                color: ColorsApp.white,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            name.isEmpty ? 'profile.unnamed'.tr() : name,
            style: TextStyleApp.dashboardSectionTitle.copyWith(
              color: ColorsApp.white,
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            user.email ?? '',
            style: TextStyleApp.dashboardCardLabel.copyWith(
              color: ColorsApp.white.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 14.h),
          _RolePill(isParent: user.isParent),
          // A ceiling is only meaningful for a member: a parent is not capped,
          // and the server refuses to set one on them. Showing "0" next to a
          // parent's name would read as "cannot spend anything".
          if (!user.isParent) ...[
            SizedBox(height: 12.h),
            _LimitRow(limit: user.spendingLimit),
          ],
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final bool isParent;

  const _RolePill({required this.isParent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: ColorsApp.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isParent ? Icons.shield_outlined : Icons.person_outline,
            size: 14.r,
            color: ColorsApp.white,
          ),
          SizedBox(width: 6.w),
          Text(
            isParent ? 'auth.parent'.tr() : 'auth.family_member'.tr(),
            style: TextStyleApp.budgetsPreviewBadge.copyWith(
              color: ColorsApp.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final num? limit;

  const _LimitRow({required this.limit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'profile.my_limit'.tr(),
          style: TextStyleApp.dashboardCardLabel.copyWith(
            color: ColorsApp.white.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          // Null is "no ceiling set", which `isolatedAmount` would render as
          // 0.00 — the same misreading the parent guard above exists to avoid.
          limit == null
              ? 'profile.no_limit'.tr()
              : '${DashboardFormatter.isolatedAmount(limit)} '
                    '${'dashboard.currency_sar'.tr()}',
          style: TextStyleApp.budgetsSummaryValue.copyWith(
            color: ColorsApp.white,
          ),
        ),
      ],
    );
  }
}
