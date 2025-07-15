import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager/FileManagement/CreatePasswordScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final _storage = FlutterSecureStorage();
  final _auth = LocalAuthentication();
  static const _localKey = "APP_LOCK_ENABLED";
  static const _biometricKey = "BIOMETRIC_ENABLED";

  //This Code is For set Pin
  Future<void> SetPin(Map<String, dynamic> pin) async {
    await _storage.write(key: "app_pin", value: pin['password']);
    String jsonString = jsonEncode(pin); //Convert the map to json format
    await _storage.write(
        key: "app_pin_details",
        value: jsonString); //store the jsonString to the flutter secure storage
    await _storage.write(key: _localKey, value: true.toString());
    print("\n $pin Pin set successfully $jsonString");
  }

  //This Code is For get Pin
  Future<String?> GetPin() async {
    return await _storage.read(key: "app_pin");
  }

  //This Code is For Check Pin
  Future<bool> VerifyPin(String pin) async {
    final StoredPin = await _storage.read(key: "app_pin");
    return StoredPin == pin;
  }

  //This Function help to ResetPin
  Future<bool> resetPin() async {
    await _storage.delete(key: "app_pin");
    return await _storage.read(key: "app_pin") == null ? true : false;
  }

  //This Code is For Get Pin Details from flutter secure storage
  Future<Map<String, dynamic>> GetPinDetails() async {
    final jsonString = await _storage.read(key: "app_pin_details");
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return {};
  }

  //This Code is For Check Biometric
  Future<bool> isBiometricAvailable() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
  }

  //This function for the biometric value
  Future<bool> isBiometricToggleEnabled() async {
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }

  Future<bool> setBiometricToggle(bool enable) async {
    if (enable) {
      bool isAvailable = await isBiometricAvailable();
      bool isTrulyAvailable = await isBiometricTrulyAvailable();
      if (isTrulyAvailable && isAvailable) {
        bool didAuthenticate = await authenticateWithBiometric();
        if (didAuthenticate) {
          await _storage.write(key: _biometricKey, value: 'true');
          print("Biometric enabled Via Toggle");
          return true;
        } else {
          print("User cancelled biometric auth");
          return false;
        }
      } else {
        print("Biometric not available or enrolled");
        return false;
      }
    } else {
      await _storage.write(key: _biometricKey, value: 'false');
      print("Biometric disabled via toggle");
      return true;
    }
  }

  //Ye wala function Explain karta hi ki biometric jo lagi hoi hai kya nhi
  Future<bool> isBiometricTrulyAvailable() async {
    final result = await _auth.getAvailableBiometrics();
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  //This code is for the authenticate with Biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      bool isAvailable = await _auth.canCheckBiometrics;
      bool isSupported = await _auth.isDeviceSupported();

      if (!isAvailable || !isSupported) {
        print("Biometric not available or not supported.");
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: "Authenticate to unlock the app",
        options: const AuthenticationOptions(
          biometricOnly: true, // ✅ No fallback to PIN and pattern and password
          stickyAuth: true, // ✅ Keep auth active across screens
          useErrorDialogs: true, // ✅ Show system dialogs if errors occur
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }

  //Siraf Pin and Password aur pattern ke liye authentication
  Future<bool> authenticateWithPinOrPattern() async {
    try {
      bool isAuthenticated = await _auth.authenticate(
          // Ye siraf PIN, pattern, ya password ke liye hai
          localizedReason:
              'Please authenticate using your device PIN, pattern, password ',
          options: const AuthenticationOptions(
            biometricOnly: false,
            // ✅ False rakhein taki sirf PIN, pattern, password chale
            useErrorDialogs: true,
            stickyAuth: false,
            sensitiveTransaction: false,
          ));
      return isAuthenticated;
    } catch (error) {
      debugPrint(" \n Error in authenticate with pin or pattern: $error");
      return false; // Agar koi error aaye to false return karein
    }
  }

  //This code is for the authenticate with all authentication methods Pin , pattern , face  or fingerprint
  Future<bool> allAuthenticationOfDevice() async {
    try {
      bool isAvailable =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!isAvailable) {
        // Device par koi bhi lock nahi hai
        return false;
      }
      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'App unlock karne ke liye authenticate karein',
        options: const AuthenticationOptions(
          biometricOnly: false,
          // False rakhein taki PIN, pattern, password bhi chale
          useErrorDialogs: true,
          // System dialogs dikhane ke liye
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint("Error in all authentication of device: $e");
      return false; // Agar koi error aaye to false return karein
    }
  }

  // Device par supported biometric types check karein
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }

  Future<void> printAvailableBiometrics() async {
    List<BiometricType> availableBiometrics = await getAvailableBiometrics();
    if (availableBiometrics.isEmpty) {
      print("No biometric types available on this device.");
    } else {
      print("Available biometric types: $availableBiometrics");
    }
  }

  //Check if the app is Enabled
  Future<bool> isAppLockEnabled() async {
    final isEnabled = await _storage.read(key: _localKey);
    return isEnabled == 'true';
  }

//Enable /Disable App Lock
  Future<void> setAppLockEnabled(bool value) async {
    print("\n Value of the Set App Lock Enabled $value");
    return _storage.write(key: _localKey, value: value.toString());
  }

  //This function is for fetching app lock value ScreenLock or pin

  Future<String?> getStoredLockOption() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'lock_option'); // 'screenLock' ya 'pin'
  }

