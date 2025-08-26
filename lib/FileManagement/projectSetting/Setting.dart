import 'package:filemanager/FileManagement/projectSetting/AuthService.dart';
import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

import '../createPasswordUi/CreatePasswordScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: settingpage(),
    );
  }
}

class settingpage extends StatefulWidget {
  @override
  _Mysettingpage createState() => _Mysettingpage();
}

class _Mysettingpage extends State<settingpage> {
  final TextEditingController _password =
      TextEditingController(); //Controller for password
  final TextEditingController question1 = TextEditingController();
  final TextEditingController question2 = TextEditingController();
  final TextEditingController enterPin = TextEditingController();

  // Non-nullable flags with sane defaults
  bool pinStatus = false;
  bool biometricStatus = false;
  bool isAppLockEnabled = false;
  bool biometricAvailable = false;

  final uiObject = uiUtility(); // Create an instance of uiUtility
  final authService = AuthService(); // Create an instance of AuthService

  //This Function help to get value from isBiometricAvailable or not
  void getBiometricAvilablity() async {
    bool result = await authService.isBiometricTrulyAvailable();
    print('\n Biometric available $result');
    setState(() {
      biometricAvailable = result;
    });
  }

// This Function help to get the Value of the AppLock
  void getValueOfAppLock() async {
    bool result = await authService.isAppLockEnabled();
    print('\n AppLock available $result');
    setState(() {
      isAppLockEnabled = result;
    });
  }

  //Fetch the Pin
  void pinFetch() async {
    String? result = await authService.getPin();
    if (result != null) {
      print("Pin is Available $result");
      setState(() {
        pinStatus = true;
      });
    } else {
      print("Pin is Available $result");
      setState(() {
        pinStatus = false;
      });
    }
  }

  //Load the Biometric Toggle
  void loadBiometricToggle() async {
    bool enabled = await authService.isBiometricToggleEnabled();
    print("\n Biometric Stauts $enabled");
    setState(() => biometricStatus = enabled);
  }

// Fetch Biometric Availability
  @override
  void initState() {
    super.initState();
    getBiometricAvilablity(); //Get the Availability Biometric
    getValueOfAppLock(); //Get the Value of the AppLock Availability
    pinFetch(); //Fetch the Pin
    loadBiometricToggle(); //Load the Biometric Toggle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Security Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 1,
                child: ListTile(
                  onTap: () async {
                    setPinFunctionality(
                        context); //set the Functionality of the Pin
                  },
                  title: Text("Enable App Lock"),
                  subtitle:
                      Text("Set the App Lock Setting to Protect your app"),
                  trailing: SizedBox(
                    width: 55,
                    child: FlutterSwitch(
                        width: 55.0,
                        height: 25.0,
                        valueFontSize: 12.0,
                        toggleSize: 18.0,
                        value: isAppLockEnabled,
                        borderRadius: 30.0,
                        padding: 4.0,
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey,
                        onToggle: (val) async {
                          enableAndDisableAppLock(val, context);
                        }),
                  ),
                ),
              ),
              Card(
                elevation: 1,
                child: ListTile(
                  onTap: () {
                    passwordSetOrNot(context); //Check the Pin set or not
                  },
                  title: Text("Change Password"),
                  subtitle: Text("Click to update your existing password"),
                ),
              ),
              biometricAvailable
                  ? Card(
                      elevation: 1,
                      child: ListTile(
                        onTap: () async {
                          //set the Functionality of the Toggle functionality
                          bool newValue = !biometricStatus;
                          enableBiometric(newValue);
                        },
                        title: Text("Enable Biometric"),
                        subtitle: Text(
                            "Click to enable your FingerPrint Verification"),
                        trailing: SizedBox(
                          width: 55,
                          child: FlutterSwitch(
                            width: 55.0,
                            height: 25.0,
                            valueFontSize: 12.0,
                            toggleSize: 18.0,
                            value: biometricStatus,
                            borderRadius: 30.0,
                            padding: 4.0,
                            activeColor: Colors.green,
                            inactiveColor: Colors.grey,
                            onToggle: (val) async {
                              //set the Functionality of the Toggle functionality
                              enableBiometric(val);
                            },
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

//This is Code For Password Dialog Box
  void PasswordDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          title: Text(
            'Enter Pin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.blueAccent,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: TextStyle(color: Colors.grey[700]),
                prefixIcon: Icon(Icons.lock_outline),
                fillColor: Colors.grey[200],
                filled: true,
                labelText: 'Pin',
              ),
              controller: _password,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () {
                    _password.clear();
                    Navigator.pop(context);
                    forgetPasswordDialogBox(context,
                        "change"); //Here we call the ForgetPasswordDialogBox function
                  },
                  child: Text('Forget?'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  onPressed: () {
                    _password.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    authService.validatePassword(
                        context,
                        _password.text,
                        _password,
                        isAppLockEnabled,
                        biometricStatus); //Check if password valid or not
                    _password.clear(); //Clear text Fields
                    Navigator.of(context).pop();
                  },
                  child: Text('Verify'),
                ),
              ],
            ),
          ],
        );
      },
    );
  } //PasswordDialogBox for Changing the password

  void forgetPasswordDialogBox(BuildContext context, String value) async {
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    question1.clear();
                    question2.clear();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: Text("Cancel"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    validateSecurityAnswers(
                        context, question1, question2, passwordData, value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                    elevation: 0,
                  ),
                  child: Text("OK"),
                ),
              ],
            )
          ],
        );
      },
    );
  }

