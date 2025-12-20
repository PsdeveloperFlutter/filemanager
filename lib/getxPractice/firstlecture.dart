import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: CounterApp(),
  ));
}

class FirstLecture extends GetxController {
  var count = 0.obs;

  int get counter => count.value;
  RxDouble sliderValue = 10.0.obs;

  //Change Slider Value
  void changeSlider(double value) {
    sliderValue.value = value;
    count.value=sliderValue.value~/1.1;
    update();
  }

  void increment() {
    count++;
    sliderValue.value=count.toDouble()*1.1;
    //update();
  }

  void decrement() {
    if (count > 0) {
      count--;
      sliderValue.value=count.toDouble()*1.1;
      //update();
    }
  }

  void reset() {
    count.value = 0;
    sliderValue.value=count.toDouble();
    update();
  }

  @override
  onInit() {
    super.onInit();
    print("First Lecture Controller Initialized");
  }

  @override
  onReady() {
    super.onReady();
    print("\n First Lecture Controller is Ready");
  }

  @override
  onClose() {
    super.onClose();
    print("\n First Lecture Controller is Closed");
  }
}

//use the getxcontroller in your flutter app to manage state of a counter with increment, decrement and reset functions.

class CounterApp extends StatelessWidget {
  final FirstLecture controller = Get.put(FirstLecture());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GetX Counter App"),
      ),
      body: Column(
        children: [
          GetX<FirstLecture>(builder: (controller) {
            return Slider(
              value: controller.sliderValue.value,
              onChanged: (value) => controller.changeSlider(value),
              min: 0,
              max: 1000,
            );
          }),
          SizedBox(
            height: 10,
          ),
          Center(
            child: GetX<FirstLecture>(builder: (controller) {
              return Text(
                "Counter Value: ${controller.counter}",
                style: TextStyle(fontSize: 24),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: controller.increment,
            child: Icon(Icons.add),
            heroTag: 'increment',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: controller.decrement,
            child: Icon(Icons.remove),
            heroTag: 'decrement',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: controller.reset,
            child: Icon(Icons.refresh),
            heroTag: 'reset',
          ),
        ],
      ),
    );
  }
}