// Function to show the bottom sheet for biometric authentication when user select option of biometric authentication
  Future showBottomSheets(context) {
    // `this.context` refers to the BuildContext of the _FileManagerScreenState
    // No need for casting if you're sure it's being called when the state is mounted.
    return showModalBottomSheet(
      context: context,
      // Use the State's context directly
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      builder: (BuildContext bottomSheetContext) {
        // Explicitly type the builder's context
        return WillPopScope(
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 300,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    "Unlock Doc Scanner",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text("Use fingerprint or DocScanner password."),
                  const SizedBox(height: 30),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        // अगर आप चाहते हैं कि आइकन पूरी जगह ले
                        shape: RoundedRectangleBorder(
                          //  <-- इसे बदलें
                          borderRadius: BorderRadius.circular(30), // गोल कोने
                          side: BorderSide(
                            // बॉर्डर
                            color: Colors.blue.shade500,
                            width: 2,
                          ),
                        ),
                      ),
                      onPressed: () {
                        AuthService authService = AuthService();
                        authService
                            .authenticateWithBiometric()
                            .then((value) => {
                                  if (value)
                                    {
                                      Navigator.of(bottomSheetContext).pop(),
                                      debugPrint(
                                          "\n Fingerprint Authentication Successful"),
                                    }
                                  else
                                    {
                                      debugPrint(
                                          "\n Fingerprint Authentication Failed"),
                                    }
                                });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.fingerprint,
                          size: 45,
                          color: Colors.blue.shade500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 56,
                  ),
                  GestureDetector(
                    onTap: () {
                      final AuthService authService = AuthService();
                      authService
                          .authenticateWithPinOrPattern()
                          .then((value) => {
                                if (value)
                                  {
                                    Navigator.of(bottomSheetContext).pop(),
                                    debugPrint(
                                        "\n Pattern and Pin , Password Authentication Successful"),
                                  }
                                else
                                  {
                                    debugPrint(
                                        "\n Pattern and Pin , Password Authentication Failed"),
                                  }
                              });
                    },
                    child: Text(
                      "USE PASSWORD",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade500),
                    ),
                  ),
                ],
              ),
            ),
            onWillPop: () async => false);
      },
    );
  }

// Function to validate security answers
  Future<void> validateSecurityAnswers(
    BuildContext context,
    TextEditingController question1,
    TextEditingController question2,
    Map<String, dynamic> passwordData,
  ) async {
    if (question1.text.isEmpty || question2.text.isEmpty) {
      flushBars("Please Answer Both Questions", "Both questions are required",
          Colors.red, context);
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
      flushBars("Wrong Answers", "Please try again", Colors.red, context);
    }
    question1.clear();
    question2.clear();
  }

  // Function to show flush bar
  Widget flushBars(
      String title, String message, Color color, BuildContext context) {
    return Flushbar(
      icon: Icon(
        Icons.info_outline,
        size: 28.0,
        color: Colors.white,
      ),
      flushbarStyle: FlushbarStyle.FLOATING,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      title: title,
      message: message,
      duration: Duration(seconds: 3),
      backgroundColor: color,
      flushbarPosition: FlushbarPosition.TOP,
    )..show(context);
  }
  // Function to show the forget password dialog box
  void forgetPasswordDialogBox(BuildContext context, AuthService _authService,
      TextEditingController question1, TextEditingController question2) async {
    final Map<String, dynamic> passwordData =
        await _authService.GetPinDetails();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          title: Text(
            "Forgot Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.blueAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Text(
                  "Forgot your password? No issue! Just answer the security questions correctly and you can reset your password.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: question1,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.question_answer_outlined),
                    labelText: passwordData['question1'],
                    hintText: passwordData['question1'],
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: question2,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.question_answer_outlined),
                    labelText: passwordData['question2'],
                    hintText: passwordData['question2'],
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    question1.clear();
                    question2.clear();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                    elevation: 0,
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    validateSecurityAnswers(
                        context, question1, question2, passwordData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                    elevation: 0,
                  ),
                  child: Text(
                    "OK",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
