import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/style/colors.dart';

/// Colour and copy for a [BudgetStatus].
///
/// One lookup rather than a switch repeated in every widget: the card, the
/// progress bar and the form preview all read a budget's state from here, so
/// they can never disagree about what amber means.
///
/// Unlike `CategoryVisuals`, this is **not** a stand-in for a missing column.
/// The status is derived from `limit_amount` and `current_spending`, both of
/// which exist; only the palette is a presentation decision, and it belongs on
/// the client.
class BudgetStatusVisuals {
  const BudgetStatusVisuals._();

  /// The ink for the status line, and the fill of the progress bar.
  static Color colorFor(BudgetStatus status) => switch (status) {
    BudgetStatus.exceeded => ColorsApp.errorRed,
    BudgetStatus.nearLimit => ColorsApp.budgetWarning,
    // The design draws both the 45% and the 10% cards in the primary green;
    // only their wording differs.
    BudgetStatus.onTrack || BudgetStatus.earlyStage =>
      ColorsApp.primaryGreenPressed,
  };

  /// The translated status line: "تم استهلاك 45%", "اقتربت من الحد (82%)",
  /// "تجاوزت الميزانية بـ 150 ر.س", "بداية جيدة (10%)".
  ///
  /// Returns the finished string rather than a key, because three of the four
  /// need an interpolated figure that only the budget can supply.
  static String labelFor(BudgetModel budget) {
    final String currency = 'dashboard.currency_sar'.tr();

    if (budget.status == BudgetStatus.exceeded) {
      return 'budgets.status_exceeded'.tr(
        namedArgs: <String, String>{
          'amount': '${DashboardFormatter.compactAmount(budget.overBy)} '
              '$currency',
        },
      );
    }

    final String percent = DashboardFormatter.percent(budget.progress);
    return switch (budget.status) {
      BudgetStatus.nearLimit => 'budgets.status_near_limit'.tr(
        namedArgs: <String, String>{'percent': percent},
      ),
      BudgetStatus.earlyStage => 'budgets.status_early'.tr(
        namedArgs: <String, String>{'percent': percent},
      ),
      _ => 'budgets.status_on_track'.tr(
        namedArgs: <String, String>{'percent': percent},
      ),
    };
  }
}
