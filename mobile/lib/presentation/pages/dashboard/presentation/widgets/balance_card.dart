import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// "الرصيد الإجمالي" — the hero card at the top of the dashboard.
class BalanceCard extends StatelessWidget {
  final DashboardSummary summary;

  /// The masked family account number.
  ///
  /// TODO(backend): supplied by the mock source because nothing in the schema
  /// can produce it — `accounts` has no number column and there is no
  /// `families` table. When null the whole row is hidden rather than showing a
  /// fake value, so a real (unmocked) run never displays invented data.
  final String? maskedAccountNumber;

  const BalanceCard({
    super.key,
    required this.summary,
    this.maskedAccountNumber,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dashboard.total_balance'.tr(),
                      style: TextStyleApp.dashboardCardLabel,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Flexible + FittedBox: a long balance shrinks instead
                        // of overflowing on narrow screens.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              DashboardFormatter.amount(summary.totalBalance),
                              style: TextStyleApp.dashboardBalance,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'dashboard.currency_sar'.tr(),
                          style: TextStyleApp.dashboardCurrency,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _WalletChip(),
            ],
          ),
          if (maskedAccountNumber != null) ...[
            SizedBox(height: 24.h),
            Divider(
              height: 1,
              thickness: 1,
              color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.family_account_number'.tr(),
                        style: TextStyleApp.dashboardCaption,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        maskedAccountNumber!,
                        style: TextStyleApp.dashboardAccountNumber,
                      ),
                    ],
                  ),
                ),
                const _MemberAvatars(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 40px rounded tile holding the wallet glyph.
class _WalletChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.r,
      height: 40.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorsApp.progressTrack,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        size: 20.r,
        color: ColorsApp.primaryGreenPressed,
      ),
    );
  }
}

/// The overlapping family-member avatars from the design.
///
/// TODO(backend): entirely presentational for now. There is no `families` table
/// and no avatar column on `users`, so neither the member list nor their photos
/// can be fetched. Rendered as neutral initials-free circles rather than fake
/// faces, and it must be replaced once family membership exists in the schema.
class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars();

  static const int _placeholderCount = 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28.r,
      width: (28 + (_placeholderCount - 1) * 20).r,
      child: Stack(
        children: [
          for (int i = 0; i < _placeholderCount; i++)
            PositionedDirectional(
              start: (i * 20).r,
              child: Container(
                width: 28.r,
                height: 28.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorsApp.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorsApp.white, width: 2),
                ),
                child: Icon(
                  Icons.person,
                  size: 14.r,
                  color: ColorsApp.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
