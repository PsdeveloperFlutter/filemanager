import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager/FileManagement/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

import 'CreatePasswordScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _password =
      TextEditingController(); //Controller for password
  final TextEditingController question1 = TextEditingController();
  final TextEditingController question2 = TextEditingController();
  final TextEditingController enterPin = TextEditingController();
  bool? pinstatus;

  bool? biometricstatus;

  bool? isAppLockEnabled;

  final authService = AuthService(); // Create an instance of AuthService
  bool? Biometric;

  //This Function help to get value from isBiometricAvailable or not
  void getBiometricAvilablity() async {
    bool result = await authService.isBiometricTrulyAvailable();
    print('\n Biometric available ${result}');
    setState(() {
      Biometric = result;
    });
  }

  void getValueOfAppLock() async {
    bool result = await authService.isAppLockEnabled();
    print('\n AppLock available ${result}');
    setState(() {
      isAppLockEnabled = result;
    });
  }

  void pinFetch() async {
    String? result = await authService.GetPin();
    if (result != null) {
      pinstatus = true;
      print("Pin is Available $result");
    } else {
      print("Pin is Available $result");
      pinstatus = false;
    }
  }

  void loadBiometricToggle() async {
    bool enabled = await authService.isBiometricToggleEnabled();
    print("\n Biometric Stauts ${enabled}");
    setState(() => biometricstatus = enabled);
  }

