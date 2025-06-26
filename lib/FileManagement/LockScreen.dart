import 'package:flutter/material.dart';

import 'AuthService.dart';
import 'MainFile.dart';
import 'SetPinScreen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen();

  @override
  State<LockScreen> createState() => _LookScreenState();
}

class _LookScreenState extends State<LockScreen> {
  final _authService = AuthService();
  final TextEditingController _pinController = TextEditingController();
  String? errorText;
  bool _authRunning = false;
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    checkBiometricAvailable(); // 🔍 check if supported
    tryBiometrics();
  }

  Future<void> checkBiometricAvailable() async {
    final available = await _authService.isBiometricAvailable();
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
      final available = await _authService.isBiometricAvailable();
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

  //For Verify Pin
  void verfiyPin() async {
    final isVerified = await _authService.VerifyPin(_pinController.text);
    if (isVerified) {
      _goToApp();
    } else {
      setState(() {
        errorText = "Invalid Pin";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: EdgeInsets.all(30),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text("Enter App PIN", style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: "PIN", errorText: errorText),
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: verfiyPin,
                  child: Text("Unlock"),
                ),
                _showBiometricButton
                    ? TextButton(
                        onPressed: tryBiometrics,
                        child: Text("Try Face ID / Fingerprint"),
                      )
                    : SizedBox.shrink(),
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

  void _handleResetPin(BuildContext context) async {
    final isAvailable = await _authService.isBiometricAvailable();
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Biometric is not Available on this device .")),
      );
      return;
    }
    final success = await _authService.authenticateWithBiometric();
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>FileManagerScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Biometric Authentication Failed")));
    }
  }
}
