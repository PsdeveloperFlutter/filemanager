import 'dart:async';
import 'package:filemanager/StudentManagement/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../screens/home_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    print("Navigating to next screen... \n");
    final authProvider = context.read<AuthProviders>();
    print("${authProvider.isLoggedIn} \n");
    authProvider.fetchUserSignUpData();
     print("User SignUp Data: ${authProvider.userSignUpData} \n");
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if(authProvider.isLoggedIn==false && authProvider.isLoggedIn==null  && authProvider.checkSignUpData()==true){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xfffcd66d),
              Color(0xFF6dd5ed),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 90, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Student Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text("Developed by Priyanshu Satija \n© 2025 All Rights Reserved",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                )),
          ],
        ),
      ),
    );
  }
}
