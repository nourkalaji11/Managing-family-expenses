import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The rule-label-rule separator above each day's rows.
class TransactionDayHeader extends StatelessWidget {
  /// Midnight-normalised day, or null for the trailing group of rows that carry
  /// no date at all.
  final DateTime? day;

  const TransactionDayHeader({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final String label = day == null
        ? 'transactions.undated'.tr()
        : DashboardFormatter.dayHeader(day);

    return Row(
      children: [
        const Expanded(child: _Rule()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(label, style: TextStyleApp.transactionsDayHeader),
        ),
        const Expanded(child: _Rule()),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: ColorsApp.outlineVariant);
  }
}
