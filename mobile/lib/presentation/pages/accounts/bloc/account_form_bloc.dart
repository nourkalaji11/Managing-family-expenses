import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/accounts_data.dart';
import 'package:family_expense_management/data/repos/accounts_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/accounts/domain/accounts_domain.dart';

part 'account_form_event.dart';
part 'account_form_state.dart';

/// Drives both Add and Edit, plus Delete.
///
/// The two write flows differ only in what seeds the state and which repository
/// method runs on submit, so there is one bloc and one screen rather than two
/// near-identical copies. [AccountFormState.mode] is the only branch — the same
/// arrangement as `BudgetFormBloc`.
///
/// Validation lives here, not in the widgets, and mirrors exactly what
/// `AccountController` validates:
///
///     'name'    => 'required|string|max:100'
///     'balance' => 'required|numeric'
class AccountFormBloc extends Bloc<AccountFormEvent, AccountFormState> {
  final AccountsDomain _repo;

  AccountFormBloc({AccountsDomain? repo})
    : _repo = repo ?? AccountsRepo(),
      super(AccountFormState.initial()) {
    on<AccountFormEvent>((event, emit) async {
      if (event is OnAccountFormStarted) {
        emit(_seed(event));
      } else if (event is OnAccountNameChanged) {
        emit(_revalidated(state.copyWith(name: event.name)));
      } else if (event is OnAccountBalanceChanged) {
        emit(_revalidated(state.copyWith(balanceInput: event.balanceInput)));
      } else if (event is OnSubmitAccountForm) {
        await _submit(emit);
      } else if (event is OnDeleteAccount) {
        await _delete(emit);
      }
    });
  }

  AccountFormState _seed(OnAccountFormStarted event) {
    final Account? existing = event.account;

    if (existing == null) {
      // `balance` is NOT NULL with a `0.00` default, and the design labels the
      // field "الرصيد الافتتاحي" with a "0.00" placeholder — so an empty Add
      // form starts at zero rather than blank.
      return const AccountFormState(
        mode: AccountFormMode.add,
        balanceInput: '0',
        errors: AccountFormErrors(),
      );
    }

    return AccountFormState(
      mode: AccountFormMode.edit,
      // Preserved verbatim through the whole edit and handed back to the repo.
      id: existing.id,
      name: existing.name ?? '',
      balanceInput: amountToInput(existing.balance),
      // Drives whether the delete button warns first: the server refuses a
      // delete on an account that still holds transactions.
      transactionCount: event.transactionCount,
      errors: const AccountFormErrors(),
    );
  }

  /// Recomputes the error set after any field change.
  ///
  /// Errors are always computed but only *rendered* once
  /// [AccountFormState.showErrors] is set by a submit attempt, so the form does
  /// not shout at the user before they have filled anything in.
  AccountFormState _revalidated(AccountFormState next) => next.copyWith(
    errors: validate(next),
    status: AccountFormStatus.editing,
    clearFailure: true,
  );

  Future<void> _submit(Emitter<AccountFormState> emit) async {
    // Guards double submission: a second tap while the first save is in flight
    // is dropped rather than creating two accounts.
    if (state.isBusy) return;

    final AccountFormErrors errors = validate(state);
    if (errors.hasAny) {
      emit(state.copyWith(errors: errors, showErrors: true));
      return;
    }

    emit(
      state.copyWith(
        status: AccountFormStatus.submitting,
        showErrors: true,
        errors: errors,
        clearFailure: true,
      ),
    );

    final AccountDraft draft = AccountDraft(
      name: state.name.trim(),
      // Safe: `validate` has already rejected an unparseable balance.
      balance: parseAmount(state.balanceInput)!,
    );

    final result = state.mode == AccountFormMode.add
        ? await _repo.createAccount(draft)
        : await _repo.updateAccount(state.id!, draft);

    result.fold(
      (failure) => emit(
        state.copyWith(status: AccountFormStatus.failure, failure: failure),
      ),
      (saved) => emit(
        state.copyWith(status: AccountFormStatus.success, saved: saved),
      ),
    );
  }

  Future<void> _delete(Emitter<AccountFormState> emit) async {
    if (state.isBusy) return;

    // Add mode has nothing to delete. Guarding here rather than only hiding the
    // button means a stray event cannot fire a request with a null id.
    final int? id = state.id;
    if (id == null) return;

    emit(
      state.copyWith(status: AccountFormStatus.deleting, clearFailure: true),
    );

    final result = await _repo.deleteAccount(id);

    result.fold(
      (failure) => emit(
        state.copyWith(status: AccountFormStatus.failure, failure: failure),
      ),
      // Deliberately a distinct terminal status, not `success`: the screen pops
      // with a different result so the list knows a row disappeared rather than
      // changed.
      (_) => emit(state.copyWith(status: AccountFormStatus.deleted)),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation. Returns localisation KEYS, not translated strings, so the bloc
  // stays free of easy_localization and the widget owns presentation.
  // ---------------------------------------------------------------------------

  static AccountFormErrors validate(AccountFormState state) {
    final String name = state.name.trim();
    String? nameError;
    if (name.isEmpty) {
      nameError = 'accounts.error_name_required';
    } else if (name.length > maxNameLength) {
      // Backend rule: `max:100`.
      nameError = 'accounts.error_name_too_long';
    }

    // Backend rule: `required|numeric` — with no `min`. A negative balance is
    // valid and meaningful: it is what an overdrawn credit card looks like, and
    // the design draws exactly that case in red.
    final String? balanceError = parseAmount(state.balanceInput) == null
        ? 'accounts.error_balance_required'
        : null;

    return AccountFormErrors(name: nameError, balance: balanceError);
  }

  /// Backend rule: `max:100`.
  static const int maxNameLength = 100;

  /// Parses the balance field. Returns null when nothing usable was typed.
  ///
  /// A lone "-", a lone "." and a trailing "." are all mid-typing states, not
  /// numbers.
  static num? parseAmount(String input) {
    if (input.isEmpty || input == '-') return null;
    final String normalised = input.endsWith('.')
        ? input.substring(0, input.length - 1)
        : input;
    if (normalised.isEmpty || normalised == '-') return null;
    return num.tryParse(normalised);
  }

  // ---------------------------------------------------------------------------
  // Input shape. `accounts.balance` is DECIMAL(15,2): 15 total digits with 2
  // after the point leaves 13 before it — same as `transactions.amount`.
  // ---------------------------------------------------------------------------

  static const int maxIntegerDigits = 13;
  static const int maxDecimalDigits = 2;

  /// What the balance field accepts, keystroke by keystroke.
  ///
  /// Unlike the transaction and budget amount patterns, this one allows a
  /// leading "-": the column has no `min` and an overdrawn account is a real
  /// balance. The empty string matches, so the field can be cleared.
  ///
  /// Written as one interpolated string with `\\.` and `\\d`, so the decimal
  /// point is a literal `.` and not the any-character wildcard.
  static final RegExp balanceInputPattern = RegExp(
    '^-?\\d{0,$maxIntegerDigits}(\\.\\d{0,$maxDecimalDigits})?\$',
  );

  /// Renders an existing balance back into the field for Edit.
  ///
  /// Trailing ".00" is dropped so a whole amount opens as "1250", not
  /// "1250.00", which is what the user would have typed.
  static String amountToInput(num? amount) {
    if (amount == null) return '';
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount
        .toStringAsFixed(maxDecimalDigits)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
