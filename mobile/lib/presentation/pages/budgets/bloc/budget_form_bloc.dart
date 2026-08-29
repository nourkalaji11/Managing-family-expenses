import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/budget.dart';
import 'package:family_expense_management/data/models/budgets_data.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/repos/budgets_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/budgets/domain/budgets_domain.dart';

part 'budget_form_event.dart';
part 'budget_form_state.dart';

/// Drives both Add and Edit.
///
/// The two differ only in what seeds the state and which repository method runs
/// on submit, so there is one bloc and one form rather than two near-identical
/// copies. [BudgetFormState.mode] is the only branch.
///
/// Validation lives here, not in the widgets. The rules mirror what the schema
/// and `BudgetController::store` require on `origin/souad-backend`, plus one the
/// UI owns: the period may not end before it starts.
///
/// There is deliberately **no** "this category already has a budget" rule. See
/// `BudgetModel.overlapsRange` — nothing on the backend defines one, and the two
/// hints that exist contradict each other, so inventing a restriction here would
/// block writes the server would happily accept.
class BudgetFormBloc extends Bloc<BudgetFormEvent, BudgetFormState> {
  final BudgetsDomain _repo;

  BudgetFormBloc({BudgetsDomain? repo})
    : _repo = repo ?? BudgetsRepo(),
      super(BudgetFormState.initial()) {
    on<BudgetFormEvent>((
      BudgetFormEvent event,
      Emitter<BudgetFormState> emit,
    ) async {
      if (event is OnBudgetFormStarted) {
        final BudgetFormState seeded = _seed(event);
        emit(seeded);

        // The budgets list hands its already-loaded categories down, so this
        // usually does nothing. It matters when the form is opened from
        // somewhere with nothing to give — a route pushed without arguments.
        if (seeded.categories.isEmpty) {
          await _loadOptions(emit);
        }
      } else if (event is OnBudgetCategoryChanged) {
        emit(_revalidated(state.copyWith(categoryId: event.categoryId)));
      } else if (event is OnBudgetLimitChanged) {
        emit(_revalidated(state.copyWith(limitInput: event.limitInput)));
      } else if (event is OnBudgetStartDateChanged) {
        emit(_revalidated(state.copyWith(startDate: _atMidnight(event.date))));
      } else if (event is OnBudgetEndDateChanged) {
        emit(_revalidated(state.copyWith(endDate: _atMidnight(event.date))));
      } else if (event is OnSubmitBudgetForm) {
        await _submit(emit);
      } else if (event is OnDeleteBudget) {
        await _delete(emit);
      }
    });
  }

  BudgetFormState _seed(OnBudgetFormStarted event) {
    final BudgetModel? existing = event.budget;

    if (existing == null) {
      // Add defaults to the whole of the month the list was showing. Both
      // columns are NOT NULL, so the form has to start somewhere, and a full
      // calendar month is the only period the design's own copy implies
      // ("ميزانية ... للشهر الحالي").
      final DateTime month = event.month ?? DateTime.now();
      return BudgetFormState(
        mode: BudgetFormMode.add,
        categories: event.categories,
        categoryId: null,
        startDate: DateTime(month.year, month.month, 1),
        endDate: DateTime(month.year, month.month + 1, 0),
        errors: const BudgetFormErrors(),
      );
    }

    final DateTime fallback = DateTime.now();
    return BudgetFormState(
      mode: BudgetFormMode.edit,
      // Preserved verbatim through the whole edit and handed back to the repo,
      // which uses it to replace in place rather than append.
      id: existing.id,
      categories: event.categories,
      categoryId: existing.categoryId ?? existing.category?.id,
      limitInput: amountToInput(existing.limitAmount),
      startDate:
          existing.startDate ?? DateTime(fallback.year, fallback.month, 1),
      endDate:
          existing.endDate ?? DateTime(fallback.year, fallback.month + 1, 0),
      errors: const BudgetFormErrors(),
    );
  }

  /// Fetches the category options through the same domain contract the list
  /// uses, so there is one source for them.
  Future<void> _loadOptions(Emitter<BudgetFormState> emit) async {
    final result = await _repo.getBudgets();
    result.fold(
      (failure) => emit(
        state.copyWith(status: BudgetFormStatus.failure, failure: failure),
      ),
      (data) => emit(state.copyWith(categories: data.categories)),
    );
  }

  /// Recomputes the error set after any field change.
  ///
  /// Errors are always computed but only *rendered* once
  /// [BudgetFormState.showErrors] is set by a submit attempt, so the form does
  /// not shout at the user before they have filled anything in.
  BudgetFormState _revalidated(BudgetFormState next) =>
      next.copyWith(errors: validate(next), status: BudgetFormStatus.editing);

