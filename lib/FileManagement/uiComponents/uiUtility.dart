import 'package:flutter/material.dart';

import '../projectSetting/AuthService.dart';

class uiUtility {
  // This class can be used
  AuthService authService = AuthService();
  passwordDialogBox(BuildContext context, AuthService authService,
      TextEditingController pinController, String pin,
      TextEditingController question1,TextEditingController question2) {
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
                        authService.forgetPasswordDialogBox(context, authService, question1, question2);
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
                        authService.flushBars(
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
                        authService.flushBars("Invalid Pin",
                            "Please enter four digit pin", Colors.red, context);
                      } else {
                        authService.flushBars(
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
}
