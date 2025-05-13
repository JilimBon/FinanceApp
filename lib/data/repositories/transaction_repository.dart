import '../db/app_database.dart';
import '../models/transaction.dart';

class TransactionRepository {
  Future<List<TransactionModel>> getTransactions(int userId) async {
    final db = await AppDatabase().database;
    final result = await db.query('transactions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    final db = await AppDatabase().database;
    await db.insert('transactions', tx.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    final db = await AppDatabase().database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final db = await AppDatabase().database;
    await db.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<void> deleteAllTransactions(int userId) async {
    final db = await AppDatabase().database;
    await db.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
  }
}