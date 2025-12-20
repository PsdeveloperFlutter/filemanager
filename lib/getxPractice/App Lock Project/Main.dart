import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../FileManagement/appLockUi/LockScreen.dart';
import 'homescreen.dart';
import 'lockController.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final lockController = Get.put(LockController());
  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Lock Demo',
      home: lockController.islocked.value
          ? LockScreen()
          : HomeScreen(),
    ));
  }
}
