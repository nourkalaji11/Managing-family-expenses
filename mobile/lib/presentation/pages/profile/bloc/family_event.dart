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
class OnSetSpendingLimit extends FamilyEvent {
  final int userId;
  final num limit;

  const OnSetSpendingLimit({required this.userId, required this.limit});

  @override
  List<Object?> get props => <Object?>[userId, limit];
}
