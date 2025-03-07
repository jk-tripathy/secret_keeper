import 'package:flutter/material.dart';
import 'package:secret_keeper/screens/add_password_screen.dart';
import 'package:secret_keeper/constants/colors.dart';
import 'package:secret_keeper/services/database_helper.dart';
import 'package:secret_keeper/screens/login_screen.dart';
import 'package:secret_keeper/models/password.dart';
import 'package:secret_keeper/screens/password_search_delegate.dart';
import 'package:secret_keeper/screens/show_password_screen.dart';
import 'package:secret_keeper/services/gdrive_helper.dart';
import 'package:secret_keeper/utils/password_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Password> passwordsList;
  bool isBiometricEnabled = false;
  bool isGoogleSyncEnabled = false;
  late SharedPreferences perfs;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setUpBiometric();
    _setUpGoogleSync();
    _refreshPasswords();
  }

  void _setUpBiometric() async {
    perfs = await SharedPreferences.getInstance();
    setState(() {
      isBiometricEnabled = perfs.getBool('isBiometricEnabled') ?? false;
    });
  }

  void _setUpGoogleSync() async {
    perfs = await SharedPreferences.getInstance();
    setState(() {
      isGoogleSyncEnabled = perfs.getBool('isGoogleSyncEnabled') ?? false;
    });

    if (isGoogleSyncEnabled) {
      await GdriveHelper.signInSilently();
    }
    _refreshPasswords();
  }

  Future<void> _refreshPasswords() async {
    setState(() {
      isProcessing = true;
    });
    final temp = await DatabaseHelper().getPasswords();
    setState(() {
      passwordsList = temp;
      isProcessing = false;
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
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: PasswordSearchDelegate(passwords: passwordsList),
                );
              },
            ),
            isGoogleSyncEnabled
                ? IconButton(
                  icon: Icon(Icons.sync_outlined, color: context.accent),
                  onPressed: () async {
                    await _refreshPasswords();
                  },
                )
                : SizedBox.shrink(),
          ],
        ),
        drawer: sideDrawer(),
        body:
            isProcessing
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: () async {
                    await _refreshPasswords();
                  },
                  child: FutureBuilder<List<Password>>(
                    future: DatabaseHelper().getPasswords(),
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
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ShowPasswordScreen(
                                          passwordItem: passwordItem,
                                        ),
                                  ),
                                );
                                _refreshPasswords();
                              },
                              child: passwordCardTile(passwordItem),
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
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddPasswordScreen()),
            );
            _refreshPasswords();
          },
          child: Icon(Icons.add, color: context.white),
        ),
      ),
    );
  }

  Widget sideDrawer() {
    return Drawer(
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.healing, color: context.accent),
                title: Text('Fix Master Password'),
                onTap: () {
                  PasswordHelper.clearMasterPassword();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            ),
          ),
          isBiometricEnabled
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.fingerprint_outlined,
                      color: context.accent,
                    ),
                    title: Text('Biometric Login'),
                    trailing: Switch(
                      activeColor: context.accent,
                      value: isBiometricEnabled,
                      onChanged: (value) {
                        setState(() {
                          isBiometricEnabled = value;
                          perfs.setBool(
                            'isBiometricEnabled',
                            isBiometricEnabled,
                          );
                        });
                      },
                    ),
                  ),
                ),
              )
              : SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.sync_outlined, color: context.accent),
                title: Text('Google Sync'),
                trailing: Switch(
                  activeColor: context.accent,
                  value: isGoogleSyncEnabled,
                  onChanged: (value) async {
                    setState(() {
                      isGoogleSyncEnabled = value;
                      perfs.setBool('isGoogleSyncEnabled', isGoogleSyncEnabled);
                    });
                    if (value) {
                      await GdriveHelper.signIn();
                    } else {
                      await GdriveHelper.signOut();
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(child: Container()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              color: context.accent,
              child: ListTile(
                leading: Icon(Icons.logout, color: context.white),
                title: Text('Logout', style: TextStyle(color: context.white)),
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
    );
  }

  Widget passwordCardTile(Password passwordItem) {
    return Card(
      child: ListTile(
        title: Text(passwordItem.site, style: TextStyle(color: context.accent)),
        trailing: IconButton(
          onPressed: () async {
            final String masterPassword = PasswordHelper.getMasterPassword();
            final updatedPassword = passwordItem.copyWith(
              masterPassword,
              pinned: passwordItem.pinned == 1 ? 0 : 1,
            );
            setState(() {
              isProcessing = true;
            });
            await DatabaseHelper().updatePassword(
              masterPassword,
              updatedPassword,
            );

            setState(() {
              isProcessing = false;
            });

            _refreshPasswords();
          },
          icon: Icon(
            passwordItem.pinned == 1 ? Icons.push_pin : Icons.push_pin_outlined,
            color: context.accent,
          ),
        ),
      ),
    );
  }
}
