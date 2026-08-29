import 'package:dartz/dartz.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/network/failure.dart';

/// What the dashboard needs, independent of where the data comes from.
///
/// `DashboardRepo` in `data/repos/` implements it — today against the local
/// mock source, later against the API — so swapping the source never touches
/// the bloc or the widgets.
abstract class DashboardDomain {
  /// Loads the balance, the period totals, the category breakdown and the
  /// recent-transactions list in one call.
  Future<Either<Failure, DashboardData>> getDashboard();
}
