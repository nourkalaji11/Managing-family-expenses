part of 'family_bloc.dart';

sealed class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => <Object?>[];
}

class FamilyInitial extends FamilyState {
  const FamilyInitial();
}

class FamilyLoading extends FamilyState {
  const FamilyLoading();
}

class FamilyLoaded extends FamilyState {
  /// Exactly what the server returned. Never re-filtered here — see `FamilyBloc`.
  final List<User> members;

  /// Whether the signed-in user may edit ceilings. Decides what the screen
  /// *offers*; the server decides what actually goes through, and answers 403
  /// regardless of what this says.
  final bool canManage;

  /// Id of the member whose ceiling is being saved, or null when idle. Only one
  /// at a time.
  final int? savingMemberId;

  /// Id of the member whose ceiling was saved most recently, so the screen can
  /// confirm without a toast that outlives the row.
  final int? lastSavedMemberId;

  /// Set when a ceiling write fails — carries the server's message, which is
  /// the only side that can decide 403 (not a parent) or 422 (target is a
  /// parent).
  final Failure? writeFailure;

  final bool isRefreshing;

  const FamilyLoaded({
    required this.members,
    required this.canManage,
    this.savingMemberId,
    this.lastSavedMemberId,
    this.writeFailure,
    this.isRefreshing = false,
  });

  bool get isEmpty => members.isEmpty;

  /// Members who can actually carry a ceiling. A parent is not capped, and the
  /// server refuses to set one on them.
  List<User> get manageableMembers => [
    for (final m in members)
      if (!m.isParent) m,
  ];

  List<User> get parents => [
    for (final m in members)
      if (m.isParent) m,
  ];

  bool isSaving(int? id) => id != null && savingMemberId == id;

  FamilyLoaded copyWith({
    List<User>? members,
    bool? canManage,
    int? savingMemberId,
    int? lastSavedMemberId,
    Failure? writeFailure,
    bool? isRefreshing,

    /// Explicit clears, because `null` in a `??`-based copyWith means "keep".
    bool clearSavingMemberId = false,
    bool clearFailure = false,
  }) => FamilyLoaded(
    members: members ?? this.members,
    canManage: canManage ?? this.canManage,
    savingMemberId: clearSavingMemberId
        ? null
        : (savingMemberId ?? this.savingMemberId),
    lastSavedMemberId: lastSavedMemberId ?? this.lastSavedMemberId,
    writeFailure: clearFailure ? null : (writeFailure ?? this.writeFailure),
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => <Object?>[
    // Ceilings change in place, so the ids alone would not distinguish two
    // states after a successful save.
    [for (final m in members) '${m.id}:${m.name}:${m.spendingLimit}'],
    canManage,
    savingMemberId,
    lastSavedMemberId,
    writeFailure?.message,
    isRefreshing,
  ];
}

class FamilyFailure extends FamilyState {
  final Failure error;

  const FamilyFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
