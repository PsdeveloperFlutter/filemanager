import'package:flutter/material.dart';
import'package:get/get.dart';

class Mycontroller extends GetxController
{
  var count=0.obs;
  void incerement(){
    count++;
  }
}

void main(){
  Get.put(Mycontroller());
  runApp(
    GetMaterialApp(
      home: MainScreen(),
    )
  );
}
class MainScreen extends StatelessWidget{
  final controller =Get.find<Mycontroller>();
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("GetX Binding Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GetX<Mycontroller>(
              builder:(controller){
                return Text(
                  "Count Value : ${controller.count}",
                  style: const TextStyle(fontSize: 22),
                );
              } ,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (){
                controller.incerement();
              },
              child: const Text("Incerement Count"),
            )
          ],
        ),
      ),
    );
  }


}