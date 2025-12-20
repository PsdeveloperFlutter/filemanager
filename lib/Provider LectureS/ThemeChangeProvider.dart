import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeChanger(),
      child: const MyApp(),
    ),
  );
}

/* ================= PROVIDER ================= */

class ThemeChanger extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

/* ================= APP ================= */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeChanger>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: const ThemeChangeScreen(),
    );
  }
}

/* ================= UI ================= */

class ThemeChangeScreen extends StatelessWidget {
  const ThemeChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeChanger>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Theme"),
      ),
      body: Column(
        children: [

          RadioListTile<ThemeMode>(
            title: const Text("Light Theme"),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              themeProvider.setTheme(value!);
            },
          ),

          RadioListTile<ThemeMode>(
            title: const Text("Dark Theme"),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              themeProvider.setTheme(value!);
            },
          ),

          RadioListTile<ThemeMode>(
            title: const Text("System Default"),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              themeProvider.setTheme(value!);
            },
          ),

        ],
      ),
    );
  }
}
