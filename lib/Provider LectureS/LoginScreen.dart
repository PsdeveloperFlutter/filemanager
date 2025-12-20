import 'package:filemanager/Provider%20LectureS/auth_Provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(),
    child: MaterialApp(home: loginScreen()),
  ));
}

class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: emailController,
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      gapPadding: 10,
                      borderSide: BorderSide(color: Colors.blue, width: 2)),
                  hintText: "Enter Your Email"),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: passwordController,
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      gapPadding: 10,
                      borderSide: BorderSide(color: Colors.blue, width: 2)),
                  hintText: "Enter Your Password"),
              obscureText: true,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () {
                String email = emailController.text;
                String password = passwordController.text;
                print("Email : $email \n Password : $password");
                authProvider.login(email, password);
                },
              child:authProvider.loading?Center(child: CircularProgressIndicator()): Text("Login"))
        ],
      )),
    );
  }
}
