import 'package:flutter/material.dart';

import 'AuthService.dart';

class PasswordScreen extends StatefulWidget {
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  // Controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController questionController1 = TextEditingController();
  final TextEditingController questionController2 = TextEditingController();
  final TextEditingController answerController1 = TextEditingController();
  final TextEditingController answerController2 = TextEditingController();

  final List<String> recoveryQuestions = [
    "What is your mother's maiden name?",
    "What was the name of your first pet?",
    "What is your favorite food?",
    "What city were you born in?",
    "What is your father's middle name?",
    "What was your childhood nickname?",
  ];

  @override
  void initState() {
    super.initState();
    questionController1.text = recoveryQuestions[0];
    questionController2.text = recoveryQuestions[1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            buildTextField('Enter 4 digit Password', passwordController, false),
            buildTextField(
                'Confirm Password', confirmPasswordController, false),
            const SizedBox(height: 30),
            Text("Security Questions",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              "These questions will help you when you forget your password.\nAll your security answers will be encrypted and stored only on the local device.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            /// First Question + Answer
            buildQuestionWithPopup(questionController1),
            const SizedBox(height: 10),
            buildTextField('Answer', answerController1, false),
            const SizedBox(height: 20),

            /// Second Question + Answer
            buildQuestionWithPopup(questionController2),
            const SizedBox(height: 10),
            buildTextField('Answer', answerController2, false),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                // Save logic here

                InsertUserPassword(
                    passwordController,
                    confirmPasswordController,
                    questionController1,
                    questionController2,
                    answerController1,
                    answerController2);
              },
              child: Text("Save"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds a regular or read-only text field
  Widget buildTextField(
      String label, TextEditingController controller, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        obscureText: false,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  /// Builds a read-only question field with a popup selector inside it
  Widget buildQuestionWithPopup(TextEditingController controller) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        buildTextField("Select Question", controller, true),
        Positioned(
          right: 12,
          child: PopupMenuButton<String>(
            icon: Icon(Icons.arrow_drop_down),
            onSelected: (value) {
              controller.text = value;
            },
            itemBuilder: (context) {
              return recoveryQuestions.map((question) {
                return PopupMenuItem<String>(
                  value: question,
                  child: Text(question),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  //Insert User Password
  void InsertUserPassword(
    TextEditingController passwordController,
    TextEditingController confirmPasswordController,
    TextEditingController questionController1,
    TextEditingController questionController2,
    TextEditingController answerController1,
    TextEditingController answerController2,
  ) {
    if (passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        questionController1.text.isEmpty ||
        questionController2.text.isEmpty ||
        answerController1.text.isEmpty ||
        answerController2.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please Fill all Fields")),
      );
    }
    else if(confirmPasswordController.text!=passwordController.text){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password and Confirm Password does not match ")));
    }
    else {

      Map<String ,dynamic>userPasswordDetails={
        "password":passwordController.text,
        "confirmpassword":confirmPasswordController.text,
        "question1":questionController1.text,
        "question2":questionController2.text,
        "answer1":answerController1.text,
        "answer2":answerController2.text,
      };
      final auth=AuthService();
      auth.SetPin(userPasswordDetails);
    }
  }
}
