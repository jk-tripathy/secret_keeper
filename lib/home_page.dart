import 'package:flutter/material.dart';
import 'package:secret_keeper/add_password_screen.dart';
import 'package:secret_keeper/database_helper.dart';
import 'package:secret_keeper/password.dart';
import 'package:secret_keeper/password_search_delegate.dart';
import 'package:secret_keeper/show_password_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      backgroundColor: Colors.deepPurple[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[100],
        title: Text('Secret Keeper'),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: Colors.deepPurple),
            onPressed: () async {
              final list = await DatabaseHelper().getPasswords();
              if (!mounted) return;
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
                return GestureDetector(
                  onTap: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ShowPasswordScreen(passwordItem: passwordItem),
                      ),
                    );
                    if (res == true) {
                      _refreshPasswords();
                    }
                  },
                  child: Card(child: ListTile(title: Text(passwordItem.site))),
                );
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
