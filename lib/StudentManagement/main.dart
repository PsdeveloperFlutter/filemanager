import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/login_screen.dart';
import 'provider/auth_provider.dart';
import 'screens/home_screen.dart';
import 'package:get/get.dart';
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProviders()..checkLoginStatus(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviders>(
      builder: (context, authProvider, _) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Student Management',
          theme: ThemeData(primarySwatch: Colors.blue),

          // ✅ CORRECT FLOW
          home: authProvider.isLoggedIn
              ? const HomeScreen()
              : LoginScreen(),
        );
      },
    );
  }
}
