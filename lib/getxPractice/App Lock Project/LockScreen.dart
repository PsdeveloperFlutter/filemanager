import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lockController.dart';
class LockScreen extends StatelessWidget{
  final LockController lockController = Get.find<LockController>();
  TextEditingController pinController=TextEditingController();
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Lock Screen"),
      ),
      body:Center(
        child:Column(
          children:[
            const Text("🔐 Enter 4-digit PIN", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller:pinController,
              maxLength: 4,
              keyboardType:TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: '****'),

            ),
            const SizedBox(height: 20,),
            ElevatedButton(onPressed: ()=>lockController.verifyPin(pinController.toString()),child: const Text("Unlock"),)

          ]
        )
      )
    );
  }
}