  Future<void> _submit(Emitter<BudgetFormState> emit) async {
    // Guards double submission: a second tap while either write is in flight is
    // dropped rather than creating two rows.
    if (state.isBusy) return;

    final BudgetFormErrors errors = validate(state);
    if (errors.hasAny) {
      emit(state.copyWith(errors: errors, showErrors: true));
      return;
    }

    emit(
      state.copyWith(
        status: BudgetFormStatus.submitting,
        showErrors: true,
        errors: errors,
        clearFailure: true,
      ),
    );

    final BudgetDraft draft = BudgetDraft(
      // Safe: `validate` has already rejected a null category and a null or
      // non-positive amount.
      categoryId: state.categoryId!,
      limitAmount: parseAmount(state.limitInput)!,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    final result = state.mode == BudgetFormMode.add
        ? await _repo.createBudget(draft)
        : await _repo.updateBudget(state.id!, draft);

    result.fold(
      (failure) => emit(
        state.copyWith(status: BudgetFormStatus.failure, failure: failure),
      ),
      (saved) =>
          emit(state.copyWith(status: BudgetFormStatus.success, saved: saved)),
    );
  }

  Future<void> _delete(Emitter<BudgetFormState> emit) async {
    // Nothing to delete in Add mode, and a delete must not race a save.
    if (state.isBusy || state.mode != BudgetFormMode.edit) return;

    final int? id = state.id;
    if (id == null) return;

    emit(state.copyWith(status: BudgetFormStatus.deleting, clearFailure: true));

    final result = await _repo.deleteBudget(id);

    result.fold(
      (failure) => emit(
        state.copyWith(status: BudgetFormStatus.failure, failure: failure),
      ),
      (_) =>
          emit(state.copyWith(status: BudgetFormStatus.deleted, deletedId: id)),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation. Returns localisation KEYS, not translated strings, so the bloc
  // stays free of easy_localization and the widget owns presentation.
  // ---------------------------------------------------------------------------

  static BudgetFormErrors validate(BudgetFormState state) {
    // Backend rule: `required|exists:categories,id`.
    final String? categoryError = state.categoryId == null
        ? 'budgets.error_category_required'
        : null;

    final num? amount = parseAmount(state.limitInput);
    String? amountError;
    if (amount == null) {
      amountError = 'budgets.error_limit_required';
    } else if (amount <= 0) {
      // Backend rule: `numeric|min:0.01`.
      amountError = 'budgets.error_limit_positive';
    }

    // Neither date can be null in this state, so the only failure mode is an
    // inverted period — a UI rule, since the schema only requires two dates and
    // the controller validates neither.
    final String? endError =
        _atMidnight(state.endDate).isBefore(_atMidnight(state.startDate))
        ? 'budgets.error_end_before_start'
        : null;

    return BudgetFormErrors(
      category: categoryError,
      limitAmount: amountError,
      endDate: endError,
    );
  }

  /// Parses the limit field. Returns null when nothing usable was typed.
  static num? parseAmount(String input) {
    if (input.isEmpty) return null;
    // A lone "." or a trailing "." is mid-typing, not a number. The pattern is
    // anchored to a literal decimal point, not the any-character wildcard.
    final String normalised = input.endsWith('.')
        ? input.substring(0, input.length - 1)
        : input;
    if (normalised.isEmpty) return null;
    return num.tryParse(normalised);
  }

  // ---------------------------------------------------------------------------
  // Input shape. `budgets.limit_amount` is DECIMAL(15,2), exactly like
  // `transactions.amount`: 15 total digits with 2 after the point leaves 13
  // before it.
  // ---------------------------------------------------------------------------

  static const int maxIntegerDigits = 13;
  static const int maxDecimalDigits = 2;

  /// What the limit field accepts, keystroke by keystroke.
  ///
  /// Lives here rather than in the widget because it encodes a schema rule, not
  /// a layout one. The empty string matches, so the field can be cleared.
  ///
  /// Written as one interpolated string with `\\.` and `\\d`, so the decimal
  /// point is a literal `.` and not the any-character wildcard.
  static final RegExp limitInputPattern = RegExp(
    '^\\d{0,$maxIntegerDigits}(\\.\\d{0,$maxDecimalDigits})?\$',
  );

  /// Renders an existing amount back into the field for Edit.
  ///
  /// Trailing ".00" is dropped so a whole amount opens as "1500", not
  /// "1500.00", which is what the user would have typed. Both patterns are
  /// escaped: `\.` is a literal decimal point.
  static String amountToInput(num? amount) {
    if (amount == null) return '';
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount
        .toStringAsFixed(maxDecimalDigits)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static DateTime _atMidnight(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