//Validate the Security Answers
  Future<void> validateSecurityAnswers(
      BuildContext context,
      TextEditingController question1,
      TextEditingController question2,
      Map<String, dynamic> passwordData,
      String value) async {
    if (question1.text.isEmpty || question2.text.isEmpty) {
      uiObject.flushBarWidget(
          "Please Answer Both Questions", context, Icons.warning_amber_rounded);
    } else if (question1.text == passwordData['answer1'] &&
        question2.text == passwordData['answer2'] &&
        value == "enable") {
      question1.clear();
      question2.clear();
      await authService.resetPin();
      await authService.setAppLockEnabled(false);
      await authService.setBiometricToggle(false);
      authService.setPrivacyLockOption('false');
      setState(() {
        biometricStatus = false;
        isAppLockEnabled = false;
      });

      Navigator.pop(context);
    } else if (question1.text == passwordData['answer1'] &&
        question2.text == passwordData['answer2'] &&
        value == "change") {
      question1.clear();
      question2.clear();
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordScreen(
          passwordValue: "Change password",
        );
      }));
    }
    else if (question1.text != passwordData['answer1'] &&
        question2.text != passwordData['answer2']) {
      uiObject.flushBarWidget("Both Answers Wrong", context, Icons.error_outline);
    }
    else if (question1.text !=passwordData['answer1']){
      uiObject.flushBarWidget("First Answer Is Wrong", context, Icons.error_outline);
    }
    else if (question1.text !=passwordData['answer2']){
      uiObject.flushBarWidget("Second Answer Is Wrong", context, Icons.error_outline);
    }
    question1.clear();
    question2.clear();
  }

//Check the Pin is set or not
  void passwordSetOrNot(BuildContext context) async {
    final pin = await authService.getPin(); // Fetch the PIN using AuthService
    if (pin != null && pin.isNotEmpty) {
      // If the PIN is set, show the password dialog box
      PasswordDialogBox(context);
    } else {
      uiObject.flushBarWidget("First Set Pin", context, Icons.pin);
    }
  }

//This is for the Verification of the UserPin
  Future verifyUserPin(
      BuildContext context, TextEditingController enterPin, dynamic val) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Enter Pin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.blueAccent,
              ),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            elevation: 10,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: enterPin,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: "Enter Pin",
                    labelText: "Enter Pin",
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton(
                      onPressed: () {
                        forgetPasswordDialogBox(
                            context, "enable"); //For Forget Password
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Text("Forget")),
                  TextButton(
                      onPressed: () {
                        enterPin.clear();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Text("Cancel")),
                  TextButton(
                      onPressed: () async {
                        verifyPinLogic(val, context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                        elevation: 0,
                      ),
                      child: Text("Verify")),
                ],
              )
            ],
          );
        });
  }

