import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/models/category.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository categoryRepository;
  CategoryCubit(this.categoryRepository) : super(CategoryInitial());

  Future<void> loadCategories(int type) async {
    emit(CategoryLoading());
    final categories = await categoryRepository.getCategories(type);
    emit(CategoryLoaded(categories));
  }

  Future<void> addCategory(CategoryModel category) async {
    await categoryRepository.addCategory(category);
    loadCategories(category.type);
  }
}