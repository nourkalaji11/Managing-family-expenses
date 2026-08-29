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

  /// True while a child's account is being created, so the form can show
  /// progress and refuse a second submission.
  final bool isAddingMember;

  /// Id of the child added most recently, so the screen can confirm and the
  /// form can close.
  final int? lastAddedMemberId;

  const FamilyLoaded({
    required this.members,
    required this.canManage,
    this.savingMemberId,
    this.lastSavedMemberId,
    this.writeFailure,
    this.isRefreshing = false,
    this.isAddingMember = false,
    this.lastAddedMemberId,
  });

  bool get isEmpty => members.isEmpty;

  /// The share of [member]'s ceiling already spent, 0..1, or null when they
  /// have no ceiling to be a share of.
  ///
  /// Clamped at 1: a bar cannot draw past full, and the overspend is reported
  /// by the figures beneath it rather than by an impossible bar.
  static double? usageOf(User member) {
    final limit = member.spendingLimit;
    if (limit == null || limit <= 0) return null;

    final ratio = (member.spent ?? 0) / limit;
    if (ratio.isNaN) return null;
    return ratio < 0 ? 0 : (ratio > 1 ? 1 : ratio.toDouble());
  }

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
    bool? isAddingMember,
    int? lastAddedMemberId,

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
    isAddingMember: isAddingMember ?? this.isAddingMember,
    lastAddedMemberId: lastAddedMemberId ?? this.lastAddedMemberId,
  );

  @override
  List<Object?> get props => <Object?>[
    // Ceilings and spend both change in place, so the ids alone would not
    // distinguish two states after a save or after a child records an expense.
    [
      for (final m in members)
        '${m.id}:${m.name}:${m.spendingLimit}:${m.spent}',
    ],
    canManage,
    savingMemberId,
    lastSavedMemberId,
    writeFailure?.message,
    isRefreshing,
    isAddingMember,
    lastAddedMemberId,
  ];
}

class FamilyFailure extends FamilyState {
  final Failure error;

  const FamilyFailure(this.error);

  @override
  List<Object?> get props => <Object?>[error.message];
}
