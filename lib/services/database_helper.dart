import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secret_keeper/models/password.dart';
import 'package:secret_keeper/services/gdrive_helper.dart';
import 'package:secret_keeper/utils/password_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static SharedPreferences? prefs;
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE passwords(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        site TEXT,
        username TEXT,
        password TEXT
        pinned INTEGER DEFAULT 0
      )
    ''');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE passwords
   ADD COLUMN pinned INTEGER DEFAULT 0
      ''');
    }
  }

  Future<void> migrateMasterPassword(
    String oldMasterPassword,
    String newMasterPassword,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> userData = await db.query('passwords');

    for (final user in userData) {
      final Password password = Password.fromMap(user);
      final String decPwd;
      try {
        decPwd = PasswordHelper.decryptPassword(
          oldMasterPassword,
          password.password,
        );
        final String encPwd = PasswordHelper.encryptPassword(
          newMasterPassword,
          decPwd,
        );
        await db.update(
          'passwords',
          {'password': encPwd},
          where: 'id = ?',
          whereArgs: [password.id],
        );
      } catch (e) {
        return;
      }
    }
  }

  Future<Database> _initDatabase() async {
    prefs = await SharedPreferences.getInstance();
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'passwords.db');
    int version = 4;

    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final db = await openDatabase(
      path,
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    final res = await db.rawQuery('PRAGMA table_info(passwords)');
    if (res.any((column) => column['name'] == 'pinned') == false) {
      _onUpgrade(db, 3, 4);
    }

    return db;
  }

  Future<List<Password>> getPasswords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('passwords');
    final generatedList = List.generate(maps.length, (i) {
      return Password.fromMap(maps[i]);
    });
    generatedList.sort((a, b) {
      if (a.pinned != b.pinned) {
        return b.pinned.compareTo(a.pinned);
      } else {
        return a.site.toLowerCase().compareTo(b.site.toLowerCase());
      }
    });
    return generatedList;
  }

  Future<Password?> getPasswordByID(int id) async {
    final db = await database;
    final result = await db.query(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Password.fromMap(result.first);
    } else {
      return null;
    }
  }

  // Function to insert a new password record
  Future<int> insertPassword(String masterPassword, Password password) async {
    final db = await database;
    final res = await db.insert('passwords', password.toMap(masterPassword));
    final isGoogleSyncEnabled = prefs!.getBool('isGoogleSyncEnabled');
    if (res != 0 && isGoogleSyncEnabled!) {
      GdriveHelper.uploadBackup();
    }
    return res;
  }

  Future<int> deletePassword(int id) async {
    final db = await database;
    final res = await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
    final isGoogleSyncEnabled = prefs!.getBool('isGoogleSyncEnabled');
    if (res != 0 && isGoogleSyncEnabled!) {
      GdriveHelper.uploadBackup();
    }
    return res;
  }

  Future<int> updatePassword(String masterPassword, Password password) async {
    final db = await database;
    final res = await db.update(
      'passwords',
      password.toMap(masterPassword),
      where: 'id = ?',
      whereArgs: [password.id],
    );
    final isGoogleSyncEnabled = prefs!.getBool('isGoogleSyncEnabled');
    if (res != 0 && isGoogleSyncEnabled!) {
      GdriveHelper.uploadBackup();
    }
    return res;
  }
}
