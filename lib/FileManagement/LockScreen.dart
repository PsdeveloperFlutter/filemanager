import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import 'AuthService.dart';
import 'CreatePasswordScreen.dart';
import 'MainFile.dart';

class LockScreen extends StatefulWidget {
  const LockScreen();

  @override
  State<LockScreen> createState() => _LookScreenState();
}

class _LookScreenState extends State<LockScreen> {
  final List<int> enteredPin = [];
  final _authService = AuthService();
  bool _authRunning = false;
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    checkBiometricAvailable(); // 🔍 check if supported
    tryBiometrics();
  }

  Future<void> checkBiometricAvailable() async {
    final available = await _authService.isBiometricTrulyAvailable();
    if (mounted) {
      setState(() {
        _showBiometricButton = available;
      });
    }
  }

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
      print('\n Biometric toggle is enabled: $available');
      if (available) {
        final success = await _authService.authenticateWithBiometric();
        if (success && mounted) {
          _goToApp(); // or reset PIN
        }
      }
    } catch (e) {
      print("Biometric error: $e");
    }

    _authRunning = false;
  }

  void onFingerprint() {
    tryBiometrics();
    print("Fingerprint tapped");
  }

  //For Verify Pin
  void verfiyPin() async {
    if (enteredPin.length != 4) {
      showFlushbar("PIN must be 4 digits", "Error", context);
      return;
    }
    try {
      int pin = int.parse(enteredPin.join());
      print("\n Entered PIN: $pin");
      final String? storedPinValue = await _authService.GetPin();

      if (storedPinValue == null || storedPinValue.isEmpty) {
        print("Stored PIN not found or is empty");
        showFlushbar("Error retrieving stored PIN", "Error", context);
        return;
      }

      final int storedPinInt = int.parse(storedPinValue);
      print("\n Stored PIN: $storedPinInt");

      if (pin == storedPinInt) {
        print("Pin Matched");
        _goToApp();
      } else {
        print("Pin Not Matched");
        showFlushbar("Pin Not Matched", "Error", context);
      }
    } catch (e) {
      print("Error during PIN verification: $e");
      showFlushbar(
          "An error occurred during PIN verification", "Error", context);
    }
  }

  void _handleResetPin(BuildContext context) async {
    final isAvailable = await _authService.isBiometricTrulyAvailable();
    if (!isAvailable) {
      showFlushbar("Biometric is not Available on this device .",
          "Not Available", context);
    }
    final success = await _authService.authenticateWithBiometric();
    if (success && mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => PasswordScreen(passwordValue: "Change Pin")),
      );
      print("\n Result will be true or false :- $result");
      Future.delayed(Duration(milliseconds: 1000), () {
        if (result == true) {
          showFlushbar("Pin Change Successfully ", "Success", context);
        } else {
          showFlushbar("Pin not Change ", "Unsuccessful", context);
        }
      });
    } else {
      showFlushbar("Biometric Authentication Failed", "Failed", context);
    }
  }

  void onKeyTap(int key) {
    // Implement key tap functionality
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin.add(key);
      });
    }
    print("Key $key tapped");
  }

  void onDelete() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin.removeLast();
      });
    }
    // Implement delete functionality
    print("Delete tapped");
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
                Text(
                  'Enter your current 4-digit Pincode',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 34),
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
                SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Handle forgot PIN
                  },
                  child: Text(
                    'Forgot your PIN?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
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
                      ...[
                        [1, 2, 3],
                        [4, 5, 6],
                        [7, 8, 9],
                        ['del', 0, 'finger']
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
                                } else if (item == 'finger') {
                                  return _KeypadButton(
                                      icon: Icons.fingerprint,
                                      onTap: onFingerprint);
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
                TextButton(
                  onPressed: () => _handleResetPin(context),
                  child: Text("Forgot PIN? Reset using biometrics"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
