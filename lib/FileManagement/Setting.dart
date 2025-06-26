import 'package:filemanager/FileManagement/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:another_flushbar/flushbar.dart';
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
  bool status = false;
  bool isAppLockEnabled = false;
  final authService = AuthService(); // Create an instance of AuthService
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
              GestureDetector(
                onTap: (){
                  passwordSetOrNot(context );
                },
                child: ListTile(
                  trailing: SizedBox(
                    width: 55.0, // Set a fixed width for the switch
                    child: FlutterSwitch(
                      width: 55.0,
                      height: 25.0,
                      valueFontSize: 12.0,
                      toggleSize: 18.0,
                      value: status,
                      borderRadius: 30.0,
                      padding: 4.0,
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey,
                      onToggle: (val) {
                        setState(() {
                          status = val;
                        });
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return PasswordScreen();
                        }));
                      },
                    ),
                  ),
                  title: Text("Set Pin"),
                  subtitle: Text("Enable and disable Pin"),
                ),
              ),
              GestureDetector(
                onTap: () {
                  PasswordDialogBox(context); //Show the password dialog box
                },
                child: ListTile(
                  title: Text("Change Password"),
                  subtitle: Text("Click to update your existing password"),
                ),
              ),
              ListTile(
                title: Text("Enable Biometric"),
                subtitle: Text("Click to enable your FingerPrint Verification"),
                trailing: SizedBox(
                  width: 55,
                  child: FlutterSwitch(
                    width: 55.0,
                    height: 25.0,
                    valueFontSize: 12.0,
                    toggleSize: 18.0,
                    value: status,
                    borderRadius: 30.0,
                    padding: 4.0,
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                    onToggle: (val) {
                      setState(() {
                        status = val;
                      });
                    },
                  ),
                ),
              ),
              ListTile(
                title: Text("Enable App Lock"),
                subtitle: Text("Set the App Lock Setting to Protect your app"),
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
                    onToggle: (val) {
                      setState(() {
                        isAppLockEnabled = val;
                      });
                      final value =
                          authService.setAppLockEnabled(isAppLockEnabled);
                      print("\n ${value.toString()}");
                    },
                  ),
                ),
              )
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
                    Navigator.pop(context);
                    forgetPasswordDialogBox(
                        context); //Here we call the ForgetPasswordDialogBox function
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    validatePassword(context, _password.text);
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
        return PasswordScreen();
      }));
    }
    else{
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
  void validatePassword(BuildContext context, String text) async {
    final Map<String, dynamic> passwordData = await authService.GetPinDetails();
    if (passwordData['password'] == text) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordScreen();
      }));
    }
    else if(text.isEmpty){
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
    }
    else{
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
  }

  void passwordSetOrNot(BuildContext context) async {
    final pin = await authService.GetPin(); // Fetch the PIN using AuthService
    if (pin != null && pin.isNotEmpty) {
      // If the PIN is set, show the password dialog box
      PasswordDialogBox(context);
    } else {
      // If the PIN is not set, navigate directly to the Set Pin screen
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PasswordScreen();
      }));
    }
  }
}
