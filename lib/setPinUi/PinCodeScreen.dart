import 'package:filemanager/FileManagement/projectSetting/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PinCodeScreen(),
  ));
}

class PinCodeScreen extends StatefulWidget {
  const PinCodeScreen({super.key});

  @override
  State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  final List<int> enteredPin = [];
  AuthService object=AuthService();//create the Object of the AuthService Class

  void onKeyTap(int value) {
    if (enteredPin.length < 5) {
      setState(() {
        enteredPin.add(value);
      });
    }
  }

  void onDelete() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin.removeLast();
      });
    }
  }

  void onFingerprint() {
    // TODO: Implement fingerprint authentication
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 150),
            Text(
              'Enter your current 4-digit Pincode',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 34),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool filled = index < enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: filled ? Colors.black : Colors.transparent,
                    border:
                        Border.all(color: Colors.blueGrey[300]!, width: 1.6),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                // TODO: Handle forgot PIN
              },
              child: Text(
                'Forgot your PIN?',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 5, bottom: 15),
              color: Colors.transparent,
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: enteredPin.length == 4
                            ? () {
                               verifyPin();//call for the Verify the Pin
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[850],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[800],
                          disabledForegroundColor: Colors.grey[400],
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, letterSpacing: 1.1),
                        ),
                      ),
                    ),
                  ),
                  // Keypad Numbers
                  ...[
                    [1, 2, 3],
                    [4, 5, 6],
                    [7, 8, 9],
                    ['del', 0, 'finger'],
                  ].map((row) => Padding(
                        padding: const EdgeInsets.symmetric(
                            // The `...` (spread operator) is used here to incorporate the elements of the list of lists (keypad layout) directly into the `children` list of the `Column` widget.
                            // This is important because it allows for a concise and readable way to define the keypad structure.
                            // Each inner list `[1, 2, 3]`, `[4, 5, 6]`, etc., represents a row of buttons on the keypad.
                            // The `.map((row) => ...)` then iterates over each of these rows to create a `Row` widget for each.
                            // Without the spread operator, you would have to manually add each `Padding` widget (representing a row) to the `children` list, making the code more verbose.
                            horizontal: 24, vertical: 4),
                        child: Row(

                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: row.map((item) {
                            if (item == 'del') {
                              return _KeypadButton(
                                icon: Icons.backspace_outlined,
                                onTap: onDelete, //Function call here of the On delete Print
                              );
                            } else if (item == 'finger') {
                              return _KeypadButton(
                                icon: Icons.fingerprint,
                                onTap: onFingerprint,//Function call here of the On Finger Print
                              );
                            } else {
                              return _KeypadButton(
                                label: item.toString(),
                                onTap: () => onKeyTap(item as int), //Function call here of the KeyBoard Type
                              );
                            }
                          }).toList(),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //This Code is for the Verify the Pin make sure of that
  void verifyPin() async{
    int pin=int.parse(enteredPin.join());
    print("\n Enter Pin :- $pin");
    final storePin=await object.GetPin();
    final int storePinInt=int.parse(storePin!);
    if(pin==storePinInt){
      print("\n Pin Matched $storePin");
      showFlushbar("Pin Matched","Success");
    }
    else{
      print("\n Pin Not Matched $storePin");
      showFlushbar("Pin Not Matched", "Unsuccess");
    }
  }

  void showFlushbar(String message, String title) {
    Flushbar(
      backgroundColor: Colors.orangeAccent,
      message:message,
      title: title,
      duration: Duration(seconds: 3),
    ).show(context);
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Container(
            height: 55,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 28, color: Colors.blue, weight: 500,) // Added a default weight
                  : Text(
                      label ?? '',
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
