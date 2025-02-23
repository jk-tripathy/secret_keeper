import 'package:flutter/material.dart';
import 'package:secret_keeper/screens/home_page.dart';
import 'package:secret_keeper/constants/colors.dart';
import 'package:secret_keeper/utils/password_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isMasterPasswordSet = false;
  final _masterPasswordController = TextEditingController();
  final _signUpPasswordController1 = TextEditingController();
  final _signUpPasswordController2 = TextEditingController();
  bool _obscureMasterText = true;
  bool _obscureSignupText1 = true;
  bool _obscureSignupText2 = true;

  Future<void> checkMasterPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    return setState(() {
      _isMasterPasswordSet = prefs.getBool('isMasterPasswordSet') ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    checkMasterPasswordSet();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      maintainBottomViewPadding: true,
      child: Scaffold(
        backgroundColor: context.lavender,
        body: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icon/logo.png',
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Secret Keeper',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: context.accent,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isMasterPasswordSet
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 40),
                            child: Text(
                              'Enter Master Password',
                              style: TextStyle(
                                fontSize: 20,
                                color: context.accent,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                            child: TextField(
                              controller: _masterPasswordController,
                              obscureText: _obscureMasterText,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Master Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureMasterText
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureMasterText = !_obscureMasterText;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 40),
                            child: Text(
                              'Set Master Password',
                              style: TextStyle(
                                fontSize: 20,
                                color: context.accent,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                            child: TextField(
                              controller: _signUpPasswordController1,
                              obscureText: _obscureSignupText1,
                              decoration: InputDecoration(
                                fillColor: context.white,
                                border: OutlineInputBorder(),
                                labelText: 'Master Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureSignupText1
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureSignupText1 =
                                          !_obscureSignupText1;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                            child: TextField(
                              controller: _signUpPasswordController2,
                              obscureText: _obscureSignupText2,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Confirm Master Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureSignupText2
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureSignupText2 =
                                          !_obscureSignupText2;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accent,
                          ),
                          onPressed: () async {
                            if (_isMasterPasswordSet) {
                              bool isCorrect =
                                  await PasswordHelper.validateMasterPassword(
                                    _masterPasswordController.text,
                                  );
                              if (isCorrect) {
                                _navigateToHomePage(
                                  _masterPasswordController.text,
                                );
                              } else {
                                _showSnackBar('Incorrect Master Password.');
                              }
                            } else if (_signUpPasswordController1.text ==
                                _signUpPasswordController2.text) {
                              await PasswordHelper.setAndSaveMasterPassword(
                                _signUpPasswordController1.text,
                              );
                              _navigateToHomePage(
                                _signUpPasswordController1.text,
                              );
                            } else {
                              _showSnackBar('Passwords do not match.');
                            }
                          },
                          child: Text(
                            'Enter',
                            style: TextStyle(color: context.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHomePage(String masterPassword) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(masterPassword: masterPassword),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
