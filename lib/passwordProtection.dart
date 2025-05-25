import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProtectionManager {
  /// Keys for SharedPreferences
  static String _passwordKey(String path) => 'protect_$path';

  static String _foodKey(String path) => 'food_$path';

  static String _placeKey(String path) => 'place_$path';

  /// Show a custom dialog and return a value
  static Future<T?> _showInputDialog<T>({
    required BuildContext context,
    required String title,
    required List<Widget> contentFields,
    required List<Widget> actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Column(children: contentFields)),
        actions: actions,
      ),
    );
  }

  /// Set password with recovery questions
  static Future<void> setPassword(BuildContext context, String path) async {
    final passwordController = TextEditingController();
    final foodController = TextEditingController();
    final placeController = TextEditingController();

    final saved = await _showInputDialog<bool>(
      context: context,
      title: 'Set Password & Recovery',
      contentFields: [
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter password'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: foodController,
          decoration:
              const InputDecoration(hintText: 'What is your favorite food?'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: placeController,
          decoration:
              const InputDecoration(hintText: 'What is your favorite place?'),
        ),
        const SizedBox(height: 10),
        const Text("Enter answer of both questions"),
      ],
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save')),
      ],
    );

    if (saved == true &&
        passwordController.text.isNotEmpty &&
        foodController.text.isNotEmpty &&
        placeController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_passwordKey(path), passwordController.text);
      await prefs.setString(
          _foodKey(path), foodController.text.trim().toLowerCase());
      await prefs.setString(
          _placeKey(path), placeController.text.trim().toLowerCase());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password and recovery questions set.')),
      );
    }
  }

  /// Validate password or recover it
  static Future<bool> validatePasswordIfProtected(
      BuildContext context, String path) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString(_passwordKey(path));

    if (storedPassword == null) return true;

    final passwordController = TextEditingController();

    final result = await _showInputDialog<String>(
      context: context,
      title: 'Enter Password',
      contentFields: [
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
      ],
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, 'forgot'),
            child: const Text('Forgot Password?')),
        TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('Unlock')),
      ],
    );

    if (result == 'forgot') {
      return await _recoverPassword(context, path);
    } else if (result == storedPassword) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password.')),
      );
      return false;
    }
  }

  /// Recover password by verifying recovery answers
  static Future<bool> _recoverPassword(
      BuildContext context, String path) async {
    final foodController = TextEditingController();
    final placeController = TextEditingController();

    final confirmed = await _showInputDialog<bool>(
      context: context,
      title: 'Recover Password',
      contentFields: [
        TextField(
          controller: foodController,
          decoration:
              const InputDecoration(hintText: 'What is your favorite food?'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: placeController,
          decoration:
              const InputDecoration(hintText: 'What is your favorite place?'),
        ),
      ],
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit')),
      ],
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final storedFood = prefs.getString(_foodKey(path)) ?? '';
      final storedPlace = prefs.getString(_placeKey(path)) ?? '';

      if (foodController.text.trim().toLowerCase() == storedFood &&
          placeController.text.trim().toLowerCase() == storedPlace) {
        // Remove credentials
        await prefs.remove(_passwordKey(path));
        await prefs.remove(_foodKey(path));
        await prefs.remove(_placeKey(path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password removed. Please set a new one.')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect recovery answers.')),
        );
        return false;
      }
    }

    return false;
  }
}
