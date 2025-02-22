import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secret_keeper/database_helper.dart';
import 'package:secret_keeper/password.dart';

class ShowPasswordScreen extends StatefulWidget {
  final Password passwordItem;

  const ShowPasswordScreen({super.key, required this.passwordItem});

  @override
  State<ShowPasswordScreen> createState() => _ShowPasswordScreenState();
}

class _ShowPasswordScreenState extends State<ShowPasswordScreen> {
  bool _obscurePassword = true;
  String? _decryptedPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      appBar: AppBar(
        title: Text(widget.passwordItem.site),
        backgroundColor: Colors.deepPurple[100],
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
                      color: Colors.deepPurple,
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
                const SizedBox(height: 24),
                _buildUsernameRow(
                  label: "Username",
                  value: widget.passwordItem.username,
                  icon: Icons.person,
                  onCopy:
                      () => _copyToClipboard(
                        widget.passwordItem.username,
                        "Username",
                      ),
                ),
                const SizedBox(height: 16),
                _buildPasswordRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      children: [
        const Icon(Icons.lock, color: Colors.blueGrey),
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
          color: Colors.deepPurple,
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            size: 22,
          ),
          onPressed: () async {
            if (_obscurePassword && _decryptedPassword == null) {
              _promptForMasterPassword();
            } else {
              setState(() => _obscurePassword = !_obscurePassword);
            }
          },
          tooltip: _obscurePassword ? "Show Password" : "Hide Password",
        ),
        IconButton(
          color: Colors.deepPurple,
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(_decryptedPassword!, "Password"),
          tooltip: "Copy Password",
        ),
      ],
    );
  }

  Widget _buildUsernameRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          color: Colors.deepPurple,
          icon: const Icon(Icons.copy, size: 20),
          onPressed: onCopy,
          tooltip: "Copy $label",
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

  void _promptForMasterPassword() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Master Password'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Master Password'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String inputPassword = controller.text;
                  final decrypted = widget.passwordItem.decryptPassword(
                    inputPassword,
                    widget.passwordItem.password,
                  ); //
                  setState(() {
                    _decryptedPassword = decrypted;
                    _obscurePassword = false;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }
}
