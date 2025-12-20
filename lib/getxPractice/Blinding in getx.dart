import 'package:flutter/material.dart';
import 'package:get/get.dart';

//GetX Controller
class AppController extends GetxController {
  var theme = 'Light'.obs;
}

//InitialBinding to put the controller

void main() {
  // ✅ ये dependency App start होते ही load हो जाएगी
  Get.put(AppController());
  runApp(GetMaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatelessWidget {
  final controller = Get.find<AppController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('GetX Initial Binding Example')),
        body: Center(
            child: Obx(() =>
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Current Theme: ${controller.theme.value}',
                      style: TextStyle(fontSize: 22)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Toggle theme value
                      controller.theme.value =
                          controller.theme.value == 'Light' ? 'Dark' : 'Light';
                    },
                    child: Text('Toggle Theme'),
                  )
                ]))));
  }
}
