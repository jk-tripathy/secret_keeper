import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secret_keeper/screens/add_password_screen.dart';
import 'package:secret_keeper/constants/colors.dart';
import 'package:secret_keeper/services/database_helper.dart';
import 'package:secret_keeper/models/password.dart';
import 'package:secret_keeper/utils/password_helper.dart';

class ShowPasswordScreen extends StatefulWidget {
  Password passwordItem;

  ShowPasswordScreen({super.key, required this.passwordItem});

  @override
  State<ShowPasswordScreen> createState() => _ShowPasswordScreenState();
}

class _ShowPasswordScreenState extends State<ShowPasswordScreen> {
  bool _obscurePassword = true;
  String? _decryptedPassword;
  late String masterPassword;

  @override
  void initState() {
    masterPassword = PasswordHelper.getMasterPassword();
    super.initState();
  }

  void editPassword() async {
    print('Edit password');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddPasswordScreen(
              passwordItem: widget.passwordItem,
              isUpdate: true,
            ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.lavender,
        appBar: AppBar(
          backgroundColor: context.lavender,
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: context.accent),
              onPressed: () {
                editPassword();
              },
            ),
            IconButton(
              color: context.accent,
              onPressed: () {
                DatabaseHelper().deletePassword(widget.passwordItem.id!);
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
                        onPressed: () {
                          final updatedPassword = widget.passwordItem.copyWith(
                            masterPassword,
                            pinned: widget.passwordItem.pinned == 1 ? 0 : 1,
                          );
                          DatabaseHelper().updatePassword(
                            masterPassword,
                            updatedPassword,
                          );

                          setState(() {
                            widget.passwordItem.pinned = updatedPassword.pinned;
                          });
                        },
                        icon: Icon(
                          widget.passwordItem.pinned == 1
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          color: context.accent,
                        ),
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
              final decrypted = PasswordHelper.decryptPassword(
                masterPassword,
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
