part of 'budget_form_bloc.dart';

/// Which flow the form is serving. The only structural difference between Add
/// and Edit.
enum BudgetFormMode { add, edit }

enum BudgetFormStatus {
  editing,
  submitting,

  /// A delete is in flight. Distinct from [submitting] so the screen can spin
  /// the trash button rather than the save button, and so one write in flight
  /// blocks the other.
  deleting,
  success,

  /// The row is gone. The screen pops with a different message from [success],
  /// and the list has to drop the row rather than replace it.
  deleted,
  failure,
}

/// One localisation KEY per field, or null when the field is valid.
///
/// Keys rather than translated strings, so the bloc never imports
/// easy_localization and the widget decides how to render them.
class BudgetFormErrors extends Equatable {
  final String? category;
  final String? limitAmount;
  final String? startDate;
  final String? endDate;

  const BudgetFormErrors({
    this.category,
    this.limitAmount,
    this.startDate,
    this.endDate,
  });

  bool get hasAny =>
      category != null ||
      limitAmount != null ||
      startDate != null ||
      endDate != null;

  @override
  List<Object?> get props => <Object?>[
    category,
    limitAmount,
    startDate,
    endDate,
  ];
}

class BudgetFormState extends Equatable {
  final BudgetFormMode mode;

  /// The budget being edited. Null in Add mode. Preserved untouched so the repo
  /// replaces in place instead of appending a duplicate.
  final int? id;

  final int? categoryId;

  /// The raw text of the limit field, e.g. "1500.5". Not a parsed number,
  /// because the field has to show exactly what was typed while typing.
  final String limitInput;

  final DateTime startDate;
  final DateTime endDate;

  /// Picker options, handed down from the list screen's loaded state.
  final List<Category> categories;

  final BudgetFormStatus status;

  /// Errors are computed on every change but only rendered after the first
  /// submit attempt, so an untouched form is not covered in red.
  final bool showErrors;
  final BudgetFormErrors errors;

  /// Set when a save fails, so the screen can surface the repository's message.
  final Failure? failure;

  /// Set when a save succeeds. The screen pops after this.
  final BudgetModel? saved;

  /// The id of the budget that was deleted, so the list can drop that row.
  /// Carried separately from [saved]: there is no row left to hand back.
  final int? deletedId;

  const BudgetFormState({
    required this.mode,
    required this.startDate,
    required this.endDate,
    required this.errors,
    this.id,
    this.categoryId,
    this.limitInput = '',
    this.categories = const <Category>[],
    this.status = BudgetFormStatus.editing,
    this.showErrors = false,
    this.failure,
    this.saved,
    this.deletedId,
  });

  /// Placeholder until `OnBudgetFormStarted` arrives. `add` is the safe default:
  /// it carries no id, so nothing can be overwritten by mistake.
  factory BudgetFormState.initial() {
    final DateTime now = DateTime.now();
    return BudgetFormState(
      mode: BudgetFormMode.add,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      errors: const BudgetFormErrors(),
    );
  }

  bool get isSubmitting => status == BudgetFormStatus.submitting;

  bool get isDeleting => status == BudgetFormStatus.deleting;

  /// True while either write is in flight, so a delete cannot race a save.
  bool get isBusy => isSubmitting || isDeleting;

  bool get isEditing => mode == BudgetFormMode.edit;

  /// The currently selected category, or null when the id matches nothing.
  Category? get selectedCategory {
    final int? id = categoryId;
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The parsed limit, or null when nothing usable has been typed. Drives the
  /// live preview card as well as validation.
  num? get limitAmount => BudgetFormBloc.parseAmount(limitInput);

  BudgetFormState copyWith({
    BudgetFormMode? mode,
    int? id,
    int? categoryId,
    String? limitInput,
    DateTime? startDate,
    DateTime? endDate,
    List<Category>? categories,
    BudgetFormStatus? status,
    bool? showErrors,
    BudgetFormErrors? errors,
    Failure? failure,
    BudgetModel? saved,
    int? deletedId,

    /// Explicitly drops a previous failure. Needed because `failure: null` in a
    /// `??`-based copyWith means "keep the old one".
    bool clearFailure = false,
  }) => BudgetFormState(
    mode: mode ?? this.mode,
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    limitInput: limitInput ?? this.limitInput,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    categories: categories ?? this.categories,
    status: status ?? this.status,
    showErrors: showErrors ?? this.showErrors,
    errors: errors ?? this.errors,
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
    deletedId: deletedId ?? this.deletedId,
  );

  @override
  List<Object?> get props => <Object?>[
    mode,
    id,
    categoryId,
    limitInput,
    startDate,
    endDate,
    categories,
    status,
    showErrors,
    errors,
    failure?.message,
    saved?.id,
    deletedId,
  ];
}
