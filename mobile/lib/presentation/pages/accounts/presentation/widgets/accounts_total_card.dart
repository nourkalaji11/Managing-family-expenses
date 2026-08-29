import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The dark-green hero card at the top of the accounts list: "إجمالي الأرصدة"
/// over the summed balance.
///
/// The design also draws a "+2.4% هذا الشهر" pill under the figure. It is
/// deliberately **not** rendered: computing a month-over-month change needs a
/// historical balance, and nothing stores one. `accounts.balance` is a single
/// current value with no snapshot table, no ledger and no `balance_history`, so
/// any percentage here would be invented. The card is left with the two figures
/// that are real.
class AccountsTotalCard extends StatelessWidget {
  final num total;

  const AccountsTotalCard({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    // Existing tokens tinted for a dark surface via copyWith, which is the
    // convention the budgets summary tiles already use — no new text styles.
    final TextStyle label = TextStyleApp.dashboardCardLabel.copyWith(
      color: ColorsApp.white.withValues(alpha: 0.75),
    );
    final TextStyle value = TextStyleApp.dashboardBalance.copyWith(
      color: ColorsApp.white,
    );
    final TextStyle currency = TextStyleApp.dashboardCurrency.copyWith(
      color: ColorsApp.white.withValues(alpha: 0.85),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: ColorsApp.primaryGreenPressed,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          // Tinted to the card's own hue rather than pure black, so the shadow
          // reads as depth instead of dirt on the lavender background.
          BoxShadow(
            color: ColorsApp.primaryGreenPressed.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'accounts.total_label'.tr(),
            style: label,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          // Baseline-aligned so the currency suffix sits on the figure's
          // baseline rather than its centre, matching the dashboard card.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  // Isolated, so a negative total keeps reading as "-1,200.00"
                  // instead of being reordered inside the RTL paragraph.
                  DashboardFormatter.isolatedAmount(total),
                  style: value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text('dashboard.currency_sar'.tr(), style: currency),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
