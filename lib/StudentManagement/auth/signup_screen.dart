import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

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
                          "Create Account",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Full Name
                        TextFormField(
                          controller: nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Full name is required";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 🔹 Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            if (!value.contains('@')) {
                              return "Enter a valid email";
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

                        // 🔹 Password
                        Consumer<AuthProviders>(
                          builder: (context, authProvider, _) {
                            return TextFormField(
                              controller: passwordController,
                              obscureText:
                                  authProvider.obscurePasswordforSignUp,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: InkWell(
                                  onTap: () {
                                    authProvider.setObscureText(
                                      !authProvider.obscurePasswordforSignUp,
                                    );
                                  },
                                  child: Icon(
                                    authProvider.obscurePasswordforSignUp
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // 🔹 Confirm Password
                        Consumer<AuthProviders>(
                          builder: (context, authProvider, _) {
                            return TextFormField(
                              controller: confirmPasswordController,
                              obscureText:
                                  authProvider.obscureConfirmPasswordforSignUp,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Confirm password required";
                                }
                                if (value != passwordController.text) {
                                  return "Passwords do not match";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: InkWell(
                                  onTap: () {
                                    authProvider.setObscureText2(
                                      !authProvider
                                          .obscureConfirmPasswordforSignUp,
                                    );
                                  },
                                  child: Icon(
                                    authProvider.obscureConfirmPasswordforSignUp
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

                        // 🔹 Signup Button
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
                                await context.read<AuthProviders>().signUp(
                                      nameController.text.trim(),
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                    );

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Signup Successful")),
                                );

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text(
                              "Create Account",
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
