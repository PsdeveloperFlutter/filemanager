import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../../mainFile/MainFile.dart';
import '../createPasswordUi/CreatePasswordScreen.dart';
import '../projectSetting/AuthService.dart';

class LockScreen extends StatefulWidget {
  const LockScreen();

  @override
  State<LockScreen> createState() => _LookScreenState();
}

class _LookScreenState extends State<LockScreen> {
  final List<int> enteredPin = [];
  final _authService = AuthService();
  bool _authRunning = false;
  final TextEditingController question1 = TextEditingController();
  final TextEditingController question2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    //checkBiometricAvailable(); // 🔍 check if supported
    // tryBiometrics();
  }

  //
  // Future<void> checkBiometricAvailable() async {
  //   final available = await _authService.isBiometricTrulyAvailable();
  //   if (mounted) {
  //     setState(() {
  //       _showBiometricButton = available;
  //     });
  //   }
  // }

  void _goToApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => FileManagerScreen()),
    );
  }

  //tryBiometric Method
  Future<void> tryBiometrics() async {
    if (_authRunning || !mounted) return; // ✅ prevents overlapping calls
    _authRunning = true;

    try {
      final available = await _authService.isBiometricToggleEnabled();
      debugPrint('\n Biometric toggle is enabled: $available');
      if (available) {
        final success = await _authService.authenticateWithBiometric();
        if (success && mounted) {
          _goToApp(); // or reset PIN
        }
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
    }

    _authRunning = false;
  }

  //For Verify Pin
  void verfiyPin() async {
    if (enteredPin.length != 4) {
      showFlushbar("PIN must be 4 digits", "Error", context);
      return;
    }
    try {
      int pin = int.parse(enteredPin.join());
      debugPrint("\n Entered PIN: $pin");
      final String? storedPinValue = await _authService.getPin();

      if (storedPinValue == null || storedPinValue.isEmpty) {
        debugPrint("Stored PIN not found or is empty");
        showFlushbar("Error retrieving stored PIN", "Error", context);
        return;
      }

      final int storedPinInt = int.parse(storedPinValue);
      debugPrint("\n Stored PIN: $storedPinInt");

      if (pin == storedPinInt) {
        debugPrint("Pin Matched");
        _goToApp();
      } else {
        debugPrint("\n Pin Not Matched");
        setState(() {
          enteredPin.clear();
        }); // Clear the entered PIN
        showFlushbar("Pin Not Matched", "Error", context);
      }
    } catch (e) {
      debugPrint("Error during PIN verification: $e");
      showFlushbar(
          "An error occurred during PIN verification", "Error", context);
    }
  }

  void onKeyTap(int key) {
    // Implement key tap functionality
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin.add(key);
      });
    }
    debugPrint("Key $key tapped");
  }

  void onDelete() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin.removeLast();
      });
    }
    // Implement delete functionality
    debugPrint("Delete tapped");
  }

  void showFlushbar(String message, String title, BuildContext context) {
    Flushbar(
      backgroundColor: Colors.orangeAccent,
      message: message,
      title: title,
      duration: Duration(seconds: 3),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 50),
                Container(
                    width: 85,
                    // Set the desired width
                    height: 85,
                    // Set the desired height
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      // Light blue background
                      shape: BoxShape.rectangle, // Circular shape
                    ),
                    child: Image.asset('assets/images/logo.png',fit: BoxFit.cover,)),
                SizedBox(
                  height: 50,
                ),
                Text(
                  'Enter your current 4-digit Pin code',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    bool filled = index < enteredPin.length;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: filled ? Colors.black : Colors.transparent,
                        border: Border.all(color: Colors.black, width: 1.6),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(
                  height: 22,
                ),
                Container(
                  padding: const EdgeInsets.only(top: 5, bottom: 15),
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                              onPressed: enteredPin.length == 4
                                  ? () {
                                      verfiyPin();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[850],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Colors.grey[400],
                                disabledForegroundColor: Colors.grey[200],
                              ),
                              child: Text(
                                'NEXT',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.1),
                              )),
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      ...[
                        [1, 2, 3],
                        [4, 5, 6],
                        [7, 8, 9],
                        ['del', 0, ' ']
                      ].map((row) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceAround, // Add a comma here
                              children: row.map((item) {
                                // Add parentheses around item
                                if (item == 'del') {
                                  return _KeypadButton(
                                      icon: Icons.backspace_outlined,
                                      onTap: onDelete);
                                } else {
                                  return _KeypadButton(
                                    label: item.toString(),
                                    // Remove .toString here
                                    onTap: () => onKeyTap(item as int),
                                  ); // Remove .toList() here
                                }
                              }).toList(), // Add .toList() here
                            ),
                          ))
                    ],
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                TextButton(
                  onPressed: () => _authService.forgetPasswordDialogBox(
                      context, _authService, question1, question2),
                  child: Text("Forget PIN? Reset Password",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> validateSecurityAnswers(
    BuildContext context,
    TextEditingController question1,
    TextEditingController question2,
    Map<String, dynamic> passwordData,
  ) async {
    if (question1.text.isEmpty || question2.text.isEmpty) {
      _authService.flushBars("Please Answer Both Questions",
          "Both questions are required", Colors.red, context);
    } else if (question1.text == passwordData['answer1'] &&
        question2.text == passwordData['answer2']) {
      question1.clear();
      question2.clear();
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordScreen(
          passwordValue: "Change password",
        );
      }));
    } else {
      _authService.flushBars(
          "Wrong Answers", "Please try again", Colors.red, context);
    }
    question1.clear();
    question2.clear();
  }
}

//This is Class for the KeyBoard and del for finger
class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: 55,
          width: 30,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      size: 28,
                      color: Colors.blue,
                      weight: 500,
                    )
                  : Text(
                      label ?? '',
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
        ),
      ),
    ));
  }
}
