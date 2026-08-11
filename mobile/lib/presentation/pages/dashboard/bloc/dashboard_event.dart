part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// First load. Shows the full-screen loader.
class OnLoadDashboard extends DashboardEvent {
  const OnLoadDashboard();
}

/// Pull-to-refresh. Keeps the current content on screen while reloading, so the
/// dashboard does not flash back to a loader.
class OnRefreshDashboard extends DashboardEvent {
  const OnRefreshDashboard();
}
