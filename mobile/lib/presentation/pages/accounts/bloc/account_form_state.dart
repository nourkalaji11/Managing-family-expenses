part of 'account_form_bloc.dart';

/// Which flow the form is serving. The only structural difference between Add
/// and Edit.
enum AccountFormMode { add, edit }

enum AccountFormStatus {
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
class AccountFormErrors extends Equatable {
  final String? name;
  final String? balance;

  const AccountFormErrors({this.name, this.balance});

  bool get hasAny => name != null || balance != null;

  @override
  List<Object?> get props => <Object?>[name, balance];
}

class AccountFormState extends Equatable {
  final AccountFormMode mode;

  /// The account being edited. Null in Add mode.
  final int? id;

  final String name;

  /// The raw text of the balance field, e.g. "-4800.5". Not a parsed number,
  /// because the field has to show exactly what was typed while typing.
  final String balanceInput;

  /// Transactions the edited account carries. Zero in Add mode.
  final int transactionCount;

  final AccountFormStatus status;

  /// Errors are computed on every change but only rendered after the first
  /// submit attempt, so an untouched form is not covered in red.
  final bool showErrors;
  final AccountFormErrors errors;

  /// Set when a save or delete fails, so the screen can surface the
  /// repository's message — including the server's 409 text, which names the
  /// exact number of transactions blocking the delete.
  final Failure? failure;

  /// Set when a save succeeds. The screen pops after this.
  final Account? saved;

  const AccountFormState({
    required this.mode,
    required this.errors,
    this.id,
    this.name = '',
    this.balanceInput = '',
    this.transactionCount = 0,
    this.status = AccountFormStatus.editing,
    this.showErrors = false,
    this.failure,
    this.saved,
  });

  /// Placeholder until `OnAccountFormStarted` arrives. `add` is the safe
  /// default: it carries no id, so nothing can be overwritten by mistake.
  factory AccountFormState.initial() => const AccountFormState(
    mode: AccountFormMode.add,
    balanceInput: '0',
    errors: AccountFormErrors(),
  );

  bool get isSubmitting => status == AccountFormStatus.submitting;

  bool get isDeleting => status == AccountFormStatus.deleting;

  /// True while either write is in flight. Both buttons disable together, so a
  /// delete cannot race a save.
  bool get isBusy => isSubmitting || isDeleting;

  bool get isEditing => mode == AccountFormMode.edit;

  /// True when the server will refuse a delete because the account still holds
  /// transactions. The screen uses it to explain up front rather than after.
  bool get hasTransactions => transactionCount > 0;

  /// The parsed balance, or null when nothing usable has been typed. Drives the
  /// live preview as well as validation.
  num? get balance => AccountFormBloc.parseAmount(balanceInput);

  AccountFormState copyWith({
    AccountFormMode? mode,
    int? id,
    String? name,
    String? balanceInput,
    int? transactionCount,
    AccountFormStatus? status,
    bool? showErrors,
    AccountFormErrors? errors,
    Failure? failure,
    Account? saved,

    /// Explicitly drops a previous failure. Needed because `failure: null` in a
    /// `??`-based copyWith means "keep the old one".
    bool clearFailure = false,
  }) => AccountFormState(
    mode: mode ?? this.mode,
    id: id ?? this.id,
    name: name ?? this.name,
    balanceInput: balanceInput ?? this.balanceInput,
    transactionCount: transactionCount ?? this.transactionCount,
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
    balanceInput,
    transactionCount,
    status,
    showErrors,
    errors,
    failure?.message,
    saved?.id,
  ];
}
