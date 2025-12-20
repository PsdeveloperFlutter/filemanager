import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🌈 Gradient Background
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

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔹 Title
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Email
                        TextFormField(
                          controller: emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email required";
                            }
                            if (!value.contains('@')) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 🔹 Password with Provider
                        Consumer<AuthProviders>(
                          builder: (context, authProvider, _) {
                            return TextFormField(
                              controller: passwordController,
                              obscureText: authProvider.obscurePasswordforLogin,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return "Password must be 6 characters";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: InkWell(
                                  onTap: () {
                                    authProvider.setObscurePasswordLogin(
                                      !authProvider.obscurePasswordforLogin,
                                    );
                                  },
                                  child: Icon(
                                    authProvider.obscurePasswordforLogin
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final auth = context.read<AuthProviders>();

                                final success = await auth.loginUser(
                                  emailController.text.trim(),
                                  passwordController.text.trim(),
                                );

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Login Successful")),
                                  );

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const HomeScreen()),
                                    (route) => false,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Login Failed")),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