// Fetch Biometric Availability

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
              ListTile(
                onTap: () async {
                  final pin = await authService.GetPin();
                  // Define `val` as a placeholder or pass it as a parameter
                  bool val = !(isAppLockEnabled ?? false);
                  final appLockEnabled = await authService.isAppLockEnabled();

                  // Case 1: PIN exists and app lock is enabled → verify user
                  if (pin != null && appLockEnabled == true) {
                    verifyUserPin(
                        context, enterPin, val); // your existing logic
                  }

                  // Case 2: PIN exists but app lock is disabled → just enable
                  else if (pin != null && appLockEnabled == false) {
                    if (val == true) {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PasswordScreen(passwordValue: "Set Password"),
                        ),
                      );

                      if (result == true) {
                        // User set password successfully
                        setState(() => isAppLockEnabled = true);
                        authService.setAppLockEnabled(true);
                      } else {
                        // User cancelled setting password → revert switch
                        setState(() => isAppLockEnabled = false);
                      }
                    } else {
                      // Toggling OFF when no password exists
                      setState(() => isAppLockEnabled = false);
                      authService.setAppLockEnabled(false);
                    }
                  }

                  // Case 3: No PIN set → navigate to password screen
                  else {
                    if (val == true) {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PasswordScreen(passwordValue: "Set Password"),
                        ),
                      );

                      if (result == true) {
                        // User set password successfully
                        setState(() => isAppLockEnabled = true);
                        authService.setAppLockEnabled(true);
                      } else {
                        // User cancelled setting password → revert switch
                        setState(() => isAppLockEnabled = false);
                      }
                    } else {
                      // Toggling OFF when no password exists
                      setState(() => isAppLockEnabled = false);
                      authService.setAppLockEnabled(false);
                    }
                  }
                },
                title: Text("Enable App Lock"),
                subtitle: Text("Set the App Lock Setting to Protect your app"),
                trailing: SizedBox(
                  width: 55,
                  child: FlutterSwitch(
                      width: 55.0,
                      height: 25.0,
                      valueFontSize: 12.0,
                      toggleSize: 18.0,
                      value: isAppLockEnabled ?? false,
                      borderRadius: 30.0,
                      padding: 4.0,
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey,
                      onToggle: (val) async {
                        final pin = await authService.GetPin();
                        final appLockEnabled =
                            await authService.isAppLockEnabled();

                        // Case 1: PIN exists and app lock is enabled → verify user
                        if (pin != null && appLockEnabled == true) {
                          verifyUserPin(
                              context, enterPin, val); // your existing logic
                        }

                        // Case 2: PIN exists but app lock is disabled → just enable
                        else if (pin != null && appLockEnabled == false) {
                          if (val == true) {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PasswordScreen(
                                    passwordValue: "Set Password"),
                              ),
                            );

                            if (result == true) {
                              // User set password successfully
                              setState(() => isAppLockEnabled = true);
                              authService.setAppLockEnabled(true);
                            } else {
                              // User cancelled setting password → revert switch
                              setState(() => isAppLockEnabled = false);
                            }
                          } else {
                            // Toggling OFF when no password exists
                            setState(() => isAppLockEnabled = false);
                            authService.setAppLockEnabled(false);
                          }
                        }

                        // Case 3: No PIN set → navigate to password screen
                        else {
                          if (val == true) {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PasswordScreen(
                                    passwordValue: "Set Password"),
                              ),
                            );

                            if (result == true) {
                              // User set password successfully
                              setState(() => isAppLockEnabled = true);
                              authService.setAppLockEnabled(true);
                            } else {
                              // User cancelled setting password → revert switch
                              setState(() => isAppLockEnabled = false);
                            }
                          } else {
                            // Toggling OFF when no password exists
                            setState(() => isAppLockEnabled = false);
                            authService.setAppLockEnabled(false);
                          }
                        }
                      }),
                ),
              ),
              ListTile(
                onTap: () {
                  passwordSetOrNot(context); //Check the Pin set or not
                },
                title: Text("Change Password"),
                subtitle: Text("Click to update your existing password"),
              ),
              Biometric == true
                  ? ListTile(
                      onTap: ()
                          //set the Functionality of the Toggle functionality
                          async {
                        if (await authService.isAppLockEnabled() == false) {
                          Flushbar(
                            message: "First Enable App Lock",
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.orange,
                            margin: EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(8),
                            icon: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                            ),
                          ).show(context);
                        } else {
                          bool newValue = !(biometricstatus ?? false);
                          bool result =
                              await authService.setBiometricToggle(newValue);
                          if (result) {
                            setState(() {
                              biometricstatus = newValue;
                            });
                          }
                        }
                      },
                      title: Text("Enable Biometric"),
                      subtitle:
                          Text("Click to enable your FingerPrint Verification"),
                      trailing: SizedBox(
                        width: 55,
                        child: FlutterSwitch(
                          width: 55.0,
                          height: 25.0,
                          valueFontSize: 12.0,
                          toggleSize: 18.0,
                          value: biometricstatus ?? false,
                          borderRadius: 30.0,
                          padding: 4.0,
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey,
                          onToggle: (val) async {
                            if (await authService.isAppLockEnabled() == false) {
                              Flushbar(
                                message: "First Enable App Lock",
                                duration: Duration(seconds: 3),
                                backgroundColor: Colors.orange,
                                margin: EdgeInsets.all(8),
                                borderRadius: BorderRadius.circular(8),
                                icon: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                ),
                              ).show(context);
                            } else {
                              bool result =
                                  await authService.setBiometricToggle(val);
                              if (result) {
                                setState(() {
                                  biometricstatus = val;
                                });
                              }
                            }
                          },
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

  void PasswordDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Password'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
            controller: _password,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  child: Text('Forget?'),
                  onPressed: () {
                    _password.clear();
                    Navigator.pop(context);
                    forgetPasswordDialogBox(
                        context); //Here we call the ForgetPasswordDialogBox function
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    _password.clear();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    validatePassword(context,
                        _password.text); //Check if password valid or not
                    _password.clear(); //Clear text Fields
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  } //PasswordDialogBox for Changing the password

  void forgetPasswordDialogBox(BuildContext context) async {
    final Map<String, dynamic> passwordData = await authService.GetPinDetails();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Forget Password"),
            contentPadding: EdgeInsets.all(10),
            content: Text(
                "Forget your Password? No issue just answer the security the security questions correctly and you can reset your password "),
            actions: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: TextField(
                  controller: question1,
                  decoration: InputDecoration(
                    labelText: passwordData['question1'],
                    hintText: passwordData['question1'],
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: TextField(
                  controller: question2,
                  decoration: InputDecoration(
                    labelText: passwordData['question2'],
                    hintText: passwordData['question2'],
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Cancel")),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        validateSecurityAnswers(context, question1, question2,
                            passwordData); //Here we call the validateSecurityAnswers function
                      },
                      child: Text("Ok"))
                ],
              )
            ],
          );
        });
  }

  //Validate the Security Answers
  void validateSecurityAnswers(
      BuildContext context,
      TextEditingController question1,
      TextEditingController question2,
      Map<String, dynamic> passwordData) {
    if (question1.text.isEmpty || question2.text.isEmpty) {
      Flushbar(
        message: "Please Answer Both Questions",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
        ),
      ).show(context);
    } else if (question1.text == passwordData['answer1'] &&
        question2.text == passwordData['answer2']) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordScreen(
          passwordValue: "Change password",
        );
      }));
    } else {
      Flushbar(
        message: "Wrong Answers",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          Icons.error_outline,
          color: Colors.white,
        ),
      ).show(context);
    }
    question1.clear();
    question2.clear();
  }

