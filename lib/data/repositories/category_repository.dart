import '../db/app_database.dart';
import '../models/category.dart';

class CategoryRepository {
  static const List<String> _defaultIncomeCategories = [
    'Зарплата',
    'Подработка',
    'Инвестиции',
  ];
  static const List<String> _defaultExpenseCategories = [
    'Еда',
    'Транспорт',
    'Жилье',
    'Здоровье',
    'Развлечения',
    'Одежда и аксессуары',
    'Образование',
    'Подарки',
    'Путешествия',
  ];

  Future<List<CategoryModel>> getCategories(int type) async {
    final db = await AppDatabase().database;
    // Проверяем, есть ли категории этого типа
    final result = await db.query('categories', where: 'type = ?', whereArgs: [type]);
    if (result.isEmpty) {
      // Если нет, добавляем стандартные
      final defaults = type == 0 ? _defaultIncomeCategories : _defaultExpenseCategories;
      for (final name in defaults) {
        await db.insert('categories', {'name': name, 'type': type});
      }
      // Повторно получаем список
      final newResult = await db.query('categories', where: 'type = ?', whereArgs: [type]);
      return newResult.map((e) => CategoryModel.fromMap(e)).toList();
    }
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    final db = await AppDatabase().database;
    await db.insert('categories', category.toMap());
  }
}