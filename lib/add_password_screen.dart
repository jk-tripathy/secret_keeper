import 'package:flutter/material.dart';
import 'package:secret_keeper/password.dart';
import 'package:secret_keeper/database_helper.dart';
import 'package:secret_keeper/colors.dart';

class AddPasswordScreen extends StatefulWidget {
  final String masterPassword;
  final int? id;
  final String? site;
  final String? username;
  final String? password;
  final bool isUpdate;

  const AddPasswordScreen({
    super.key,
    required this.masterPassword,
    this.id,
    this.site,
    this.username,
    this.password,
    this.isUpdate = false,
  });

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

      await DatabaseHelper().insertPassword(widget.masterPassword, newPassword);
    }
  }

  void _updateEntry() async {
    if (_formKey.currentState!.validate()) {
      // Create a new Password instance with an id.
      Password updatedPassword = Password(
        id: widget.id,
        site: _siteController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      await DatabaseHelper().updatePassword(
        widget.masterPassword,
        updatedPassword,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.site != null) {
      _siteController.text = widget.site!;
    }
    if (widget.username != null) {
      _usernameController.text = widget.username!;
    }
    if (widget.password != null) {
      _passwordController.text = widget.password!;
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.lavender,
        appBar: AppBar(
          title: Text('Add New Password'),
          backgroundColor: context.lavender,
        ),
        body: Padding(
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
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
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
                      _updateEntry();
                    } else {
                      _saveEntry();
                    }
                    Navigator.pop(context, true);
                  },
                  child: Text('Save', style: TextStyle(color: context.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
