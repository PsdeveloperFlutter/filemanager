import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../projectSetting/AuthService.dart';

class PasswordScreen extends StatefulWidget {
  final String passwordValue;

  PasswordScreen({required this.passwordValue});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  // Controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController answerController1 = TextEditingController();
  final TextEditingController answerController2 = TextEditingController();
  bool _isPasswordObscured = true; // Initially, the password is hidden
  bool _isConfirmPasswordObscured =
      true; // Initially, confirm password is hidden
  final FocusNode _answerFocusNode1 = FocusNode();
  final FocusNode _answerFocusNode2 = FocusNode();
  final List<String> recoveryQuestions = [
    "What is your mother's maiden name?",
    "What was the name of your first pet?",
    "What is your favorite food?",
    "What city were you born in?",
    "What is your father's middle name?",
    "What was your childhood nickname?",
  ];

  String selectedQuestion1 = "";
  String selectedQuestion2 = "";

  @override
  void initState() {
    super.initState();
    selectedQuestion1 = recoveryQuestions[0];
    selectedQuestion2 = recoveryQuestions[1];
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    answerController1.dispose();
    answerController2.dispose();
    _answerFocusNode1.dispose();
    _answerFocusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.passwordValue),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            icon: Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            buildTextField('Enter 4 digit Password', passwordController, false,
                true, false, _isPasswordObscured, true, () {
              setState(() {
                _isPasswordObscured = !_isPasswordObscured;
              });
            }, FocusNode()), // Added FocusNode for password field
            buildTextField('Confirm Password', confirmPasswordController, false,
                true, false, _isConfirmPasswordObscured, true, () {
              setState(() {
                _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
              });
            }, FocusNode()), // Added FocusNode for confirm password field
            const SizedBox(height: 30),
            Text("Security Questions",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "These questions will help you when you forget your password. All your security answers will be encrypted and stored only on the local device.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 18),
            // First Question + Answer
            QuestionSelector(
              label: "Select Question 1",
              questions: recoveryQuestions,
              selectedQuestion: selectedQuestion1,
              onChanged: (q) {
                setState(() {
                  selectedQuestion1 = q;
                });
                FocusScope.of(context).requestFocus(
                    _answerFocusNode1); // Focus on the answer field when question is selected
              },
            ),
            const SizedBox(height: 10),
            buildTextField(
                'Answer',
                answerController1,
                false,
                false,
                true,
                false,
                false,
                null,
                _answerFocusNode1), // Use the FocusNode for the answer field
            const SizedBox(height: 20),
            // Second Question + Answer
            QuestionSelector(
              label: "Select Question 2",
              questions: recoveryQuestions,
              selectedQuestion: selectedQuestion2,
              onChanged: (q) {
                setState(() {
                  selectedQuestion2 = q;
                });
                FocusScope.of(context).requestFocus(_answerFocusNode2);
              },
            ),
            const SizedBox(height: 10),
            buildTextField('Answer', answerController2, false, false, true,
                false, false, null, _answerFocusNode2),
            const SizedBox(height: 30),
            Container(
              width: 340,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(Colors.orangeAccent.shade200),
                ),
                onPressed: () {
                  InsertUserPassword();
                },
                child: Text(
                  "Save",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds a regular or read-only text field
  Widget buildTextField(
      String label,
      TextEditingController controller,
      bool readOnly,
      bool isNumber,
      bool isAnswer,
      bool obscure,
      bool showSuffixIcon, // New parameter
      VoidCallback? onSuffixIconTap, // Made nullable to match usage
      FocusNode? focusNode // New parameter for FocusNode
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        focusNode: focusNode, // Prevents focus on the field
        maxLength: isAnswer ? 100 : 4,
        textAlign: TextAlign.left,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        controller: controller,
        readOnly: readOnly,
        obscureText: obscure,
        obscuringCharacter: "*",
        decoration: InputDecoration(
          // Conditionally show the suffixIcon
          suffixIcon: showSuffixIcon
              ? IconButton(
                  icon: Icon(
                    // Change icon based on the 'obscure' state
                    obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onSuffixIconTap, // Call this function when tapped
                )
              : null,
          focusColor: Colors.grey.shade200,
          fillColor: Colors.green,
          // You might want to make this dynamic or remove if not needed for all fields
          labelText: label,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.grey),
            gapPadding: 10,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.grey),
              gapPadding: 10),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.grey),
              gapPadding: 10),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  // Insert User Password
  void InsertUserPassword() {
    if (passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        selectedQuestion1.isEmpty ||
        selectedQuestion2.isEmpty ||
        answerController1.text.isEmpty ||
        answerController2.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please Fill all Fields")),
      );
    } else if (confirmPasswordController.text != passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Password and Confirm Password does not match ")));
    } else {
      Map<String, dynamic> userPasswordDetails = {
        "password": passwordController.text.trim(),
        "confirmpassword": confirmPasswordController.text.trim(),
        "question1": selectedQuestion1.trim(),
        "question2": selectedQuestion2.trim(),
        "answer1": answerController1.text.trim(),
        "answer2": answerController2.text.trim(),
      };
      final auth = AuthService();
      auth.SetPin(userPasswordDetails);
      Flushbar(
        title: "Successfully",
        message: "Pin Set Successfully",
        duration: Duration(seconds: 2),
        icon: Icon(Icons.check, color: Colors.black),
        backgroundColor: Colors.orangeAccent,
      ).show(context).then((value) =>
          Navigator.pop(context, true)); //Navigate to Previous Screen
    }
  }
}

//This Class for Question Selection
class QuestionSelector extends StatelessWidget {
  final String label;
  final List<String> questions;
  final String selectedQuestion;
  final ValueChanged<String> onChanged;

  const QuestionSelector({
    Key? key,
    required this.label,
    required this.questions,
    required this.selectedQuestion,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset position = box.localToGlobal(Offset.zero);
        final selected = await showMenu<String>(
          context: context,
          // Dynamically position the menu under the field
          position: RelativeRect.fromLTRB(
            position.dx,
            position.dy + box.size.height,
            position.dx + box.size.width,
            position.dy,
          ),
          items: questions
              .map(
                (q) => PopupMenuItem<String>(
                  value: q,
                  child: Text(
                    q,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          color: Colors.grey[800],
        );
        if (selected != null) onChanged(selected);
      },
      child: AbsorbPointer(
        child: TextField(
          controller: TextEditingController(text: selectedQuestion),
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: "Select Question",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade200,
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          style: TextStyle(
            color: selectedQuestion.isEmpty ? Colors.grey : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
