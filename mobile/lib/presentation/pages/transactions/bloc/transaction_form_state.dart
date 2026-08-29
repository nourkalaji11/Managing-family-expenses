part of 'transaction_form_bloc.dart';

/// Which flow the form is serving. The only structural difference between Add
/// and Edit.
enum TransactionFormMode { add, edit }

enum TransactionFormStatus {
  editing,
  submitting,
  deleting,
  success,
  deleted,
  failure,
}

/// One localisation KEY per field, or null when the field is valid.
///
/// Keys rather than translated strings, so the bloc never imports
/// easy_localization and the widget decides how to render them.
class TransactionFormErrors extends Equatable {
  final String? amount;
  final String? account;
  final String? category;
  final String? date;
  final String? description;

  const TransactionFormErrors({
    this.amount,
    this.account,
    this.category,
    this.date,
    this.description,
  });

  bool get hasAny =>
      amount != null ||
      account != null ||
      category != null ||
      date != null ||
      description != null;

  @override
  List<Object?> get props => <Object?>[
    amount,
    account,
    category,
    date,
    description,
  ];
}

class TransactionFormState extends Equatable {
  final TransactionFormMode mode;

  /// The row being edited. Null in Add mode. Preserved untouched so the repo
  /// replaces in place instead of appending a duplicate.
  final int? id;

  /// The raw keypad buffer, e.g. "240.5". Not a parsed number, because the
  /// display has to show exactly what was typed while typing.
  final String amountInput;

  final TransactionType type;
  final int? accountId;
  final int? categoryId;
  final DateTime date;
  final String description;

  /// Picker options, handed down from the list screen's loaded state.
  final List<Account> accounts;
  final List<Category> categories;

  final TransactionFormStatus status;

  /// Errors are computed on every change but only rendered after the first
  /// submit attempt, so an untouched form is not covered in red.
  final bool showErrors;
  final TransactionFormErrors errors;

  /// Set when a save fails, so the screen can surface the repository's message.
  final Failure? failure;

  /// Set when a save succeeds. The screen pops with this row.
  final TransactionModel? saved;

  const TransactionFormState({
    required this.mode,
    required this.date,
    required this.errors,
    this.id,
    this.amountInput = '',
    this.type = TransactionType.expense,
    this.accountId,
    this.categoryId,
    this.description = '',
    this.accounts = const <Account>[],
    this.categories = const <Category>[],
    this.status = TransactionFormStatus.editing,
    this.showErrors = false,
    this.failure,
    this.saved,
  });

  /// Placeholder until `OnFormStarted` arrives. `add` is the safe default: it
  /// carries no id, so nothing can be overwritten by mistake.
  factory TransactionFormState.initial() {
    final DateTime now = DateTime.now();
    return TransactionFormState(
      mode: TransactionFormMode.add,
      date: DateTime(now.year, now.month, now.day),
      errors: const TransactionFormErrors(),
    );
  }

  bool get isSubmitting => status == TransactionFormStatus.submitting;

  bool get isDeleting => status == TransactionFormStatus.deleting;

  /// True while either write is in flight, so a delete cannot race a save.
  /// Same contract as `AccountFormState.isBusy`.
  bool get isBusy => isSubmitting || isDeleting;

  bool get isEditing => mode == TransactionFormMode.edit;

  /// The currently selected account, or null when the id matches nothing.
  Account? get selectedAccount {
    final int? id = accountId;
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? get selectedCategory {
    final int? id = categoryId;
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  TransactionFormState copyWith({
    TransactionFormMode? mode,
    int? id,
    String? amountInput,
    TransactionType? type,
    int? accountId,
    int? categoryId,
    DateTime? date,
    String? description,
    List<Account>? accounts,
    List<Category>? categories,
    TransactionFormStatus? status,
    bool? showErrors,
    TransactionFormErrors? errors,
    Failure? failure,
    TransactionModel? saved,
    /// Explicitly drops a previous failure. Needed because `failure: null` in a
    /// `??`-based copyWith means "keep the old one".
    bool clearFailure = false,
  }) => TransactionFormState(
    mode: mode ?? this.mode,
    id: id ?? this.id,
    amountInput: amountInput ?? this.amountInput,
    type: type ?? this.type,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    date: date ?? this.date,
    description: description ?? this.description,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
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
    amountInput,
    type,
    accountId,
    categoryId,
    date,
    description,
    accounts,
    categories,
    status,
    showErrors,
    errors,
    failure?.message,
    saved?.id,
  ];
}
