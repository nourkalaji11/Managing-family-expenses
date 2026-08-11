part of 'dashboard_bloc.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;

  /// True while a refresh is in flight over already-visible content.
  final bool isRefreshing;

  const DashboardLoaded(this.data, {this.isRefreshing = false});

  DashboardLoaded copyWith({DashboardData? data, bool? isRefreshing}) =>
      DashboardLoaded(
        data ?? this.data,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );

  // `data` is not an Equatable value object, so identity plus the refresh flag
  // is what distinguishes two states here.
  @override
  List<Object?> get props => [data, isRefreshing];
}

class DashboardFailure extends DashboardState {
  final Failure error;

  const DashboardFailure(this.error);

  @override
  List<Object?> get props => [error.message];
}
