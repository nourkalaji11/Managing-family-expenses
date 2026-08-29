part of 'transfer_bloc.dart';

enum TransferStatus {
  loading,
  loadFailure,
  editing,
  submitting,
  success,
  failure,
}

/// One localisation KEY per field, or null when the field is valid.
class TransferErrors extends Equatable {
  final String? fromAccount;
  final String? toAccount;
  final String? amount;
  final String? category;

  const TransferErrors({
    this.fromAccount,
    this.toAccount,
    this.amount,
    this.category,
  });

  bool get hasAny =>
      fromAccount != null ||
      toAccount != null ||
      amount != null ||
      category != null;

  @override
  List<Object?> get props => <Object?>[fromAccount, toAccount, amount, category];
}

class TransferState extends Equatable {
  final TransferStatus status;

  /// Picker options, fetched by this bloc — see `OnTransferFormStarted`.
  final List<Account> accounts;
  final List<Category> categories;

  final int? fromAccountId;
  final int? toAccountId;
  final int? categoryId;

  /// The raw text of the amount field. Not a parsed number, because the field
  /// has to show exactly what was typed while typing.
  final String amountInput;

  final String description;
  final DateTime date;

  final bool showErrors;
  final TransferErrors errors;

  final Failure? failure;
  final TransferModel? saved;

  const TransferState({
    required this.date,
    required this.errors,
    this.status = TransferStatus.loading,
    this.accounts = const <Account>[],
    this.categories = const <Category>[],
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.amountInput = '',
    this.description = '',
    this.showErrors = false,
    this.failure,
    this.saved,
  });

  /// Placeholder until the options load. The date defaults to today, which is
  /// what a transfer almost always is.
  TransferState.initial()
    : status = TransferStatus.loading,
      accounts = const <Account>[],
      categories = const <Category>[],
      fromAccountId = null,
      toAccountId = null,
      categoryId = null,
      amountInput = '',
      description = '',
      date = _today(),
      showErrors = false,
      errors = const TransferErrors(),
      failure = null,
      saved = null;

  static DateTime _today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isLoading => status == TransferStatus.loading;

  bool get isSubmitting => status == TransferStatus.submitting;

  /// True when the family has fewer than two accounts, so a transfer is
  /// impossible. The screen shows an explanation instead of a form nobody can
  /// complete.
  bool get hasTooFewAccounts =>
      status != TransferStatus.loading && accounts.length < 2;

  Account? get fromAccount => _accountById(fromAccountId);

  Account? get toAccount => _accountById(toAccountId);

  Category? get category {
    final int? id = categoryId;
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The parsed amount, or null when nothing usable has been typed. Drives the
  /// live preview as well as validation.
  num? get amount => TransferBloc.parseAmount(amountInput);

  /// What the source account's balance becomes if this goes through.
  ///
  /// Shown as a preview so the user sees the consequence before committing —
  /// especially useful when it pushes an account negative, which the app
  /// permits and the server allows.
  num? get projectedFromBalance {
    final Account? from = fromAccount;
    final num? value = amount;
    if (from == null || value == null) return null;
    return (from.balance ?? 0) - value;
  }

  num? get projectedToBalance {
    final Account? to = toAccount;
    final num? value = amount;
    if (to == null || value == null) return null;
    return (to.balance ?? 0) + value;
  }

  Account? _accountById(int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  TransferState copyWith({
    TransferStatus? status,
    List<Account>? accounts,
    List<Category>? categories,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    String? amountInput,
    String? description,
    DateTime? date,
    bool? showErrors,
    TransferErrors? errors,
    Failure? failure,
    TransferModel? saved,

    /// Explicit clears, because `null` in a `??`-based copyWith means "keep".
    /// The swap action needs them: swapping into an unset slot must actually
    /// unset it.
    bool clearFrom = false,
    bool clearTo = false,
    bool clearFailure = false,
  }) => TransferState(
    status: status ?? this.status,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    fromAccountId: clearFrom ? null : (fromAccountId ?? this.fromAccountId),
    toAccountId: clearTo ? null : (toAccountId ?? this.toAccountId),
    categoryId: categoryId ?? this.categoryId,
    amountInput: amountInput ?? this.amountInput,
    description: description ?? this.description,
    date: date ?? this.date,
    showErrors: showErrors ?? this.showErrors,
    errors: errors ?? this.errors,
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    accounts.length,
    categories.length,
    fromAccountId,
    toAccountId,
    categoryId,
    amountInput,
    description,
    date,
    showErrors,
    errors,
    failure?.message,
    saved?.groupId,
  ];
}