//Validate the Password
  Future<bool> validatePassword(BuildContext context, String text) async {
    final Map<String, dynamic> passwordData = await authService.GetPinDetails();
    if (passwordData['password'] == text) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordScreen(passwordValue: "Change Password");
      }));
      return true;
    } else if (text.isEmpty) {
      Flushbar(
        message: "Please Enter Password",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          Icons.error_outline,
          color: Colors.white,
        ),
      ).show(context);
      return false;
    } else {
      Flushbar(
        message: "Wrong Pin",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          Icons.error_outline,
          color: Colors.white,
        ),
      ).show(context);
    }
    _password.clear();
    return false;
  }

  //Check the Pin is set or not
  void passwordSetOrNot(BuildContext context) async {
    final pin = await authService.GetPin(); // Fetch the PIN using AuthService
    if (pin != null && pin.isNotEmpty) {
      // If the PIN is set, show the password dialog box
      PasswordDialogBox(context);
    } else {
      Flushbar(
        message: "First Set Pin",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          Icons.pin,
          color: Colors.white,
        ),
      ).show(context);
    }
  }

  //This is for the Verification of the UserPin
  Future verifyUserPin(
      BuildContext context, TextEditingController enterPin, dynamic val) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Enter Pin"),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: enterPin,
                  decoration: InputDecoration(
                    hintText: "Enter Pin",
                    labelText: "Enter Pin",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton(onPressed: (){
                    forgetPasswordDialogBox(context);
                  }, child: Text("Forget")),
                  TextButton(
                      onPressed: () {
                        enterPin.clear();
                        Navigator.pop(context);
                      },
                      child: Text("Cancel")),
                  TextButton(
                      onPressed: () async {
                        if (enterPin.text.isEmpty) {
                          Flushbar(
                            message: "Please Enter Pin",
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.redAccent,
                            margin: EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(8),
                            icon: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                          ).show(context);
                          return;
                        }
                        String? result = await authService.GetPin();
                        if (result == enterPin.text.toString()) {
                          setState(() {
                            isAppLockEnabled = val;
                          });
                          authService
                              .setAppLockEnabled(isAppLockEnabled ?? false);
                          //This Below Code Help to disable Biometric with App Lock
                          if (!isAppLockEnabled!) {
                            setState(() {
                              biometricstatus = false;
                            });
                            authService.setBiometricToggle(false);
                          }
                          enterPin.clear();
                          Navigator.pop(context);
                        } else {
                          Flushbar(
                            message: "Wrong Pin",
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.orange,
                            margin: EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(8),
                            icon: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                            ),
                          ).show(context);
                        }
                        enterPin.clear();
                      },
                      child: Text("Verify")),
                ],
              )
            ],
          );
        });
  }
}
