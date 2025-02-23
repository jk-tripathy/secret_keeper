import 'package:flutter/material.dart';
import 'package:secret_keeper/screens/add_password_screen.dart';
import 'package:secret_keeper/constants/colors.dart';
import 'package:secret_keeper/services/database_helper.dart';
import 'package:secret_keeper/screens/login_screen.dart';
import 'package:secret_keeper/models/password.dart';
import 'package:secret_keeper/screens/password_search_delegate.dart';
import 'package:secret_keeper/screens/show_password_screen.dart';

class HomePage extends StatefulWidget {
  final String masterPassword;
  const HomePage({super.key, required this.masterPassword});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Password>> passwordsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPasswords();
  }

  void _refreshPasswords() {
    setState(() {
      passwordsFuture = DatabaseHelper().getPasswords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.deepPurple[100],
        appBar: AppBar(
          backgroundColor: Colors.deepPurple[100],
          title: Text(
            'Secret Keeper',
            style: TextStyle(
              color: context.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search_rounded, color: context.accent),
              onPressed: () async {
                final list = await DatabaseHelper().getPasswords();
                if (!mounted) return;
                showSearch(
                  context: context,
                  delegate: PasswordSearchDelegate(
                    passwords: list,
                    masterPassword: widget.masterPassword,
                  ),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: context.lavender,
          child: Column(
            mainAxisSize: MainAxisSize.max,

            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: context.accent),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: context.white,
                      child: Image.asset(
                        'assets/icon/logo.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                    SizedBox(height: 10, width: double.infinity),
                    Text(
                      'Secret Keeper',
                      style: TextStyle(
                        color: context.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.healing, color: context.accent),
                    title: Text('Fix Master Password'),
                    onTap: () async {
                      await Password.clearMasterPassword();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ),
              ),
              Expanded(child: Container()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Card(
                  color: context.accent,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: context.white),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: context.white),
                    ),
                    onTap: () async {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _refreshPasswords();
          },
          child: FutureBuilder<List<Password>>(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ShowPasswordScreen(
                                  passwordItem: passwordItem,
                                  masterPassword: widget.masterPassword,
                                ),
                          ),
                        );
                        _refreshPasswords();
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(
                            passwordItem.site,
                            style: TextStyle(color: context.accent),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              final updatedPassword = passwordItem.copyWith(
                                widget.masterPassword,
                                pinned: passwordItem.pinned == 1 ? 0 : 1,
                              );
                              DatabaseHelper().updatePassword(
                                widget.masterPassword,
                                updatedPassword,
                              );

                              _refreshPasswords();
                            },
                            icon: Icon(
                              passwordItem.pinned == 1
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: context.accent,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: context.accent,
          onPressed: () async {
            // Add a new password
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddPasswordScreen(
                      masterPassword: widget.masterPassword,
                    ),
              ),
            );
            if (result == true) {
              _refreshPasswords();
            }
          },
          child: Icon(Icons.add, color: context.white),
        ),
      ),
    );
  }
}
