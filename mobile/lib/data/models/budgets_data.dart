import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/category.dart';

/// Everything the budgets feature loads in one call.
///
/// The list screen needs [budgets]; the add/edit form needs [categories] to
/// populate its category grid. They are fetched together so opening the form
/// never has to block on a second round trip — the same arrangement as
/// `TransactionsData`.
class BudgetsData {
  /// Newest first. Ordering is applied by the repository so the mock and the
  /// future remote path agree.
  final List<BudgetModel> budgets;

  final List<Category> categories;

  const BudgetsData({required this.budgets, required this.categories});
}

/// The editable half of a budget: exactly the fields the add/edit form owns,
/// and nothing else.
///
/// Deliberately mirrors the `budgets` columns that a write must supply:
///
///     limit_amount  DECIMAL(15,2)  NOT NULL
///     start_date    DATE           NOT NULL
///     end_date      DATE           NOT NULL
///     category_id   FK             NOT NULL
///
/// `id`, `created_at`, `user_id` and `current_spending` are absent on purpose:
/// the form never edits them, and the edit flow preserves the existing values.
class BudgetDraft {
  final int categoryId;
  final num limitAmount;
  final DateTime startDate;
  final DateTime endDate;

  const BudgetDraft({
    required this.categoryId,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
  });

  /// The JSON body the `budgets` endpoints accept.
  ///
  /// Sent as-is by both `BudgetsRepo._remoteCreate` (`POST /budgets`) and
  /// `_remoteUpdate` (`PUT /budgets/{id}`), whose validators are identical.
  /// `user_id` is absent on purpose: the server reads it from the bearer token
  /// on create and preserves the existing owner on update.
  ///
  /// `current_spending` is absent too — see `BudgetsRepo`: no controller writes
  /// that column, so the client derives it rather than sending it.
  Map<String, dynamic> toRequestJson() => {
    'category_id': categoryId,
    'limit_amount': limitAmount,
    // Both columns are SQL `DATE`, so only the calendar day goes on the wire.
    'start_date': _formatDate(startDate),
    'end_date': _formatDate(endDate),
  };

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
