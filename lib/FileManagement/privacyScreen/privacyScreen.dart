import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class privacyScreen extends StatefulWidget {
  const privacyScreen({super.key});

  @override
  State<privacyScreen> createState() => _privacyScreenState();
}

class _privacyScreenState extends State<privacyScreen> {
  bool isLocked = false;

  // Initial value for the switch
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          privacyListTitle(
            title: 'Enable app lock',
            leadingColor: Colors.blue,
            icon: Icons.lock,
            onTap: () {
              setState(() {
                isLocked = !isLocked;
              });
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
                  setState(() {
                    isLocked = val;
                  });
                }),
            subtitle: 'Use your existing passcode to keep your app secure.',
          )
        ],
      ),
    );
  }
}

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
        leading: Icon(icon, color: leadingColor,size: 30,),
        subtitle: Text(subtitle!, style: TextStyle(color: Colors.black)),
        title: Text(title, style: TextStyle(color: Colors.black)),
        onTap: onTap,
        trailing: SizedBox(width: 55, child: trialing),
      ),
    );
  }
}
