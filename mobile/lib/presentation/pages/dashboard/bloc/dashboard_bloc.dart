import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/data/repos/dashboard_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/dashboard/domain/dashboard_domain.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Owns the data of the dashboard **home tab**.
///
/// Not to be confused with `DashboardCubit`, which owns only the selected
/// bottom-navigation tab index for the shell in `presentation/dashboard.dart`.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  /// The abstract contract from `domain/dashboard_domain.dart`. Injectable so
  /// tests can supply a fake without touching the mock source or GetIt.
  final DashboardDomain _repo;

  DashboardBloc({DashboardDomain? repo})
    : _repo = repo ?? DashboardRepo(),
      super(const DashboardInitial()) {
    on<DashboardEvent>((event, emit) async {
      if (event is OnLoadDashboard) {
        emit(const DashboardLoading());
        await _load(emit);
      } else if (event is OnRefreshDashboard) {
        // Keep the current content visible while refreshing instead of
        // dropping back to a full-screen loader.
        final current = state;
        if (current is DashboardLoaded) {
          emit(current.copyWith(isRefreshing: true));
        }
        await _load(emit);
      }
    });
  }

  Future<void> _load(Emitter<DashboardState> emit) async {
    final result = await _repo.getDashboard();
    result.fold(
      (failure) => emit(DashboardFailure(failure)),
      (data) => emit(DashboardLoaded(data)),
    );
  }
}
