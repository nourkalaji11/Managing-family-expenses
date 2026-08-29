part of 'category_form_bloc.dart';

/// Which flow the form is serving.
enum CategoryFormMode { add, edit }

enum CategoryFormStatus {
  editing,
  submitting,
  deleting,
  success,
  deleted,
  failure,
}

/// One localisation KEY, or null when the field is valid.
class CategoryFormErrors extends Equatable {
  final String? name;

  const CategoryFormErrors({this.name});

  bool get hasAny => name != null;

  @override
  List<Object?> get props => <Object?>[name];
}

class CategoryFormState extends Equatable {
  final CategoryFormMode mode;

  /// The category being edited. Null in Add mode.
  final int? id;

  final String name;

  /// Transactions plus budgets referencing the edited category. Zero in Add
  /// mode.
  final int usageCount;

  final CategoryFormStatus status;

  /// Errors are computed on every change but only rendered after the first
  /// submit attempt.
  final bool showErrors;
  final CategoryFormErrors errors;

  /// Set when a save or delete fails. Carries the server's message for the two
  /// cases only it can decide: a duplicate name (422) and a category still in
  /// use (409).
  final Failure? failure;

  /// Set when a save succeeds. The screen pops after this.
  final Category? saved;

  const CategoryFormState({
    required this.mode,
    required this.errors,
    this.id,
    this.name = '',
    this.usageCount = 0,
    this.status = CategoryFormStatus.editing,
    this.showErrors = false,
    this.failure,
    this.saved,
  });

  /// Placeholder until `OnCategoryFormStarted` arrives. `add` is the safe
  /// default: it carries no id, so nothing can be overwritten by mistake.
  const CategoryFormState.initial()
    : mode = CategoryFormMode.add,
      id = null,
      name = '',
      usageCount = 0,
      status = CategoryFormStatus.editing,
      showErrors = false,
      errors = const CategoryFormErrors(),
      failure = null,
      saved = null;

  bool get isSubmitting => status == CategoryFormStatus.submitting;

  bool get isDeleting => status == CategoryFormStatus.deleting;

  /// True while either write is in flight, so a delete cannot race a save.
  bool get isBusy => isSubmitting || isDeleting;

  bool get isEditing => mode == CategoryFormMode.edit;

  /// True when the server will refuse a delete because something still
  /// references the category.
  bool get isInUse => usageCount > 0;

  /// The name as it will actually be sent and previewed.
  String get trimmedName => name.trim();

  CategoryFormState copyWith({
    CategoryFormMode? mode,
    int? id,
    String? name,
    int? usageCount,
    CategoryFormStatus? status,
    bool? showErrors,
    CategoryFormErrors? errors,
    Failure? failure,
    Category? saved,

    /// Explicitly drops a previous failure. Needed because `failure: null` in a
    /// `??`-based copyWith means "keep the old one".
    bool clearFailure = false,
  }) => CategoryFormState(
    mode: mode ?? this.mode,
    id: id ?? this.id,
    name: name ?? this.name,
    usageCount: usageCount ?? this.usageCount,
    status: status ?? this.status,
    showErrors: showErrors ?? this.showErrors,
    errors: errors ?? this.errors,
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => <Object?>[
    mode,
    id,
    name,
    usageCount,
    status,
    showErrors,
    errors,
    failure?.message,
    saved?.id,
  ];
}
