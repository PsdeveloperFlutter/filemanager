import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../projectSetting/AuthService.dart';

class uiUtility {
  AuthService authService = AuthService();

  passwordDialogBox(
      BuildContext context,
      AuthService authService,
      TextEditingController pinController,
      String pin,
      TextEditingController question1,
      TextEditingController question2) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.all(20),
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            alignment: Alignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            backgroundColor: Colors.white,
            elevation: 5,
            content: Text(
              "Verify your PIN",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            title: Text(
              "Verify PIN",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.blueAccent,
              ),
            ),
            actions: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: "Enter your PIN",
                  hintText: "Enter your PIN",
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(90, 40),
                        backgroundColor: Colors.blue.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                        elevation: 0,
                      ),
                      onPressed: () {
                        authService.forgetPasswordDialogBox(
                            context, authService, question1, question2);
                      },
                      child: Text(
                        "Forget",
                        style: TextStyle(color: Colors.white),
                      )),
                  ElevatedButton(
                    onPressed: () {
                      pinController.clear();
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
                  ElevatedButton(
                    onPressed: () {
                      if (pinController.text == pin) {
                        flushBars(
                            'Pin Verified',
                            'Your PIN is verified successfully',
                            Colors.green,
                            context);

                        Future.delayed(Duration(seconds: 4), () {
                          pinController.clear();
                          Navigator.pop(context);
                        });
                      } else if (pinController.text.isEmpty ||
                          pinController.text.length < 4) {
                        flushBars("Invalid Pin", "Please enter four digit pin",
                            Colors.red, context);
                      } else {
                        flushBars(
                            'Incorrect Pin',
                            'The entered PIN is incorrect',
                            Colors.red,
                            context);
                      }
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
        });
  }

  //This is for the FlushBar
  Future flushBarWidget(String message, BuildContext context, iconsValue) {
    return Flushbar(
        message: message,
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          iconsValue,
          color: Colors.white,
        )).show(context);
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
      borderRadius: BorderRadius.circular(8),
      title: title,
      message: message,
      duration: Duration(seconds: 3),
      backgroundColor: color,
      flushbarPosition: FlushbarPosition.TOP,
    )..show(context);
  }


// Function to show the bottom sheet for biometric authentication when user select option of biometric authentication

  Future showBottomSheets(BuildContext context) {
    if (Platform.isIOS) {
      /// ✅ Cupertino ActionSheet for iOS
      return showCupertinoModalPopup(
        context: context,
        builder: (BuildContext bottomSheetContext) {
          return CupertinoActionSheet(
            title: Text('Unlock Doc Scanner'),
            message: Text('Use fingerprint or DocScanner password.'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () async {
                  AuthService authService = AuthService();
                  bool isAuthenticated =
                  await authService.authenticateWithBiometric();

                  if (isAuthenticated) {
                    Navigator.of(bottomSheetContext).pop();
                    debugPrint("Fingerprint Authentication Successful");
                  } else {
                    debugPrint("Fingerprint Authentication Failed");
                  }
                },
                child: Icon(
                  CupertinoIcons.lock_shield,
                  size: 40,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  AuthService authService = AuthService();
                  bool isAuthenticated =
                  await authService.authenticateWithPinOrPattern();

                  if (isAuthenticated) {
                    Navigator.of(bottomSheetContext).pop();
                    debugPrint("Pin/Password Authentication Successful");
                  } else {
                    debugPrint("Pin/Password Authentication Failed");
                  }
                },
                child: Text("USE PASSWORD"),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(bottomSheetContext).pop(),
              child: Text('Cancel'),
            ),
          );
        },
      );
    } else {
      /// ✅ Material BottomSheet for Android
      return showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        enableDrag: false,
        builder: (BuildContext bottomSheetContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 300,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Unlock Doc Scanner",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text("Use fingerprint or DocScanner password."),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () async {
                      AuthService authService = AuthService();
                      bool isAuthenticated =
                      await authService.authenticateWithBiometric();

                      if (isAuthenticated) {
                        Navigator.of(bottomSheetContext).pop();
                        debugPrint("Fingerprint Authentication Successful");
                      } else {
                        debugPrint("Fingerprint Authentication Failed");
                      }
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.fingerprint,
                          size: 55,
                          color: Colors.blue.shade500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  GestureDetector(
                    onTap: () async {
                      AuthService authService = AuthService();
                      bool isAuthenticated =
                      await authService.authenticateWithPinOrPattern();

                      if (isAuthenticated) {
                        Navigator.of(bottomSheetContext).pop();
                        debugPrint("Pin/Password Authentication Successful");
                      } else {
                        debugPrint("Pin/Password Authentication Failed");
                      }
                    },
                    child: Text(
                      "USE PASSWORD",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

}
