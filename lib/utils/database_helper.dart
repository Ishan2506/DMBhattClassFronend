import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null; // No database on web
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'student_accounts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT UNIQUE,
            name TEXT,
            token TEXT,
            role TEXT,
            phone TEXT,
            userData TEXT,
            profilePic TEXT,
            isActive INTEGER DEFAULT 1
          )
        ''');
      },
    );
  }

  Future<void> saveAccount({
    required String userId,
    required String name,
    required String token,
    required String role,
    required String phone,
    String? userData,
    String? profilePic,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> accounts = await getAccounts();
      final newAcc = {
        'userId': userId,
        'name': name,
        'token': token,
        'role': role,
        'phone': phone,
        'userData': userData,
        'profilePic': profilePic,
        'isActive': 1,
      };
      // Upsert
      int index = accounts.indexWhere((a) => a['userId'] == userId);
      if (index >= 0) accounts[index] = newAcc;
      else accounts.add(newAcc);
      await prefs.setString('web_accounts_fallback', jsonEncode(accounts));
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert(
      'accounts',
      {
        'userId': userId,
        'name': name,
        'token': token,
        'role': role,
        'phone': phone,
        'userData': userData,
        'profilePic': profilePic,
        'isActive': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('web_accounts_fallback');
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    final db = await database;
    if (db == null) return [];
    return await db.query('accounts', orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getAccount(String userId) async {
    if (kIsWeb) {
      final accounts = await getAccounts();
      final results = accounts.where((a) => a['userId'] == userId).toList();
      return results.isNotEmpty ? results.first : null;
    }
    final db = await database;
    if (db == null) return null;
    final results = await db.query(
      'accounts',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteAccount(String userId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> accounts = await getAccounts();
      accounts.removeWhere((a) => a['userId'] == userId);
      await prefs.setString('web_accounts_fallback', jsonEncode(accounts));
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete(
      'accounts',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> clearAllExcept(String? currentUserId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      if (currentUserId != null) {
        List<Map<String, dynamic>> accounts = await getAccounts();
        accounts.retainWhere((a) => a['userId'] == currentUserId);
        await prefs.setString('web_accounts_fallback', jsonEncode(accounts));
      } else {
        await prefs.remove('web_accounts_fallback');
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    if (currentUserId != null) {
      await db.delete(
        'accounts',
        where: 'userId != ?',
        whereArgs: [currentUserId],
      );
    } else {
      await db.delete('accounts');
    }
  }
}