//Set Pin Functionality and Pin Logic Here
  void setPinFunctionality(BuildContext context) async {
    final pin = await authService.getPin();
    // Define `val` as a placeholder or pass it as a parameter
    bool val = !isAppLockEnabled;
    final appLockEnabled = await authService.isAppLockEnabled();

    // Case 1: PIN exists and app lock is enabled → verify user (likely disabling)
    if (pin != null && appLockEnabled == true) {
      verifyUserPin(context, enterPin, val); // your existing logic
    }
    // Case 2: PIN exists but app lock is disabled → just enable
    else if (pin != null && appLockEnabled == false) {
      if (val == true) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(passwordValue: "Set Password"),
          ),
        );

        if (result == true) {
          // User set password successfully
          setState(() => isAppLockEnabled = true);
          await authService.setAppLockEnabled(true);
          authService.setPrivacyLockOption('true');
        } else {
          // User cancelled setting password → revert switch
          setState(() => isAppLockEnabled = false);
          authService.setPrivacyLockOption('false');
        }
      } else {
        // Toggling OFF when already disabled
        setState(() => isAppLockEnabled = false);
        await authService.setAppLockEnabled(false);
        authService.setPrivacyLockOption('false');
      }
    }
    // Case 3: No PIN set → navigate to password screen
    else {
      if (val == true) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(passwordValue: "Set Password"),
          ),
        );

        if (result == true) {
          // User set password successfully
          setState(() {
            isAppLockEnabled = true;
            biometricStatus = true;
          });
          await authService.setAppLockEnabled(true);
          await authService.setBiometricToggle(true);
          authService.setPrivacyLockOption('true');
        } else {
          // User cancelled setting password → revert switch
          setState(() {
            isAppLockEnabled = false;
            biometricStatus = false;
          });
          authService.setPrivacyLockOption('false');
        }
      } else {
        // Toggling OFF when no password exists
        setState(() {
          isAppLockEnabled = false;
          biometricStatus = false;
          pinStatus = false;
        });
        await authService.setAppLockEnabled(false);
        await authService.setBiometricToggle(false);
        authService.setPrivacyLockOption('false');
      }
    }
  }

  //This Code when the User Disable and Verfiy the Pin code and after that User pin will reset
  void verifyPinLogic(val, BuildContext context) async {
    if (enterPin.text.isEmpty) {
      uiObject.flushBarWidget("Please Enter Pin", context, Icons.error_outline);
      return;
    }
    String? result = await authService.getPin();
    if (result == enterPin.text.toString()) {
      setState(() {
        isAppLockEnabled = val;
        biometricStatus = val;
      });

      // DO NOT reset the PIN on disable (better UX)
      await authService.setAppLockEnabled(isAppLockEnabled);

      //This Below Code Help to disable Biometric with App Lock
      if (!isAppLockEnabled) {
        setState(() {
          biometricStatus = false;
        });
        await authService.setBiometricToggle(false);
        authService.setPrivacyLockOption('false');
      } else {
        authService.setPrivacyLockOption('true');
      }
      Navigator.pop(context); //For Navigate Back
    } else {
      uiObject.flushBarWidget(
          "Wrong Pin", context, Icons.warning_amber_rounded);
    }
    enterPin.clear();
  }

  //This Enable and Disable App Lock
  void enableAndDisableAppLock(bool val, BuildContext context) async {
    final pin = await authService.getPin();
    final appLockEnabled = await authService.isAppLockEnabled();

    // Case 1: PIN exists and app lock is enabled → verify user (likely disabling)
    if (pin != null && appLockEnabled == true) {
      verifyUserPin(
          context, enterPin, val); // verification handles privacy flag
      return;
    }

    // Case 2: PIN exists but app lock is disabled → enable
    else if (pin != null && appLockEnabled == false) {
      if (val == true) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(passwordValue: "Set Password"),
          ),
        );

        if (result == true) {
          // User set password successfully
          setState(() {
            isAppLockEnabled = true;
            biometricStatus = true;
          });
          await authService.setAppLockEnabled(true);
          await authService.setBiometricToggle(true);
          authService.setPrivacyLockOption('true');
        } else {
          // User cancelled setting password → revert switch
          setState(() {
            isAppLockEnabled = false;
            biometricStatus = false;
          });
          authService.setPrivacyLockOption('false');
        }
      } else {
        // Turning OFF while already disabled
        setState(() {
          isAppLockEnabled = false;
          biometricStatus = false;
        });
        await authService.setAppLockEnabled(false);
        await authService.setBiometricToggle(false);
        authService.setPrivacyLockOption('false');
      }
      return;
    }

    // Case 3: No PIN set → navigate to password screen if enabling
    else {
      if (val == true) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(passwordValue: "Set Password"),
          ),
        );

        if (result == true) {
          // User set password successfully
          setState(() {
            isAppLockEnabled = true;
            biometricStatus = true;
          });
          await authService.setAppLockEnabled(true);
          await authService.setBiometricToggle(true);
          authService.setPrivacyLockOption('true');
        } else {
          // User cancelled setting password → revert switch
          setState(() {
            isAppLockEnabled = false;
            biometricStatus = false;
          });
          authService.setPrivacyLockOption('false');
        }
      } else {
        // Toggling OFF when no password exists
        setState(() {
          isAppLockEnabled = false;
          biometricStatus = false;
        });
        await authService.setAppLockEnabled(false);
        await authService.setBiometricToggle(false);
        authService.setPrivacyLockOption('false');
      }
    }
  }

  //Enable Biometric
  void enableBiometric(bool val) async {
    if (await authService.isAppLockEnabled() == false) {
      uiObject.flushBarWidget(
          "First Enable App Lock", context, Icons.warning_amber_rounded);
    } else {
      bool result = await authService.setBiometricToggle(val);
      if (result) {
        setState(() {
          biometricStatus = val;
        });
      }
    }
  }
}
