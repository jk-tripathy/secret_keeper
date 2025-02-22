import 'package:flutter/material.dart';
import 'package:secret_keeper/password.dart';
import 'package:secret_keeper/database_helper.dart';
import 'package:secret_keeper/colors.dart';

class AddPasswordScreen extends StatefulWidget {
  final String masterPassword;
  const AddPasswordScreen({super.key, required this.masterPassword});

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
                    _saveEntry();
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
