import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

import '../appLockUi/appLockScreen.dart';
import '../projectSetting/AuthService.dart';

// Assuming you have an AuthService class for authentication
class privacyScreen extends StatefulWidget {
  const privacyScreen({super.key});

  @override
  State<privacyScreen> createState() => _privacyScreenState();
}

class _privacyScreenState extends State<privacyScreen> {
  bool isLocked = false; // Initial value for the switch
  dynamic lock_option = ' ';
  AuthService object =
      AuthService(); // Create the Object of the AuthService Class

  // Function to get the current value of the privacy lock option
  void getPrivacyLockValue() async {
    lock_option = await object.getStoredLockOption();
    debugPrint('\n Lock Option: $lock_option');
    final value = await object.getPrivacyLockOption() == 'true' ? true : false;
    setState(() {
      isLocked =value; // Update the switch state based on the stored value
    });
    debugPrint('\n Privacy Lock Value: $isLocked');
  }

  void initState() {
    super.initState();
    getPrivacyLockValue(); // Fetch the initial value when the screen loads
    seePin();
  }
  // Function to check if the pin is set or not
  bool seePin(){
    object.getPin().then((value){
      if(value=='true'){
       return true;
      }
      else {
        return false;
      }
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Privacy & Security',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          privacyListTitle(
            title: 'Enable app lock',
            leadingColor: Colors.blue,
            icon: Icons.lock,
            onTap: () {
              onTapFunction();
            },
            trialing: FlutterSwitch(
                width: 50.0,
                height: 30.0,
                valueFontSize: 12.0,
                toggleSize: 18.0,
                borderRadius: 30.0,
                padding: 4.0,
                activeColor: Colors.green,
                inactiveColor: Colors.grey,
                value: isLocked,
                onToggle: (val) {
                  // if(isLocked==true){
                  //   object.setPrivacyLockOption('false');
                  //   setState(() {
                  //     isLocked = false;
                  //   });
                  //   object.resetPin(); // Reset the pin when disabling the lock
                  // }
                  // else{
                  //   onTapFunction();
                  // }
                  if(isLocked==false){
                    onTapFunction();
                  }
                  else if(isLocked==true){
                    setState(() {
                      isLocked=val;
                    });
                    object.setPrivacyLockOption(isLocked? 'true' : 'false');
                    object.resetPin(); // Reset the pin when disabling the lock
                  }
                }),
            subtitle: 'Use your existing passcode to keep your app secure.',
          ),
          const SizedBox(height: 15),
          Visibility(
              visible:isLocked,
              child: Padding(
                padding: const EdgeInsets.only(left: 18.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return applock();
                    })).then((value) {
                      getPrivacyLockValue(); // Refresh the lock state after returning
                    });
                  },
                  child: Text(
                    'Manage your app lock',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ))
        ],
      ),
    );
  }

  // Function to handle the tap on the switch and Navigate to the app lock screen
  void onTapFunction() async {
    // setState(() {
    //   isLocked = !isLocked;
    // });
    // if (isLocked) {
    //   object.setPrivacyLockOption('true');
    // } else {
    //   object.setPrivacyLockOption('false');
    // }
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return applock();
    }));
    getPrivacyLockValue();
  }
}

//Privacy List Title Widget
class privacyListTitle extends StatelessWidget {
  final String title;
  final Color leadingColor;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trialing;
  final String? subtitle;

  const privacyListTitle(
      {super.key,
      required this.title,
      required this.leadingColor,
      required this.icon,
      required this.onTap,
      required this.trialing,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ListTile(
        leading: Icon(
          icon,
          color: leadingColor,
          size: 30,
        ),
        subtitle: Text(subtitle!, style: TextStyle(color: Colors.black)),
        title: Text(title, style: TextStyle(color: Colors.black)),
        onTap: onTap,
        trailing: SizedBox(width: 55, child: trialing),
      ),
    );
  }
}
