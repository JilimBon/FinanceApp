import '../../data/models/category.dart';

abstract class CategoryState {}

class CategoryInitial extends CategoryState {}
class CategoryLoading extends CategoryState {}
class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  CategoryLoaded(this.categories);
}
class CategoryFailure extends CategoryState {
  final String message;
  CategoryFailure(this.message);
}