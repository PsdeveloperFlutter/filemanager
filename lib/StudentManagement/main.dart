import 'package:filemanager/StudentManagement/screens/splashScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/auth_provider.dart';
import 'package:get/get.dart';
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProviders>(
          create: (_) => AuthProviders()..checkLoginStatus()..loadTheme(),
        ),
        // Add other providers here
      ],
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
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: authProvider.themeMode,

          // ✅ CORRECT FLOW
          home: const SplashScreen(),
        );
      },
    );
  }
}
