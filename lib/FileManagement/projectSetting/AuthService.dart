import 'dart:convert';
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager/FileManagement/createPasswordUi/CreatePasswordScreen.dart';
import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart';

import '../mainFile/MainFile.dart';

void main() {
  AuthService obj = AuthService();
  obj.printAvailableBiometrics();
}
FileManagerScreenSubState fileObject=FileManagerScreenSubState();
uiUtility uiObject = uiUtility();
class AuthService {
  final _storage = FlutterSecureStorage();
  final _auth = LocalAuthentication();
  static const _localKey = "APP_LOCK_ENABLED";
  static const _biometricKey = "BIOMETRIC_ENABLED";

  //This Code is For set Pin
  Future<void> setPin(Map<String, dynamic> pin) async {
    await _storage.write(key: "app_pin", value: pin['password']);
    String jsonString = jsonEncode(pin); //Convert the map to json format
    await _storage.write(
        key: "app_pin_details",
        value: jsonString); //store the jsonString to the flutter secure storage
    await _storage.write(key: _localKey, value: true.toString());
    debugPrint("\n $pin Pin set successfully $jsonString");
  }

  //This Code is For Check Pin
  Future<bool> seePin() async {
    String? pin = await getPin();
    if(pin !=null && pin.isNotEmpty){
      return true;
    }
    else{
      return false;
    }
  }

  //This Code is For get Pin
  Future<String?> getPin() async {
    return await _storage.read(key: "app_pin");
  }

