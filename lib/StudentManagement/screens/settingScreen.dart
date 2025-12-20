import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProviders>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Card(
           elevation: 1,
            child: RadioListTile<ThemeMode>(
              title: const Text('Light Theme'),
              value: ThemeMode.light,
              groupValue: provider.themeMode,
              onChanged: (value) {
                provider.changeTheme(value!);
              },
            ),
          ),
          Card(
            elevation: 1,
            child: RadioListTile<ThemeMode>(
              title: const Text('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: provider.themeMode,
              onChanged: (value) {
                provider.changeTheme(value!);
              },
            ),
          ),
          Card(
            elevation: 1,
            child: RadioListTile<ThemeMode>(
              title: const Text('System Theme'),
              value: ThemeMode.system,
              groupValue: provider.themeMode,
              onChanged: (value) {
                provider.changeTheme(value!);
              },
            ),
          ),
        ],
      ),
    );
  }
}
