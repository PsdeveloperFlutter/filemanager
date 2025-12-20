import 'package:filemanager/getxPractice/App%20Lock%20Project/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
void main(){
  runApp(Navigation1());
}
class Navigation1 extends StatelessWidget{
  var backValue = ''.obs;
  @override
  Widget build(BuildContext context){

    return GetMaterialApp(
      getPages: [
        // Define your routes here
        GetPage(
          name: '/home',
          page:()=>Home(),
        ),
        GetPage(
          name:'/settings',
          page:()=>Settings(),
        )
      ],
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GetX Navigation Example'),
        ),
        body:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: () async {
                var result = await Get.toNamed('/home');
                backValue.value = result ?? 'Returned from Home with no data';
              }, child: Text("Go to Home Screen")),
              ElevatedButton(onPressed: (){
               Get.toNamed('/settings',arguments:"Hii I Priyanshu Satija doing Navigation using GetX");
              }, child: Text("Go to Settings Screen")),
              Obx(() => Text(backValue.value))
            ],
          ),
        ),
      ),
    );
  }
}

Widget Settings() {
  var args=Get.arguments;
  return Scaffold(
    appBar: AppBar(
      title: const Text('Settings Screen'),
    ),
    body: Center(
      child: Text('$args This is the Settings Screen'),
    ),
  );
}


Widget Home(){
  return Scaffold(
    appBar: AppBar(
      title: const Text('User Screen'),
    ),
    body: Center(
      child: Column(
        children: [
          const Text('This is the User Screen'),
          ElevatedButton(onPressed: (){
            Get.back(result: "Returning from User Screen");

          }, child: const Text("Go Back")),
        ],
      ),
    ),
  );
}
