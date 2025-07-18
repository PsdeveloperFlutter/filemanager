import 'package:filemanager/FileManagement/createPasswordUi/CreatePasswordScreen.dart';
import 'package:filemanager/FileManagement/projectSetting/AuthService.dart';
import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: applock()));
}

class applock extends StatefulWidget {
  const applock({super.key});

  @override
  State<applock> createState() => _appLockState();
}

enum LockOption { screenLock, pin }

class _appLockState extends State<applock> {
  //Create instance of Flutter Local Storage
  final storage = FlutterSecureStorage();
  bool _visible = false; // Variable to control visibility of the widget
  bool _bioVisible =
      false; // Variable to control visibility of the biometric option
  final TextEditingController question1 = TextEditingController();
  final TextEditingController question2 = TextEditingController();
  final TextEditingController pinController =
      TextEditingController(); // Controller for the PIN input
  AuthService authService = AuthService();
  uiUtility uiobject = uiUtility();
  LockOption? _selectedOption = LockOption.screenLock;

  @override
  void initState() {
    super.initState();
    authService.printAvailableBiometrics();
    _loadStoredOption();
  }

  @override
  void dispose() {
    question1.dispose();
    question2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enable App Lock'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LockOptionTile(
            value: LockOption.screenLock,
            groupValue: _selectedOption,
            title: 'Use your screen lock',
            subtitle:
                'Use your existing PIN, pattern,\nface Id, or fingerprint',
            onChanged: (value) async {
              if (await authService.isBiometricTrulyAvailable() == true &&
                  await authService.isBiometricAvailable() == true) {
                debugPrint("\n Biometric is available");
                setState(() {
                  _selectedOption = value;
                  _visible = false;
                  _bioVisible = false;
                });
                debugPrint("\n Selected option is: $_bioVisible ");
                authService.showBottomSheets(
                    context); // Show the bottom sheet for biometric authentication
              } else {
                setState(() {
                  _bioVisible = true;
                });
                debugPrint("\n Selected option is: $_bioVisible ");
                debugPrint("\n Biometric is not available");
                authService.flushBars(
                    "Not Support",
                    "Check your Biometric and Pin Setting",
                    Colors.red,
                    context);
                return;
              }
            },
          ),
          sizedBoxs(10),
          Visibility(
            visible: _bioVisible,
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                "Biometric is not Set or Available",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          sizedBoxs(18),
          LockOptionTile(
            value: LockOption.pin,
            groupValue: _selectedOption,
            title: 'Use your 4-Digit PIN',
            subtitle: 'Use your 4-digit PIN to unlock',
            onChanged: (value) async {
              // Handle pin selection
              await handlePinSelection(context);
              // Update the selected option
              setState(() {
                _selectedOption = value;
              });
              showmethod().then((value) {
                if (value) {
                  setState(() {
                    _visible = true;
                  }); // Show the widget if pin is set
                } else {
                  setState(() {
                    _visible = false;
                  }); // Hide the widget if pin is not set
                }
              });
            },
          ),
          sizedBoxs(18),
          Visibility(
            visible: _visible,
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: GestureDetector(
                onTap: () {
                  passwordSetOrNot(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 15,
                        child: Icon(
                          size: 12,
                          Icons.question_mark_rounded,
                          color: Colors.blue,
                        )),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      "Did you forget pin?",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          sizedBoxs(18),
          Center(
            child: Container(
              width: 330,
              height: 50,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade500,
                      padding: EdgeInsets.all(10),
                      fixedSize: Size(330, 50),
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.yellow.shade50))),
                  onPressed: () async {
                    if (await storeOptions() == false) {
                      return;
                    }
                    authService.flushBars(
                        'App Lock Enabled',
                        'Your app lock settings have been saved successfully',
                        Colors.green,
                        context);
                    Future.delayed(Duration(seconds: 4), () {
                      Navigator.pop(context);
                    });
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )),
            ),
          )
        ],
      ),
    );
  }

  // Function to handle pin selection
  Future<void> handlePinSelection(BuildContext context) async {
    final String? pin = await authService.getPin();
    debugPrint("\n Pin is $pin");
    if (pin == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordScreen(
            passwordValue: 'Set Password',
          ),
        ),
      ).then((result) {
        if (result is bool) {
          debugPrint("\n Returned value is: $result");
          setState(() {
            _visible = result;
          });
          if (result) {
            authService.flushBars('Pin Set', 'Pin Set Successfully',
                Colors.orangeAccent, context);
          } else {
            authService.flushBars(
                'Not Set', 'Pin not set', Colors.red, context);
          }
        } else {
          debugPrint("\n Returned value is not a boolean");
        }
      });
    } else if (pin.isNotEmpty) {
      uiobject.passwordDialogBox(context, authService, pinController, pin);
    }
  }

  // Function for the space between the widgets
  Widget sizedBoxs(double height) {
    return SizedBox(
      height: height,
    );
  }

  // Function to show the password check it is available or not
  void passwordSetOrNot(BuildContext context) async {
    final pin = await authService.getPin(); // Fetch the PIN using AuthService
    if (pin != null && pin.isNotEmpty) {
      // If the PIN is set, show the password dialog box
      forgetPasswordDialogBox(context);
    } else {
      authService.flushBars(
          'No PIN Set', 'Please set a PIN first', Colors.red, context);
    }
  }

  void forgetPasswordDialogBox(BuildContext context) async {
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
                    authService.validateSecurityAnswers(
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

  Future<bool> storeOptions() async {
    if (_selectedOption?.name.toString() == 'pin' &&
        await authService.getPin() == null) {
      authService.flushBars(
          "Set a Pin", "Please set a pin to proceed", Colors.red, context);
      return false;
    }
    if (_selectedOption == null) {
      authService.flushBars("Select an Option",
          "Please select an option to proceed", Colors.red, context);
      return false;
    } else {
      await storage.write(key: 'lock_option', value: _selectedOption!.name);
      debugPrint("\n Lock option selected: ${_selectedOption!.name}");
      return true;
    }
  }

  // Function to check if the pin is set or not
  Future<bool> showmethod() async {
    if (await authService.getPin() != null) {
      return true;
    } else {
      return false;
    }
  }

  // Function to load the stored lock option
  void _loadStoredOption() async {
    final option = await authService.getStoredLockOption();
    debugPrint("\n Stored option is: $option");
    setState(() {
      if (option == 'pin') {
        _selectedOption = LockOption.pin;
        showmethod().then((value) {
          if (value) {
            setState(() {
              _visible = true; // Show the widget if pin is set
            });
          } else {
            setState(() {
              _visible = false; // Hide the widget if pin is not set
            });
          }
        });
      } else if (option == 'screenLock') {
        _selectedOption = LockOption.screenLock;
        // authService.showBottomSheets(context);
      } else {
        _selectedOption = null; // Default case if no option is stored
      }
    });
  }
}

//This is the Lock Radio option
class LockOptionTile extends StatelessWidget {
  final LockOption value;
  final LockOption? groupValue;
  final ValueChanged<LockOption?> onChanged;
  final String title;
  final String subtitle;

  LockOptionTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          shape: BoxShape.rectangle,
          border: Border.all(color: Colors.grey, width: 2),
        ),
        child: RadioListTile<LockOption>(
          controlAffinity: ListTileControlAffinity.trailing,
          value: value,
          groupValue: groupValue,
          title: Text(title),
          subtitle: Text(subtitle),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
