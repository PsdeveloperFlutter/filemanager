import 'package:filemanager/getxPractice/App%20Lock%20Project/lockController.dart';
import'package:flutter/material.dart';
import 'package:get/get.dart';

import 'SettingsScreen.dart';

class HomeScreen extends StatelessWidget{
  final lockController=Get.find<LockController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
        actions: [
          IconButton(
            icon:Icon(Icons.settings),
            onPressed: ()=>Get.to(()=>SettingsScreen()),
          )
        ],
      ),
      body: Center(


        child: Column(
          children: [
            Text(
              "Welcome to the Home Screen!",
              style: TextStyle(fontSize: 24),
            ),
            Text(
              lockController.islocked.value
                  ? '🔒 Locked'
                  : '🔓 Unlocked (App Running)',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: lockController.lock,
              child: const Text('Lock Now'),
            ),
          ],
        ),
      ),
    );
  }
}