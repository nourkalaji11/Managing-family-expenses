import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_expense_management/data/models/categories_data.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/repos/categories_repo.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/presentation/pages/categories/domain/categories_domain.dart';

part 'category_form_event.dart';
part 'category_form_state.dart';

/// Drives Add, Edit and Delete for a category.
///
/// Structurally identical to `AccountFormBloc`, with one field instead of two.
/// Validation mirrors what `CategoryController` validates:
///
///     'name' => 'required|string|max:50|unique:categories,name'
///
/// The uniqueness rule is deliberately **not** re-implemented here. The client
/// cannot see categories it did not load, and `categories` has no owner column,
/// so the authoritative check is the server's — a local guess would either
/// block a name the server accepts or miss one it rejects. The 422 comes back
/// with an already-Arabic message, which the screen shows verbatim.
class CategoryFormBloc extends Bloc<CategoryFormEvent, CategoryFormState> {
  final CategoriesDomain _repo;

  CategoryFormBloc({CategoriesDomain? repo})
    : _repo = repo ?? CategoriesRepo(),
      super(const CategoryFormState.initial()) {
    on<CategoryFormEvent>((event, emit) async {
      if (event is OnCategoryFormStarted) {
        emit(_seed(event));
      } else if (event is OnCategoryNameChanged) {
        emit(
          state.copyWith(
            name: event.name,
            errors: validate(state.copyWith(name: event.name)),
            status: CategoryFormStatus.editing,
            clearFailure: true,
          ),
        );
      } else if (event is OnSubmitCategoryForm) {
        await _submit(emit);
      } else if (event is OnDeleteCategory) {
        await _delete(emit);
      }
    });
  }

  CategoryFormState _seed(OnCategoryFormStarted event) {
    final Category? existing = event.category;

    if (existing == null) {
      return const CategoryFormState(
        mode: CategoryFormMode.add,
        errors: CategoryFormErrors(),
      );
    }

    return CategoryFormState(
      mode: CategoryFormMode.edit,
      id: existing.id,
      name: existing.name ?? '',
      // Drives whether the delete button warns first: the server refuses a
      // delete on a category still referenced by a transaction or a budget.
      usageCount: event.usageCount,
      errors: const CategoryFormErrors(),
    );
  }

  Future<void> _submit(Emitter<CategoryFormState> emit) async {
    // Guards double submission.
    if (state.isBusy) return;

    final CategoryFormErrors errors = validate(state);
    if (errors.hasAny) {
      emit(state.copyWith(errors: errors, showErrors: true));
      return;
    }

    emit(
      state.copyWith(
        status: CategoryFormStatus.submitting,
        showErrors: true,
        errors: errors,
        clearFailure: true,
      ),
    );

    final CategoryDraft draft = CategoryDraft(name: state.name.trim());

    final result = state.mode == CategoryFormMode.add
        ? await _repo.createCategory(draft)
        : await _repo.updateCategory(state.id!, draft);

    result.fold(
      (failure) => emit(
        state.copyWith(status: CategoryFormStatus.failure, failure: failure),
      ),
      (saved) => emit(
        state.copyWith(status: CategoryFormStatus.success, saved: saved),
      ),
    );
  }

  Future<void> _delete(Emitter<CategoryFormState> emit) async {
    if (state.isBusy) return;

    final int? id = state.id;
    if (id == null) return;

    emit(
      state.copyWith(status: CategoryFormStatus.deleting, clearFailure: true),
    );

    final result = await _repo.deleteCategory(id);

    result.fold(
      (failure) => emit(
        state.copyWith(status: CategoryFormStatus.failure, failure: failure),
      ),
      (_) => emit(state.copyWith(status: CategoryFormStatus.deleted)),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation. Returns localisation KEYS, not translated strings.
  // ---------------------------------------------------------------------------

  /// Backend rule: `max:50`. Note this is half the account limit — the two
  /// tables genuinely differ.
  static const int maxNameLength = 50;

  static CategoryFormErrors validate(CategoryFormState state) {
    final String name = state.name.trim();

    if (name.isEmpty) {
      return const CategoryFormErrors(name: 'categories.error_name_required');
    }
    if (name.length > maxNameLength) {
      return const CategoryFormErrors(name: 'categories.error_name_too_long');
    }
    return const CategoryFormErrors();
  }
}
