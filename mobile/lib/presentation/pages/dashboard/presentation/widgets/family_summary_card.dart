import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/user.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// "أفراد العائلة" — who is in the family and how much of their allowance is
/// left.
///
/// ---------------------------------------------------------------------------
/// Shown to a parent only. `GET /users` scopes its answer by role, so a member
/// receives a list containing only themselves and `DashboardData.children`
/// filters that to nothing — the card disappears without the screen having to
/// know the rule.
///
/// It reports **allowance, spent and remaining**, not a balance per person.
/// That is not a simplification: `accounts` has no per-person balance and no
/// owner beyond who created the row, and the family's accounts are explicitly
/// shared — `DashboardController` sums them all for everyone. Splitting that
/// total between children would be an invented number. What each child actually
/// controls is their allowance, which is what this draws.
/// ---------------------------------------------------------------------------
class FamilySummaryCard extends StatelessWidget {
  final List<User> members;

  /// Opens the family screen, where allowances are edited and members added.
  final VoidCallback? onManage;

  const FamilySummaryCard({
    super.key,
    required this.members,
    this.onManage,
  });

  /// Where a bar turns amber. The same ratio at which the server sends the
  /// "running out" warning, so the colour and the notification agree.
  static const double warnRatio = 0.8;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dashboard.family_title'.tr(),
                      style: TextStyleApp.dashboardSectionTitle,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'dashboard.family_count'.tr(
                        namedArgs: {'count': members.length.toString()},
                      ),
                      style: TextStyleApp.dashboardStatLabel,
                    ),
                  ],
                ),
              ),
              if (onManage != null)
                TextButton(
                  key: const Key('dashboard_family_manage'),
                  onPressed: onManage,
                  child: Text(
                    'dashboard.family_view_all'.tr(),
                    style: TextStyleApp.dashboardSectionAction,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          for (int i = 0; i < members.length; i++) ...[
            if (i > 0) SizedBox(height: 16.h),
            _MemberRow(member: members[i]),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final User member;

  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final num? limit = member.spendingLimit;
    final num spent = member.spent ?? 0;
    final bool over = limit != null && spent > limit;

    // Null when there is no allowance: a bar needs something to be a fraction
    // of, and drawing an empty one would imply a ceiling that does not exist.
    final double? usage = (limit == null || limit <= 0)
        ? null
        : (spent / limit).clamp(0, 1).toDouble();

    final Color ink = over
        ? ColorsApp.errorRed
        : ((usage ?? 0) >= FamilySummaryCard.warnRatio
              ? ColorsApp.dashboardAmber
              : ColorsApp.primaryGreenPressed);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(name: member.name),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      member.name ?? '',
                      style: TextStyleApp.budgetsCardFooterValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    limit == null
                        ? 'dashboard.member_no_limit'.tr()
                        : '${DashboardFormatter.isolatedAmount(member.remaining ?? 0)} '
                              '${'dashboard.currency_sar'.tr()}',
                    style: TextStyleApp.budgetsCardFooterValue.copyWith(
                      color: ink,
                    ),
                  ),
                ],
              ),
              if (usage != null) ...[
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: usage,
                    minHeight: 6.h,
                    backgroundColor: ColorsApp.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(ink),
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              Text(
                _caption(limit, spent, over),
                style: TextStyleApp.budgetsCardCaption.copyWith(
                  color: over ? ColorsApp.errorRed : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _caption(num? limit, num spent, bool over) {
    if (over) return 'dashboard.member_over'.tr();
    if (spent == 0) return 'dashboard.member_nothing_spent'.tr();
    if (limit == null) {
      // No ceiling, but they have spent — the figure alone is still the answer
      // to "how much has this child spent".
      return '${DashboardFormatter.isolatedAmount(spent)} '
          '${'dashboard.currency_sar'.tr()}';
    }
    return 'dashboard.member_spent_of'.tr(
      namedArgs: {
        'spent': DashboardFormatter.isolatedAmount(spent),
        'limit': DashboardFormatter.isolatedAmount(limit),
      },
    );
  }
}

/// The initial, matching the family screen's avatars so the same person reads
/// the same way on both.
class _Avatar extends StatelessWidget {
  final String? name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final String trimmed = (name ?? '').trim();
    final String initial = trimmed.isEmpty ? '?' : trimmed.characters.first;

    return Container(
      width: 40.r,
      height: 40.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorsApp.primaryGreenPressed.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyleApp.budgetsCardFooterValue.copyWith(
          color: ColorsApp.primaryGreenPressed,
        ),
      ),
    );
  }
}
