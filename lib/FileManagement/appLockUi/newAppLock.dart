import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager/FileManagement/appLockUi/appLockScreen.dart';
import 'package:flutter/material.dart';

import '../projectSetting/AuthService.dart';

AuthService objAuth = AuthService();

class NewAppLock extends StatefulWidget {
  const NewAppLock({super.key});

  @override
  State<NewAppLock> createState() => _NewAppLockState();
}

class _NewAppLockState extends State<NewAppLock> {
  bool biometricAvailable = false; // Biometric or PIN available
  bool isAppLockEnabled = false;

  /// Function to check saved app lock state
  Future<void> isAppLockEnabledOrNot() async {
    isAppLockEnabled = await objAuth.isAppLockEnabled();
    setState(() {});
    debugPrint("\n App Lock Enabled (from storage): $isAppLockEnabled");
  }

  /// Function to check biometric + PIN availability
  Future<void> fetchBiometricAvailability() async {
    biometricAvailable = await objAuth.isBiometricTrulyAvailableOrNot();
    setState(() {}); // refresh UI after checking
    debugPrint(
        "\n Secure Lock Available (Biometric or PIN): $biometricAvailable");
  }

  @override
  void initState() {
    super.initState();
    fetchBiometricAvailability();
    isAppLockEnabledOrNot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New App Lock Screen"),
      ),
      body: Column(
        children: [
          Card(
            color: biometricAvailable ? Colors.white : Colors.grey.shade100,
            elevation: 1,
            child: SwitchListTile(
              title: const Text("App Lock"),
              subtitle:
              const Text("This app lock works with Biometric or Screen Lock"),
              value: isAppLockEnabled,
              onChanged: (bool value) async {
                if (!biometricAvailable) {
                  // ❌ No security available at all
                  Flushbar(
                    title: "No Security Found",
                    message:
                    "Please set PIN/Password or enable Biometric in your device settings.",
                    duration: const Duration(seconds: 3),
                    flushbarPosition: FlushbarPosition.BOTTOM,
                    backgroundColor: Colors.red,
                  ).show(context);

                  setState(() {
                    isAppLockEnabled = false;
                  });
                  await objAuth.setAppLockEnabled(false);
                  objAuth.setPrivacyLockOption("false");
                  return;
                }

                if (value == true) {
                  // ✅ Ask authentication before enabling
                  final bool success = await objAuth.authenticateWithBiometric();
                  if (success) {
                    setState(() {
                      isAppLockEnabled = true;
                    });
                    await objAuth.setAppLockEnabled(true);
                    objAuth.setPrivacyLockOption("true");

                    debugPrint("App Lock Enabled ✅");
                  } else {
                    // ❌ Authentication failed
                    setState(() {
                      isAppLockEnabled = false;
                    });
                    await objAuth.setAppLockEnabled(false);
                    objAuth.setPrivacyLockOption("false");

                    Flushbar(
                      title: "Authentication Failed",
                      message:
                      "Could not enable App Lock. Please try again with correct authentication.",
                      duration: const Duration(seconds: 3),
                      flushbarPosition: FlushbarPosition.BOTTOM,
                      backgroundColor: Colors.red,
                    ).show(context);
                  }
                } else {
                  // 🔓 Turning off App Lock
                  setState(() {
                    isAppLockEnabled = false;
                  });
                  await objAuth.setAppLockEnabled(false);
                  objAuth.setPrivacyLockOption("false");
                  debugPrint("App Lock Disabled ❌");

                  // cleanup
                  objAuth.getStoredLockOptionDelete();
                  await objAuth.resetPin();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
