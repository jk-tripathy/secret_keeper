import 'package:flutter/material.dart';
import 'package:secret_keeper/password.dart';
import 'package:secret_keeper/show_password_screen.dart';

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
          onTap: () {
            query = passwordItem.site;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ShowPasswordScreen(passwordItem: passwordItem),
              ),
            );
          },
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ShowPasswordScreen(passwordItem: passwordItem),
              ),
            );
          },
        );
      },
    );
  }
}
