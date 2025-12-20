//This is an example of using GetX for route binding in a Flutter application.

import'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController{
  var count=0.obs;
  void increment(){
    count++;
  }
}

//Bindings Class
class HomeBinding extends Bindings{
  @override
  void dependencies(){
    Get.lazyPut<HomeController>(()=>HomeController());
  }
}

void main(){
  runApp(
    GetMaterialApp(
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: ()=>HomeScreen(),binding: HomeBinding()),
      ],
    )
  );
}


class HomeScreen extends StatelessWidget{
  final controller =Get.find<HomeController>();
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("GetX Route Binding Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GetX<HomeController>(
              builder:(controller){
                return Text(
                  "Count Value : ${controller.count}",
                  style: const TextStyle(fontSize: 22),
                );
              }  ,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:(){
                controller.increment();
              },
              child: const Text("Increment Count"),
            )
          ],
        ),
      ),
    );
  }
}