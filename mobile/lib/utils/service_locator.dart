import 'package:get_it/get_it.dart';
import 'package:family_expense_management/blocs/local_user_cubit.dart';
import 'package:family_expense_management/blocs/locale_cubit.dart';
import 'package:family_expense_management/blocs/password_cubit.dart';
import 'package:family_expense_management/blocs/toggle_cubit.dart';
import 'package:family_expense_management/presentation/pages/auth/bloc/auth_bloc.dart';
import 'package:family_expense_management/presentation/pages/dashboard/bloc/dashboard_bloc.dart';
import 'package:family_expense_management/presentation/pages/dashboard/bloc/dashboard_cubit.dart';
import 'package:family_expense_management/presentation/pages/notifications/bloc/notifications_bloc.dart';
import 'package:family_expense_management/presentation/pages/transactions/bloc/transaction_form_bloc.dart';
import 'package:family_expense_management/presentation/pages/transactions/bloc/transactions_bloc.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<LocaleCubit>(
    () => LocaleCubit(),
    dispose: (param) {
      return false;
    },
  );
  getIt.registerLazySingleton<LocalUserCubit>(
    () => LocalUserCubit(),
    dispose: (param) {
      return false;
    },
  );

  getIt.registerFactory<ToggleCubit>(() => ToggleCubit());
  // A factory (not a singleton) so every password field owns its own
  // visibility state instead of sharing one global toggle.
  getIt.registerFactory<PasswordCubit>(() => PasswordCubit());
  getIt.registerFactory<DashboardCubit>(() => DashboardCubit());
  // Owns the home tab's data. Separate from DashboardCubit, which owns only the
  // selected bottom-navigation tab index.
  getIt.registerFactory<DashboardBloc>(() => DashboardBloc());
  getIt.registerFactory<AuthBloc>(() => AuthBloc());
  getIt.registerFactory<NotificationsBloc>(() => NotificationsBloc());

  // Transactions. Factories, not singletons: the list bloc is owned by the
  // transactions tab and the form bloc by each pushed form, so every instance
  // must be fresh. The screens currently construct their own, exactly as
  // `HomeScreen` does with `DashboardBloc`; these registrations keep the
  // container complete and give tests an injection point.
  getIt.registerFactory<TransactionsBloc>(() => TransactionsBloc());
  getIt.registerFactory<TransactionFormBloc>(() => TransactionFormBloc());
}
