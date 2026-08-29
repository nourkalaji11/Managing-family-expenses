import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/accounts_data.dart';
import 'package:family_expense_management/data/repos/accounts_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/accounts/domain/accounts_domain.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

/// Owns the accounts list: loading, the search query and the header total.
///
/// All derivation happens here, never in a widget — the screen renders
/// `AccountsLoaded.visible` and `AccountsLoaded.totalBalance` and nothing else.
/// Same arrangement as `BudgetsBloc`.
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  /// The abstract contract from `domain/accounts_domain.dart`. Injectable so
  /// tests can supply a fake without touching GetIt.
  final AccountsDomain _repo;

  AccountsBloc({AccountsDomain? repo})
    : _repo = repo ?? AccountsRepo(),
      super(const AccountsInitial()) {
    on<AccountsEvent>((event, emit) async {
      if (event is OnLoadAccounts) {
        emit(const AccountsLoading());
        await _load(emit);
      } else if (event is OnRefreshAccounts) {
        // Keep the current content visible while reloading instead of dropping
        // back to a full-screen loader.
        final current = state;
        if (current is AccountsLoaded) {
          emit(current.copyWith(isRefreshing: true));
        }
        await _load(emit);
      } else if (event is OnAccountsQueryChanged) {
        _reproject(emit, query: event.query);
      }
    });
  }

  Future<void> _load(Emitter<AccountsState> emit) async {
    // The query survives a refresh: reloading must not silently clear what the
    // user typed.
    final AccountsState current = state;
    final String query = current is AccountsLoaded ? current.query : '';

    final result = await _repo.getAccounts();
    result.fold((failure) => emit(AccountsFailure(failure)), (data) {
      emit(
        AccountsLoaded(
          data: data,
          query: query,
          visible: matching(data.accounts, query),
        ),
      );
    });
  }

  /// Re-filters after a query change, without hitting the repository again.
  void _reproject(Emitter<AccountsState> emit, {required String query}) {
    final AccountsState current = state;
    if (current is! AccountsLoaded) return;

    // Always rebuilt from the loaded data, so clearing the query restores the
    // full list rather than progressively narrowing it.
    emit(
      current.copyWith(
        query: query,
        visible: matching(current.data.accounts, query),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Projection. Static and pure, so it is directly testable and can never read
  // state it was not given.
  // ---------------------------------------------------------------------------

  /// The accounts whose name contains [query], case-insensitively.
  ///
  /// Only `name` is searched: it is the one text column the table has. Ordering
  /// is left exactly as the repository returned it.
  static List<Account> matching(List<Account> source, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return List<Account>.unmodifiable(source);

    return List<Account>.unmodifiable([
      for (final a in source)
        if ((a.name ?? '').toLowerCase().contains(needle)) a,
    ]);
  }
}
