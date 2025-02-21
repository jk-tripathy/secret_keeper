import 'package:flutter/material.dart';
import 'package:secret_keeper/main.dart';

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
  final TextEditingController _masterPasswordController =
      TextEditingController();

  void _saveEntry(String userPin) async {
    if (_formKey.currentState!.validate()) {
      // Create a new Password instance without an id.
      Password newPassword = Password(
        site: _siteController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      await DatabaseHelper().insertPassword(userPin, newPassword);
    }
  }

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _masterPasswordController.dispose();
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
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Master Password'),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the master password'
                            : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveEntry(_masterPasswordController.text);
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
