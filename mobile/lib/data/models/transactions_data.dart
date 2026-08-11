import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';

/// Everything the transactions feature loads in one call.
///
/// The list screen needs [transactions]; the add/edit form needs [accounts] and
/// [categories] to populate its pickers. They are fetched together so opening
/// the form never has to block on a second round trip.
class TransactionsData {
  /// Newest first. Ordering is applied by the repository so the mock and the
  /// future remote path agree.
  final List<TransactionModel> transactions;

  final List<Account> accounts;
  final List<Category> categories;

  const TransactionsData({
    required this.transactions,
    required this.accounts,
    required this.categories,
  });
}

/// The editable half of a transaction: exactly the fields the add/edit form
/// owns, and nothing else.
///
/// Deliberately mirrors the request body that
/// `TransactionController::store` already validates on branch
/// `origin/souad-backend`:
///
///     'account_id'  => 'required|exists:accounts,id',
///     'category_id' => 'required|exists:categories,id',
///     'amount'      => 'required|numeric|min:0.01',
///     'type'        => 'required|in:income,expense',
///     'description' => 'nullable|string|max:255',
///     'date'        => 'required|date',
///
/// Keeping the shape identical means wiring the real endpoint later is a
/// serialisation change inside the repository, not a change to the form, the
/// bloc or the validation rules.
///
/// `id`, `created_at` and `user_id` are absent on purpose: the form never edits
/// them, and the edit flow preserves the existing values.
class TransactionDraft {
  final num amount;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final int accountId;
  final int categoryId;

  const TransactionDraft({
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.accountId,
    required this.categoryId,
  });

  /// The exact JSON body the backend's validator accepts.
  ///
  /// TODO(backend): unused for now, and intentionally so. `store()` calls
  /// `Transaction::create($validated)` without ever setting the NOT NULL
  /// `user_id` column, so posting this body fails on an integrity constraint;
  /// `update()` is an empty stub that returns 200 and changes nothing. This
  /// method exists as the single documented place the contract lives, so that
  /// enabling the real calls does not require re-deriving it. See
  /// `TransactionsRepo`.
  Map<String, dynamic> toRequestJson() => {
    'account_id': accountId,
    'category_id': categoryId,
    'amount': amount,
    'type': type.apiValue,
    'description': description,
    // The column is SQL `DATE`, so only the calendar day goes on the wire.
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
  };
}
