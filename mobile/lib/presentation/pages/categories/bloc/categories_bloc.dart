import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/categories_data.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/repos/categories_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/categories/domain/categories_domain.dart';

part 'categories_event.dart';
part 'categories_state.dart';

/// Owns the categories grid: loading and the search query.
///
/// All derivation happens here, never in a widget. Mirrors `AccountsBloc`
/// exactly, minus the header total — categories carry no amount of their own.
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesDomain _repo;

  CategoriesBloc({CategoriesDomain? repo})
    : _repo = repo ?? CategoriesRepo(),
      super(const CategoriesInitial()) {
    on<CategoriesEvent>((event, emit) async {
      if (event is OnLoadCategories) {
        emit(const CategoriesLoading());
        await _load(emit);
      } else if (event is OnRefreshCategories) {
        final current = state;
        if (current is CategoriesLoaded) {
          emit(current.copyWith(isRefreshing: true));
        }
        await _load(emit);
      } else if (event is OnCategoriesQueryChanged) {
        _reproject(emit, query: event.query);
      }
    });
  }

  Future<void> _load(Emitter<CategoriesState> emit) async {
    // The query survives a refresh, same as in `AccountsBloc`.
    final CategoriesState current = state;
    final String query = current is CategoriesLoaded ? current.query : '';

    final result = await _repo.getCategories();
    result.fold((failure) => emit(CategoriesFailure(failure)), (data) {
      emit(
        CategoriesLoaded(
          data: data,
          query: query,
          visible: matching(data.categories, query),
        ),
      );
    });
  }

  void _reproject(Emitter<CategoriesState> emit, {required String query}) {
    final CategoriesState current = state;
    if (current is! CategoriesLoaded) return;

    emit(
      current.copyWith(
        query: query,
        visible: matching(current.data.categories, query),
      ),
    );
  }

  /// The categories whose name contains [query], case-insensitively.
  ///
  /// Only `name` is searched: it is the one text column the table has.
  static List<Category> matching(List<Category> source, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return List<Category>.unmodifiable(source);

    return List<Category>.unmodifiable([
      for (final c in source)
        if ((c.name ?? '').toLowerCase().contains(needle)) c,
    ]);
  }
}
