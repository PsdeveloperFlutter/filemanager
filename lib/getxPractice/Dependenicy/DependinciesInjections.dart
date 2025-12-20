import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ GetX Controller
class MyGetxController extends GetxController {
  var counter = 0.obs;

  void increment() {
    counter++;
  }
}

// ✅ Routes configuration
class Routes {
  static List<GetPage> routes = [
    GetPage(name: '/screen1', page: () => Screen1()),
    GetPage(name: '/screen2', page: () => Screen2()),
  ];
}

// ✅ Main Application
void main() {
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        Get.put(MyGetxController());
      }),
      getPages: Routes.routes,
      initialRoute: '/screen1',
    ),
  );
}

// ✅ Screen 1
class Screen1 extends StatelessWidget {
  final MyGetxController getxController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GetX Dependency Injection Example")),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GetX<MyGetxController>(
              builder: (controller) {
                return Text(
                  "Counter Value: ${controller.counter}",
                  style: const TextStyle(fontSize: 22),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.toNamed('/screen2'),
              child: const Text("Go to Screen 2"),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getxController.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ✅ Screen 2
class Screen2 extends StatelessWidget {
  final MyGetxController getxController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Screen 2 - Same Controller")),
      body: Center(
        child: Obx(() => Text(
          "Counter Value: ${getxController.counter}",
          style: const TextStyle(fontSize: 22),
        )),
      ),
    );
  }
}
