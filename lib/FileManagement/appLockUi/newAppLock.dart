// Description: New App Lock Screen UI and some basic functionality with biometric and passcode options
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../projectSetting/AuthService.dart';

AuthService objAuth = AuthService();

class newAppLock extends StatefulWidget {
  const newAppLock({super.key});

  @override
  State<newAppLock> createState() => _newAppLockState();
}

class _newAppLockState extends State<newAppLock> {
  bool biometricAvailable = false;
  bool isAppLockEnabled = false;

  //Function to check the isApplockenabled or not
  void isAppLockEnabledOrNot() async {
    isAppLockEnabled = await objAuth.isAppLockEnabled();
    setState(() {}); // Update the UI after fetching the value
    debugPrint("\n App Lock Enabled: $isAppLockEnabled");
  }

  /// Function to check biometric availability
  fetchBiometricAvailability() async {
    biometricAvailable = await objAuth.isBiometricTrulyAvailable();
    debugPrint("\n Biometric Available: $biometricAvailable");
  }

  @override
  void initState() {
    super.initState();
    // You can add initialization code here if needed
    fetchBiometricAvailability(); // Check biometric availability on init
    isAppLockEnabledOrNot(); // Check if App Lock is enabled on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("New App Lock Screen"),
        ),
        body: Column(
          children: [
            Card(
              color: biometricAvailable ? Colors.white:Colors.grey.shade100,
              elevation: 1,
              child: SwitchListTile(
                title: Text("App Lock"),
                subtitle: Text("This app lock according to Screen Lock "),
                value: isAppLockEnabled,
                onChanged: (bool value) {
                  // Handle switch toggle
                  // Handle switch toggle
                  if (biometricAvailable == true) {
                    setState(() {
                      isAppLockEnabled = value;
                    });
                    // Prompt biometric authentication when enabling
                    objAuth.authenticateWithBiometric().whenComplete(() {
                      objAuth.setAppLockEnabled(
                          isAppLockEnabled); // Save the state using AuthService set AppLockEnabled to true
                      debugPrint("\n App Lock Enabled: $isAppLockEnabled");
                    });
                  } else {
                    Flushbar(
                      title: "Biometric Not Available",
                      message:
                          "Please enable biometric authentication in your device settings.",
                      duration: Duration(seconds: 3),
                      flushbarPosition: FlushbarPosition.BOTTOM,
                      backgroundColor: Colors.red,
                    ).show(context);
                    setState(() {
                      // Keep the switch off if biometric is not available
                      isAppLockEnabled = false;
                    });
                    objAuth.setAppLockEnabled(
                        isAppLockEnabled); // Save the state using AuthService set to false and set applockenabled to false
                  }
                },
              ),
            ),
          ],
        ));
  }
}

//isBiometricAvailable()
