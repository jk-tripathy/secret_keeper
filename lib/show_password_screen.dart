import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secret_keeper/add_password_screen.dart';
import 'package:secret_keeper/colors.dart';
import 'package:secret_keeper/database_helper.dart';
import 'package:secret_keeper/password.dart';

class ShowPasswordScreen extends StatefulWidget {
  final String masterPassword;
  final Password passwordItem;

  const ShowPasswordScreen({
    super.key,
    required this.passwordItem,
    required this.masterPassword,
  });

  @override
  State<ShowPasswordScreen> createState() => _ShowPasswordScreenState();
}

class _ShowPasswordScreenState extends State<ShowPasswordScreen> {
  bool _obscurePassword = true;
  String? _decryptedPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lavender,
      appBar: AppBar(
        backgroundColor: context.lavender,
        actions: [
          IconButton(
            color: context.accent,
            onPressed: () {
              DatabaseHelper().deletePassword(
                widget.passwordItem.site,
                widget.passwordItem.username,
                widget.passwordItem.password,
              );
              Navigator.of(context).pop(true);
            },
            icon: Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.passwordItem.site,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),

                    IconButton(
                      icon: Icon(Icons.edit, color: context.accent),
                      onPressed: () async {
                        DatabaseHelper().deletePassword(
                          widget.passwordItem.site,
                          widget.passwordItem.username,
                          widget.passwordItem.password,
                        );
                        final decryptedPassword = widget.passwordItem
                            .decryptPassword(
                              widget.masterPassword,
                              widget.passwordItem.password,
                            );
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AddPasswordScreen(
                                  masterPassword: widget.masterPassword,
                                  site: widget.passwordItem.site,
                                  username: widget.passwordItem.username,
                                  password: decryptedPassword,
                                ),
                          ),
                        );
                        Navigator.of(context).pop(res);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildUsernameRow(),
                const SizedBox(height: 16),
                _buildPasswordRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameRow() {
    return Row(
      children: [
        Icon(Icons.person, color: context.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Username",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              Text(
                widget.passwordItem.username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          color: context.accent,
          icon: const Icon(Icons.copy, size: 20),
          onPressed:
              () => _copyToClipboard(widget.passwordItem.username, "Username"),
          tooltip: "Copy Username",
        ),
      ],
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      children: [
        Icon(Icons.lock, color: context.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Password",
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
              Text(
                _obscurePassword
                    ? '••••••••'
                    : _decryptedPassword ?? 'Decryption failed!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          color: context.accent,
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            size: 22,
          ),
          onPressed: () async {
            if (_obscurePassword && _decryptedPassword == null) {
              final decrypted = widget.passwordItem.decryptPassword(
                widget.masterPassword,
                widget.passwordItem.password,
              ); //
              setState(() {
                _decryptedPassword = decrypted;
                _obscurePassword = false;
              });
            } else {
              setState(() => _obscurePassword = !_obscurePassword);
            }
          },
          tooltip: _obscurePassword ? "Show Password" : "Hide Password",
        ),
        IconButton(
          color: context.accent,
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(_decryptedPassword!, "Password"),
          tooltip: "Copy Password",
        ),
      ],
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
