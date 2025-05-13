import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password_hash TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            type INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            amount REAL,
            type INTEGER,
            category TEXT,
            date TEXT,
            description TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          );
        ''');

        // Initialize default categories
        await _initializeDefaultCategories(db);
      },
    );
  }

  Future<void> _initializeDefaultCategories(Database db) async {
    // Income categories (type = 0)
    final incomeCategories = [
      'Зарплата',
      'Подработка',
      'Инвестиции',
    ];

    // Expense categories (type = 1)
    final expenseCategories = [
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

    // Insert income categories
    for (final category in incomeCategories) {
      await db.insert('categories', {
        'name': category,
        'type': 0,
      });
    }

    // Insert expense categories
    for (final category in expenseCategories) {
      await db.insert('categories', {
        'name': category,
        'type': 1,
      });
    }
  }
}