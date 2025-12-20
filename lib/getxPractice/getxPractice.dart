import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(GetMaterialApp(
    home: HomeScreen(),
  ));
}

/// ✅ GetX Controller
class MyController extends GetxController {
  var count = 0.obs;
  var name = ''.obs;
  var searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // 🔹 ever(): हर बार जब count बदले
    ever(count, (val) {
      print("👉 ever: Count बदला: $val");
    });

    // 🔹 once(): केवल पहली बार जब name बदले
    once(name, (val) {
      print("👉 once: Name पहली बार बदला गया: $val");
    });

    // 🔹 debounce(): जब user typing रोक दे
    debounce(searchText, (val) {
      print("👉 debounce: सर्च API कॉल: $val");
    }, time: Duration(seconds: 1));
  }

  void increment() => count++;
  void changeName(String newName) => name.value = newName;
  void updateSearch(String text) => searchText.value = text;
}

/// ✅ HomeScreen (Main Screen)
class HomeScreen extends StatelessWidget {
  final MyController controller = Get.put(MyController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GetX Demo - ever, once, debounce')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Counter Example (ever)
            Obx(() => Text(
              "Count: ${controller.count}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            )),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: controller.increment,
              child: const Text("Increment Count"),
            ),

            const Divider(height: 30),

            /// 🔹 Name Example (once)
            TextField(
              decoration: const InputDecoration(
                labelText: "Enter your name (once example)",
              ),
              onChanged: controller.changeName,
            ),

            const Divider(height: 30),

            /// 🔹 Search Example (debounce)
            TextField(
              decoration: const InputDecoration(
                labelText: "Search something (debounce example)",
              ),
              onChanged: controller.updateSearch,
            ),

            const SizedBox(height: 20),

            Obx(() => Text(
              "Current search: ${controller.searchText}",
              style: TextStyle(fontSize: 18),
            )),
          ],
        ),
      ),
    );
  }
}
