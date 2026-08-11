import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';
import 'package:family_expense_management/data/models/transactions_data.dart';
import 'package:family_expense_management/data/repos/transactions_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/transactions/domain/transactions_domain.dart';

part 'transaction_form_event.dart';
part 'transaction_form_state.dart';

/// Drives both Add and Edit.
///
/// The two differ only in what seeds the state and which repository method runs
/// on submit, so there is one bloc and one form rather than two near-identical
/// copies. [TransactionFormState.mode] is the only branch.
///
/// Validation lives here, not in the widgets. The rules mirror the ones
/// `TransactionController::store` already enforces on `origin/souad-backend`,
/// with one addition the UI owns: the date may not be in the future.
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  final TransactionsDomain _repo;

  TransactionFormBloc({TransactionsDomain? repo})
    : _repo = repo ?? TransactionsRepo(),
      super(TransactionFormState.initial()) {
    on<TransactionFormEvent>((event, emit) async {
      if (event is OnFormStarted) {
        final TransactionFormState seeded = _seed(event);
        emit(seeded);

        // The transactions list hands its already-loaded options down, so this
        // usually does nothing. It matters when the form is opened from
        // somewhere that has no options to give — the dashboard's "إضافة
        // معاملة" quick action — which pushes the route with no arguments
        // rather than duplicating a load the form can do itself.
        if (seeded.accounts.isEmpty || seeded.categories.isEmpty) {
          await _loadOptions(emit);
        }
      } else if (event is OnAmountDigitPressed) {
        emit(_withInput(_appendDigit(state.amountInput, event.digit)));
      } else if (event is OnAmountBackspace) {
        emit(_withInput(_removeLastDigit(state.amountInput)));
      } else if (event is OnTypeChanged) {
        emit(_revalidated(state.copyWith(type: event.type)));
      } else if (event is OnAccountChanged) {
        emit(_revalidated(state.copyWith(accountId: event.accountId)));
      } else if (event is OnCategoryChanged) {
        emit(_revalidated(state.copyWith(categoryId: event.categoryId)));
      } else if (event is OnDateChanged) {
        emit(_revalidated(state.copyWith(date: event.date)));
      } else if (event is OnDescriptionChanged) {
        emit(_revalidated(state.copyWith(description: event.description)));
      } else if (event is OnSubmitForm) {
        await _submit(emit);
      }
    });
  }

  TransactionFormState _seed(OnFormStarted event) {
    final TransactionModel? existing = event.transaction;

    if (existing == null) {
      return TransactionFormState(
        mode: TransactionFormMode.add,
        accounts: event.accounts,
        categories: event.categories,
        // Pre-selecting the only sensible defaults keeps the form usable
        // without inventing data: first account, no category until chosen.
        accountId: event.accounts.isEmpty ? null : event.accounts.first.id,
        categoryId: null,
        date: _todayAtMidnight(),
        errors: const TransactionFormErrors(),
      );
    }

    return TransactionFormState(
      mode: TransactionFormMode.edit,
      // Preserved verbatim through the whole edit and handed back to the repo,
      // which uses it to replace in place rather than append.
      id: existing.id,
      accounts: event.accounts,
      categories: event.categories,
      amountInput: _amountToInput(existing.amount),
      type: existing.type,
      accountId: existing.accountId ?? existing.account?.id,
      categoryId: existing.categoryId ?? existing.category?.id,
      date: existing.date ?? existing.createdAt ?? _todayAtMidnight(),
      description: existing.description ?? '',
      errors: const TransactionFormErrors(),
    );
  }

  /// Fetches the account and category options through the same domain contract
  /// the list uses, so there is one source for them.
  Future<void> _loadOptions(Emitter<TransactionFormState> emit) async {
    final result = await _repo.getTransactions();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TransactionFormStatus.failure,
          failure: failure,
        ),
      ),
      (data) {
        // Only fills a gap: an id already chosen (Edit, or a seeded default)
        // wins over the fallback.
        final int? accountId =
            state.accountId ??
            (data.accounts.isEmpty ? null : data.accounts.first.id);

        emit(
          state.copyWith(
            accounts: data.accounts,
            categories: data.categories,
            accountId: accountId,
          ),
        );
      },
    );
  }

  TransactionFormState _withInput(String input) =>
      _revalidated(state.copyWith(amountInput: input));

  /// Recomputes the error set after any field change.
  ///
  /// Errors are always computed but only *rendered* once [showErrors] is set by
  /// a submit attempt, so the form does not shout at the user before they have
  /// filled anything in.
  TransactionFormState _revalidated(TransactionFormState next) =>
      next.copyWith(errors: validate(next), status: TransactionFormStatus.editing);

  Future<void> _submit(Emitter<TransactionFormState> emit) async {
    // Guards double submission: a second tap while the first save is in flight
    // is dropped rather than creating two rows.
    if (state.isSubmitting) return;

    final TransactionFormErrors errors = validate(state);
    if (errors.hasAny) {
      emit(state.copyWith(errors: errors, showErrors: true));
      return;
    }

    emit(
      state.copyWith(
        status: TransactionFormStatus.submitting,
        showErrors: true,
        errors: errors,
        clearFailure: true,
      ),
    );

    final String trimmed = state.description.trim();
    final TransactionDraft draft = TransactionDraft(
      // Safe: `validate` has already rejected a null or non-positive amount.
      amount: parseAmount(state.amountInput)!,
      type: state.type,
      // An empty note is stored as null, matching the column's `nullable`.
      description: trimmed.isEmpty ? null : trimmed,
      date: state.date,
      accountId: state.accountId!,
      categoryId: state.categoryId!,
    );

    final result = state.mode == TransactionFormMode.add
        ? await _repo.createTransaction(draft)
        : await _repo.updateTransaction(state.id!, draft);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TransactionFormStatus.failure,
          failure: failure,
        ),
      ),
      (saved) => emit(
        state.copyWith(status: TransactionFormStatus.success, saved: saved),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation. Returns localisation KEYS, not translated strings, so the bloc
  // stays free of easy_localization and the widget owns presentation.
  // ---------------------------------------------------------------------------

  /// Mirrors the backend's `store()` rules, plus the UI-only future-date rule.
  static TransactionFormErrors validate(TransactionFormState state) {
    final num? amount = parseAmount(state.amountInput);

    String? amountError;
    if (amount == null) {
      amountError = 'transactions.error_amount_required';
    } else if (amount <= 0) {
      // Backend rule: `numeric|min:0.01`.
      amountError = 'transactions.error_amount_positive';
    }

    final String? accountError = state.accountId == null
        ? 'transactions.error_account_required'
        : null;

    final String? categoryError = state.categoryId == null
        ? 'transactions.error_category_required'
        : null;

    // The date is never null in this state, so the only failure mode is a
    // future date — a UI rule, since the backend accepts any parseable date.
    final String? dateError = _isAfterToday(state.date)
        ? 'transactions.error_date_future'
        : null;

    // Backend rule: `nullable|string|max:255`.
    final String? descriptionError = state.description.trim().length > 255
        ? 'transactions.error_description_long'
        : null;

    return TransactionFormErrors(
      amount: amountError,
      account: accountError,
      category: categoryError,
      date: dateError,
      description: descriptionError,
    );
  }

  /// Parses the keypad buffer. Returns null when nothing usable was typed.
  static num? parseAmount(String input) {
    if (input.isEmpty) return null;
    // A lone "." or a trailing "." is mid-typing, not a number.
    final String normalised = input.endsWith('.')
        ? input.substring(0, input.length - 1)
        : input;
    if (normalised.isEmpty) return null;
    return num.tryParse(normalised);
  }

  // ---------------------------------------------------------------------------
  // Keypad buffer. Mirrors the design's behaviour, with two limits the schema
  // imposes: `transactions.amount` is DECIMAL(15,2).
  // ---------------------------------------------------------------------------

  /// 15 total digits with 2 after the point leaves 13 before it.
  static const int maxIntegerDigits = 13;
  static const int maxDecimalDigits = 2;

  static String _appendDigit(String current, String digit) {
    if (digit == '.') {
      if (current.contains('.')) return current;
      return current.isEmpty ? '0.' : '$current.';
    }

    final int dot = current.indexOf('.');
    if (dot < 0) {
      // Leading zero is replaced rather than accumulated, so "0" then "5"
      // reads "5", not "05".
      if (current == '0') return digit;
      if (current.length >= maxIntegerDigits) return current;
      return '$current$digit';
    }

    final String decimals = current.substring(dot + 1);
    if (decimals.length >= maxDecimalDigits) return current;
    return '$current$digit';
  }

  static String _removeLastDigit(String current) {
    if (current.isEmpty) return current;
    return current.substring(0, current.length - 1);
  }

  /// Renders an existing amount back into the keypad buffer for Edit.
  ///
  /// Trailing ".00" is dropped so a whole amount opens as "240", not "240.00",
  /// which is what the user would have typed.
  static String _amountToInput(num? amount) {
    if (amount == null) return '';
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount
        .toStringAsFixed(maxDecimalDigits)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static DateTime _todayAtMidnight() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool _isAfterToday(DateTime date) {
    final DateTime today = _todayAtMidnight();
    final DateTime d = DateTime(date.year, date.month, date.day);
    return d.isAfter(today);
  }
}
