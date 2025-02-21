import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class Password {
  final int id;
  final String site;
  final String username;
  final String password;

  Password({
    required this.id,
    required this.site,
    required this.username,
    required this.password,
  });

  factory Password.fromMap(Map<String, dynamic> json) => Password(
    id: json['id'],
    site: json['site'],
    username: json['username'],
    password: json['password'],
  );

  Map<String, dynamic> toMap() {
    return {'site': site, 'username': username, 'password': password};
  }
}

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
  Future<int> insertPassword(Password password) async {
    final db = await database;
    return await db.insert('passwords', password.toMap());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secret Keeper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Password>> passwordsFuture;

  @override
  void initState() {
    super.initState();
    passwordsFuture = DatabaseHelper().getPasswords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secret Keeper'),
        actions: [
          IconButton(icon: Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<List<Password>>(
        future: passwordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No passwords found.'));
          } else {
            final passwords = snapshot.data!;
            return ListView.builder(
              itemCount: passwords.length,
              itemBuilder: (context, index) {
                final passwordItem = passwords[index];
                return ListTile(
                  title: Text(passwordItem.site),
                  subtitle: Text(passwordItem.password),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a new password
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
