import 'package:filemanager/fileBrowserController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'fileManageUi.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Await the permission request properly
  await requestPermission();

  // Register the controller after permission and bindings are handled
  Get.put(FileBrowserController()).loadThemeFromPrefs();
  Get.put(FileBrowserController()).loadLayoutFromPrefs();
  runApp(MyApp());
}
Future<void> requestPermission() async {
  var status = await Permission.manageExternalStorage.status;
  if (!status.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}
class MyApp extends StatelessWidget {
  MyApp({super.key});
  // This line is safe now since the controller is registered before runApp()
  final themeController = Get.find<FileBrowserController>();
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeController.themeMode,
      debugShowCheckedModeBanner: false,
      title: 'File Manager',
      home: FileBrowserScreen(),
    );
  }
}
