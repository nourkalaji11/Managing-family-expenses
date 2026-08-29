part of 'family_bloc.dart';

sealed class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load. Shows the full-screen loader.
class OnLoadFamily extends FamilyEvent {
  const OnLoadFamily();
}

/// Pull-to-refresh.
class OnRefreshFamily extends FamilyEvent {
  const OnRefreshFamily();
}

/// Sets one member's spending ceiling.
///
/// Ignored while another save is in flight, so two quick taps cannot race.
/// Creates a child's account. Parent-only; the server refuses otherwise
/// whatever the screen offers.
///
/// [spendingLimit] is optional: a parent may add the child first and decide the
/// allowance afterwards.
class OnAddFamilyMember extends FamilyEvent {
  final String name;
  final String email;
  final String password;
  final num? spendingLimit;

  const OnAddFamilyMember({
    required this.name,
    required this.email,
    required this.password,
    this.spendingLimit,
  });

  @override
  // The password is deliberately absent: `Equatable` props end up in
  // `toString()` and in bloc observers, and a credential must not.
  List<Object?> get props => <Object?>[name, email, spendingLimit];
}

class OnSetSpendingLimit extends FamilyEvent {
  final int userId;
  final num limit;

  const OnSetSpendingLimit({required this.userId, required this.limit});

  @override
  List<Object?> get props => <Object?>[userId, limit];
}
