import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProtectionManager {
  /// Save password for file/folder
  static Future<void> setPassword(BuildContext context, String path) async {
    TextEditingController controller = TextEditingController();

    String? password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(hintText: 'Enter password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('Save')),
        ],
      ),
    );

    if (password != null && password.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('protect_$path', password);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password set successfully.')),
      );
    }
  }

  /// Ask for password if file/folder is protected
  static Future<bool> validatePasswordIfProtected(BuildContext context, String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPassword = prefs.getString('protect_$path');

    // No password → allow access
    if (storedPassword == null) return true;

    TextEditingController controller = TextEditingController();

    String? entered = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(hintText: 'Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('Unlock')),
        ],
      ),
    );

    if (entered == storedPassword) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect password.')),
      );
      return false;
    }
  }
}
