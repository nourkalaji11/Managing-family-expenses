import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transfer_data.dart';
import 'package:family_expense_management/data/repos/transfers_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/transfers/domain/transfers_domain.dart';

part 'transfer_event.dart';
part 'transfer_state.dart';

/// Drives the transfer form.
///
/// Validation mirrors `TransferController::store`, including its `different`
/// rule — moving money from an account to itself is a no-op the server rejects,
/// and catching it here means the user finds out while the picker is still
/// open rather than after a round trip.
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final TransfersDomain _repo;

  TransferBloc({TransfersDomain? repo})
    : _repo = repo ?? TransfersRepo(),
      // Not `const`: the initial state defaults its date to today, which cannot
      // be evaluated at compile time.
      super(TransferState.initial()) {
    on<TransferEvent>((event, emit) async {
      if (event is OnTransferFormStarted) {
        emit(state.copyWith(status: TransferStatus.loading));
        await _loadOptions(emit);
      } else if (event is OnTransferFromChanged) {
        emit(_revalidated(state.copyWith(fromAccountId: event.accountId)));
      } else if (event is OnTransferToChanged) {
        emit(_revalidated(state.copyWith(toAccountId: event.accountId)));
      } else if (event is OnTransferSwapAccounts) {
        emit(
          _revalidated(
            state.copyWith(
              fromAccountId: state.toAccountId,
              toAccountId: state.fromAccountId,
              // Explicit clears, because a null id must actually move across
              // rather than being kept by the `??` in copyWith.
              clearFrom: state.toAccountId == null,
              clearTo: state.fromAccountId == null,
            ),
          ),
        );
      } else if (event is OnTransferCategoryChanged) {
        emit(_revalidated(state.copyWith(categoryId: event.categoryId)));
      } else if (event is OnTransferAmountChanged) {
        emit(_revalidated(state.copyWith(amountInput: event.amountInput)));
      } else if (event is OnTransferDescriptionChanged) {
        emit(_revalidated(state.copyWith(description: event.description)));
      } else if (event is OnTransferDateChanged) {
        emit(_revalidated(state.copyWith(date: _atMidnight(event.date))));
      } else if (event is OnSubmitTransfer) {
        await _submit(emit);
      }
    });
  }

  Future<void> _loadOptions(Emitter<TransferState> emit) async {
    final result = await _repo.getFormData();
    result.fold(
      (failure) => emit(
        state.copyWith(status: TransferStatus.loadFailure, failure: failure),
      ),
      (data) => emit(
        state.copyWith(
          status: TransferStatus.editing,
          accounts: data.accounts,
          categories: data.categories,
          // Sensible defaults so the common case is one tap: the first two
          // accounts, and the first category — which is filler anyway, since
          // `transactions.category_id` is NOT NULL and a transfer has no
          // natural category.
          fromAccountId: data.accounts.isNotEmpty ? data.accounts[0].id : null,
          toAccountId: data.accounts.length > 1 ? data.accounts[1].id : null,
          categoryId:
              data.categories.isNotEmpty ? data.categories.first.id : null,
        ),
      ),
    );
  }

  TransferState _revalidated(TransferState next) => next.copyWith(
    errors: validate(next),
    status: TransferStatus.editing,
    clearFailure: true,
  );

  Future<void> _submit(Emitter<TransferState> emit) async {
    if (state.isSubmitting) return;

    final TransferErrors errors = validate(state);
    if (errors.hasAny) {
      emit(state.copyWith(errors: errors, showErrors: true));
      return;
    }

    emit(
      state.copyWith(
        status: TransferStatus.submitting,
        showErrors: true,
        errors: errors,
        clearFailure: true,
      ),
    );

    final TransferDraft draft = TransferDraft(
      // Safe: `validate` has already rejected null ids and a non-positive
      // amount.
      fromAccountId: state.fromAccountId!,
      toAccountId: state.toAccountId!,
      amount: parseAmount(state.amountInput)!,
      categoryId: state.categoryId!,
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
      date: state.date,
    );

    final result = await _repo.createTransfer(draft);

    result.fold(
      (failure) => emit(
        state.copyWith(status: TransferStatus.failure, failure: failure),
      ),
      (saved) =>
          emit(state.copyWith(status: TransferStatus.success, saved: saved)),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation. Returns localisation KEYS, not translated strings.
  // ---------------------------------------------------------------------------

  static TransferErrors validate(TransferState state) {
    String? fromError;
    String? toError;

    if (state.fromAccountId == null) {
      fromError = 'transfers.error_from_required';
    }
    if (state.toAccountId == null) {
      toError = 'transfers.error_to_required';
    } else if (state.toAccountId == state.fromAccountId) {
      // Backend rule: `different:to_account_id`.
      toError = 'transfers.error_same_account';
    }

    final num? amount = parseAmount(state.amountInput);
    String? amountError;
    if (amount == null) {
      amountError = 'transactions.error_amount_required';
    } else if (amount <= 0) {
      // Backend rule: `numeric|min:0.01`.
      amountError = 'transactions.error_amount_positive';
    }

    // Deliberately **not** validated: whether the source account holds enough.
    // `accounts.balance` may legitimately be negative — that is what an
    // overdrawn credit card is — and the server imposes no such rule either.
    // Blocking here would invent a constraint the data model does not have.

    final String? categoryError = state.categoryId == null
        ? 'transactions.error_category_required'
        : null;

    return TransferErrors(
      fromAccount: fromError,
      toAccount: toError,
      amount: amountError,
      category: categoryError,
    );
  }

  /// Parses the amount field. Returns null when nothing usable was typed.
  static num? parseAmount(String input) {
    if (input.isEmpty) return null;
    final String normalised = input.endsWith('.')
        ? input.substring(0, input.length - 1)
        : input;
    if (normalised.isEmpty) return null;
    return num.tryParse(normalised);
  }

  /// `transactions.amount` is DECIMAL(15,2): 13 digits before the point, 2 after.
  static const int maxIntegerDigits = 13;
  static const int maxDecimalDigits = 2;

  /// What the amount field accepts, keystroke by keystroke. No leading minus:
  /// direction is expressed by which account is which, not by the sign.
  static final RegExp amountInputPattern = RegExp(
    '^\\d{0,$maxIntegerDigits}(\\.\\d{0,$maxDecimalDigits})?\$',
  );

  static DateTime _atMidnight(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
