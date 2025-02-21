import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secret_keeper/password.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the directory for the database
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'passwords.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE passwords(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            site TEXT,
            username TEXT,
            password TEXT
          )
        ''');
      },
    );
  }

  // Function to fetch all password records
  Future<List<Password>> getPasswords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('passwords');
    return List.generate(maps.length, (i) {
      return Password.fromMap(maps[i]);
    });
  }

  // Function to insert a new password record
  Future<int> insertPassword(String userPin, Password password) async {
    final db = await database;
    return await db.insert('passwords', password.toMap(userPin));
  }

  Future<int> deletePassword(
    String site,
    String username,
    String encryptedPassword,
  ) async {
    final db = await database;
    return await db.delete(
      'passwords',
      where: 'site = ? AND username = ? AND password = ?',
      whereArgs: [site, username, encryptedPassword],
    );
  }
}