  //This Code is For Check Pin
  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: "app_pin");
    return storedPin == pin;
  }

  //This Function help to ResetPin
  Future<bool> resetPin() async {
    await _storage.delete(key: "app_pin");
    return await _storage.read(key: "app_pin") == null ? true : false;
  }

  //This Code is For Get Pin Details from flutter secure storage
  Future<Map<String, dynamic>> getPinDetails() async {
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
          debugPrint("Biometric enabled Via Toggle");
          return true;
        } else {
          debugPrint("User cancelled biometric auth");
          return false;
        }
      } else {
        debugPrint("Biometric not available or enrolled");
        return false;
      }
    } else {
      await _storage.write(key: _biometricKey, value: 'false');
      debugPrint("Biometric disabled via toggle");
      return true;
    }
  }

  //Ye walla function Explain kart hi ki biometric jo lag hoi hai kya nhi
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
      bool isAvailable = await isBiometricAvailable();
      bool isSupported = await isBiometricTrulyAvailable();

      if (!isAvailable || !isSupported) {
        debugPrint("Biometric not available or not supported.");
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
      debugPrint("Biometric error: $e");
      return false;
    }
  }

  //Sira Pin and Password aur pattern ke liye authentication
  Future<bool> authenticateWithPinOrPattern() async {
    try {
      bool isAuthenticated = await _auth.authenticate(
          // Ye sirrah PIN, pattern, ya password ke liye hai
          localizedReason:
              'Please authenticate using your device PIN, pattern, password ',
          options: const AuthenticationOptions(
            biometricOnly: false,
            // ✅ False rakhein taki sirf PIN, pattern, password chale
            useErrorDialogs: true,
            stickyAuth: true,
            sensitiveTransaction: false,
          ));
      return isAuthenticated;
    } catch (error) {
      debugPrint(" \n Error in authenticate with pin or pattern: $error");
      return false; // Agar koi error aaye to false return karein
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }

  // This function is to print the available biometric types
  Future<void> printAvailableBiometrics() async {
    List<BiometricType> availableBiometrics = await getAvailableBiometrics();
    if (availableBiometrics.isEmpty) {
      debugPrint("No biometric types available on this device.");
    } else {
      debugPrint("Available biometric types: $availableBiometrics");
    }
    debugPrint('\n ${availableBiometrics.contains(BiometricType.strong)}');
  }

  //Check if the app is Enabled
  Future<bool> isAppLockEnabled() async {
    final isEnabled = await _storage.read(key: _localKey);
    return isEnabled == 'true';
  }

  //Enable /Disable App Lock
  Future<void> setAppLockEnabled(bool value) async {
    debugPrint("\n Value of the Set App Lock Enabled $value");
    return _storage.write(key: _localKey, value: value.toString());
  }

  //This function is for fetching app lock value ScreenLock or pin
  Future<String?> getStoredLockOption() async {
    return await _storage.read(key: 'lock_option'); // 'screenLock' ya 'pin'
  }

  //This function is for the Setting the Privacy Lock Option
  void setPrivacyLockOption(String option) async {
    await _storage.write(key: 'privacy_lock_option', value: option);
    debugPrint(" \n Privacy Lock Option set to $option");
  }

  Future<String?> getPrivacyLockOption() async {
    return await _storage.read(key: 'privacy_lock_option');
  }

// Function to validate security answers
  Future<void> validateSecurityAnswers(
    BuildContext context,
    TextEditingController question1,
    TextEditingController question2,
    Map<String, dynamic> passwordData,
  ) async {
    if (question1.text.isEmpty || question2.text.isEmpty) {
      uiObject.flushBars("Please Answer Both Questions", "Both questions are required",
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
      uiObject.flushBars("Wrong Answers", "Please try again", Colors.red, context);
    }
    question1.clear();
    question2.clear();
  }

  //Function to show Enter Password Dialog Box for App Lock Screen

  // Function to show the forget password dialog box
  void forgetPasswordDialogBox(BuildContext context, AuthService authService,
      TextEditingController question1, TextEditingController question2) async {
    final Map<String, dynamic> passwordData = await authService.getPinDetails();

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


//Validate the Password
  Future<bool> validatePassword(
      BuildContext context,
      String text,
      TextEditingController password,
      bool isAppLockEnabled,
      bool biometricstatus) async {
    final Map<String, dynamic> passwordData = await getPinDetails();
    if (passwordData['password'] == text) {
      debugPrint('\n isAppLockEnabled $isAppLockEnabled');
      debugPrint('\n biometric status $biometricstatus');
      debugPrint('\n isAppLockEnabled $isAppLockEnabled');
      debugPrint('\n biometric status $biometricstatus');
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordScreen(passwordValue: "Change Password");
      }));

      return true;
    } else if (text.isEmpty) {
    uiObject.flushBarWidget("Please Enter Password", context, Icons.error_outline);
      return false;
    } else {
     uiObject.flushBarWidget("Wrong Pin", context, Icons.error_outline);
    }
    password.clear();
    return false;
  }

  //This Below Function is for the Moving of the File to the Folder
  Future<void> movesFileToFolder(
      List<FileSystemEntity> files,
      Directory targetFolder,
      BuildContext context,
      int len,
      Directory item

      ) async {
    for (final file in files) {
      try {
        final filename = basename(file.path);
        final newPath = join(targetFolder.path, filename);
        await file.rename(newPath);
        Flushbar(
          title: 'Successfully',
          message: len == 0
              ? '${len + 1} Document Move Successfully'
              : len == 1
              ? ' $len Document Move Successfully'
              : '$len Documents Move Successfully',
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orangeAccent,
          icon: Icon(
            Icons.check,
            color: Colors.black,
          ),
        ).show(context).then((_) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return FileManagerScreenSub(path: item.path);
          }));
        });
      } catch (e) {
        debugPrint("Error moving file: $e");
      }
    }

    fileObject.fetchFolderContent(); //For Refresh the Folder
  }


  //Code for Creating a Folder
  Future<void> createFolder(BuildContext context,path) async {
    TextEditingController folderNameController = TextEditingController();
    String? errorText; // For feedback inside the dialog
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                  title: Text("Create a New Folder"),
                  content: TextField(
                    controller: folderNameController,
                    decoration: InputDecoration(
                      hintText: "Enter Folder Name",
                      errorText: errorText,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        folderNameController.clear();
                        Navigator.of(context).pop();
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        String newFolderName =
                        folderNameController.text.trim();
                        if (newFolderName.isNotEmpty) {
                          final folder =
                          Directory("$path/$newFolderName");
                          if (!await folder.exists()) {
                            await folder.create();
                            fileObject.fetchFolderContent();
                            folderNameController.clear();
                            Navigator.of(context).pop();
                          } else {
                            uiObject.flushBars("Error", "Error Occur",
                                Colors.red, context);
                          }
                        }
                      },
                      child: Text("Create"),
                    )
                  ]));
        });
  }

}
