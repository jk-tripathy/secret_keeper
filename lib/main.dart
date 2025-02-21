import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class Password {
  final String site;
  final String username;
  final String password;

  Password({
    required this.site,
    required this.username,
    required this.password,
  });

  factory Password.fromMap(Map<String, dynamic> json) => Password(
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

  void _refreshPasswords() {
    setState(() {
      passwordsFuture = DatabaseHelper().getPasswords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secret Keeper'),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: () async {
              final list = await DatabaseHelper().getPasswords();
              showSearch(
                context: context,
                delegate: PasswordSearchDelegate(passwords: list),
              );
            },
          ),
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
                return Card(child: ListTile(title: Text(passwordItem.site)));
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Add a new password
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPasswordScreen()),
          );
          // If V
          if (result == true) {
            _refreshPasswords();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      // Create a new Password instance without an id.
      Password newPassword = Password(
        site: _siteController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      await DatabaseHelper().insertPassword(newPassword);
    }
  }

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Password')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _siteController,
                decoration: InputDecoration(labelText: 'Site'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the site'
                            : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the username'
                            : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the password'
                            : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveEntry();
                  Navigator.pop(context, true);
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordSearchDelegate extends SearchDelegate<Password?> {
  final List<Password> passwords;

  PasswordSearchDelegate({required this.passwords});

  // Actions for the app bar (clear the search query)
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  // Leading icon for the app bar (back arrow)
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  // Show results based on the search query
  @override
  Widget buildResults(BuildContext context) {
    final results =
        passwords.where((password) {
          return password.site.toLowerCase().contains(query.toLowerCase());
        }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final passwordItem = results[index];
        return ListTile(
          title: Text(passwordItem.site),
          subtitle: Text(
            'Username: ${passwordItem.username}\nPassword: ${passwordItem.password}',
          ),
          isThreeLine: true,
        );
      },
    );
  }

  // Show suggestions while the user types
  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        passwords.where((password) {
          return password.site.toLowerCase().contains(query.toLowerCase()) ||
              password.username.toLowerCase().contains(query.toLowerCase());
        }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final passwordItem = suggestions[index];
        return ListTile(
          title: Text(passwordItem.site),
          subtitle: Text('Username: ${passwordItem.username}'),
          onTap: () {
            query = passwordItem.site;
            showResults(context);
          },
        );
      },
    );
  }
}
