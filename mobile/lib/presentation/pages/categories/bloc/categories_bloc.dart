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
      } else if (event is OnCategoryTypeChanged) {
        _reproject(emit, type: event.type);
      }
    });
  }

  Future<void> _load(Emitter<CategoriesState> emit) async {
    // The query survives a refresh, same as in `AccountsBloc`.
    final CategoriesState current = state;
    final String query = current is CategoriesLoaded ? current.query : '';
    final String type = current is CategoriesLoaded
        ? current.type
        : Category.typeExpense;

    final result = await _repo.getCategories();
    result.fold((failure) => emit(CategoriesFailure(failure)), (data) {
      emit(
        CategoriesLoaded(
          data: data,
          query: query,
          type: type,
          visible: matching(data.categories, query, type),
        ),
      );
    });
  }

  void _reproject(
    Emitter<CategoriesState> emit, {
    String? query,
    String? type,
  }) {
    final CategoriesState current = state;
    if (current is! CategoriesLoaded) return;

    final String nextQuery = query ?? current.query;
    final String nextType = type ?? current.type;

    emit(
      current.copyWith(
        query: nextQuery,
        type: nextType,
        // Always rebuilt from the full list, so tab and search compose instead
        // of one resetting the other.
        visible: matching(current.data.categories, nextQuery, nextType),
      ),
    );
  }

  /// The categories in tab [type] whose name contains [query].
  ///
  /// Only `name` is searched: it is the one text column worth searching.
  ///
  /// A search keeps a group whose *child* matched, even when the group's own
  /// name does not — otherwise the match would be rendered under no heading, or
  /// dropped along with its parent.
  static List<Category> matching(
    List<Category> source,
    String query,
    String type,
  ) {
    final List<Category> inTab = [
      for (final c in source)
        if (c.type == type) c,
    ];

    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return List<Category>.unmodifiable(inTab);

    bool hit(Category c) => (c.name ?? '').toLowerCase().contains(needle);

    final Set<int> keep = {};
    for (final c in inTab) {
      if (!hit(c)) continue;
      if (c.id != null) keep.add(c.id!);
      if (c.parentId != null) keep.add(c.parentId!);
    }

    return List<Category>.unmodifiable([
      for (final c in inTab)
        if (c.id != null && keep.contains(c.id)) c,
    ]);
  }
}
