import 'package:flutter/material.dart';
import 'package:secret_keeper/constants/colors.dart';
import 'package:secret_keeper/models/password.dart';
import 'package:secret_keeper/services/database_helper.dart';
import 'package:secret_keeper/utils/password_helper.dart';

class AddPasswordScreen extends StatefulWidget {
  final Password? passwordItem;
  final bool isUpdate;

  const AddPasswordScreen({
    super.key,
    this.passwordItem,
    this.isUpdate = false,
  });

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool isProcessing = false;
  late String masterPassword;

  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    masterPassword = PasswordHelper.getMasterPassword();
    super.initState();
    if (widget.isUpdate) {
      final decryptedPassword = PasswordHelper.decryptPassword(
        masterPassword,
        widget.passwordItem!.password,
      );

      _siteController.text = widget.passwordItem!.site;
      _usernameController.text = widget.passwordItem!.username;
      _passwordController.text = decryptedPassword;
    }
  }

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> savePassword(
    String masterPassword,
    String site,
    String username,
    String password,
  ) async {
    setState(() {
      isProcessing = true;
    });
    Password newPassword = Password(
      site: site,
      username: username,
      password: password,
    );

    await DatabaseHelper().insertPassword(masterPassword, newPassword);
    setState(() {
      isProcessing = false;
    });

    Navigator.pop(context, true);
  }

  Future<void> updatePassword(
    String masterPassword,
    int id,
    String site,
    String username,
    String password,
    int pinned,
  ) async {
    setState(() {
      isProcessing = true;
    });
    Password updatedPassword = Password(
      id: id,
      site: site,
      username: username,
      password: password,
      pinned: pinned,
    );

    await DatabaseHelper().updatePassword(masterPassword, updatedPassword);
    setState(() {
      isProcessing = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.lavender,
        appBar: AppBar(
          title: Text(
            widget.isUpdate ? 'Update Password' : 'Add Password',
            style: TextStyle(color: context.accent),
          ),
          backgroundColor: context.lavender,
        ),
        body:
            isProcessing
                ? Center(child: CircularProgressIndicator())
                : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: _siteController,
                            decoration: InputDecoration(
                              labelText: 'Site',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter the site'
                                        : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter the username'
                                        : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: _passwordController,
                            textInputAction: TextInputAction.go,
                            onFieldSubmitted: (value) async {
                              if (widget.isUpdate) {
                                if (_formKey.currentState!.validate()) {
                                  updatePassword(
                                    masterPassword,
                                    widget.passwordItem!.id!,
                                    _siteController.text,
                                    _usernameController.text,
                                    _passwordController.text,
                                    widget.passwordItem!.pinned,
                                  );
                                }
                              } else {
                                if (_formKey.currentState!.validate()) {
                                  savePassword(
                                    masterPassword,
                                    _siteController.text,
                                    _usernameController.text,
                                    _passwordController.text,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please fill all the fields',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter the password'
                                        : null,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accent,
                          ),
                          onPressed: () {
                            if (widget.isUpdate) {
                              if (_formKey.currentState!.validate()) {
                                updatePassword(
                                  masterPassword,
                                  widget.passwordItem!.id!,
                                  _siteController.text,
                                  _usernameController.text,
                                  _passwordController.text,
                                  widget.passwordItem!.pinned,
                                );
                              }
                            } else {
                              if (_formKey.currentState!.validate()) {
                                savePassword(
                                  masterPassword,
                                  _siteController.text,
                                  _usernameController.text,
                                  _passwordController.text,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill all the fields'),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            widget.isUpdate ? 'Update' : 'Save',
                            style: TextStyle(color: context.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
