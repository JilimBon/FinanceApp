import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../db/app_database.dart';
import '../models/user.dart';

class UserRepository {
  Future<UserModel?> getUserByUsername(String username) async {
    final db = await AppDatabase().database;
    final result = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<UserModel> createUser(String username, String password) async {
    final db = await AppDatabase().database;
    final hash = _hashPassword(password);
    final id = await db.insert('users', {
      'username': username,
      'password_hash': hash,
    });
    return UserModel(id: id, username: username, passwordHash: hash);
  }

  bool verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
} 