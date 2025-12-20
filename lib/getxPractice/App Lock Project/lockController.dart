import'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ Controller for App Lock Functionality
class LockController extends GetxController with WidgetsBindingObserver{
  final islocked=false.obs;
  final isAppLocked=false.obs;
  final savedPin=''.obs;
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadLockState();
  }
  @override
  void onReady(){
    super.onReady();
    debugPrint("\n Lock Controller is Ready");
  }
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint("\n Lock Controller Closed");
    super.onClose();
  }
  //loadLockState from SharedPreferences
  Future<void>loadLockState()async{
    final prefs=await SharedPreferences.getInstance();
    isAppLocked.value=prefs.getBool('isAppLocked')??false;
    savedPin.value=prefs.getString('appPin')??'';
    if(isAppLocked.value && savedPin.value.isNotEmpty){
     //*****islocked value set true*****//;
      islocked.value=true;
    }
  }


  //set app lock
  Future<void>setAppLock(bool enable)async{
    final prefs=await SharedPreferences.getInstance();
    await prefs.setBool('isAppLocked', enable);
    isAppLocked.value=enable;
    if(!enable){
      islocked.value=false;
    }
    else {
      islocked.value=true;
    }
  }

  //set app Pin
  Future<void>setAppPin(String pin)async{
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('appPin', pin);
    savedPin.value=pin;
    islocked.value=true;
  }

  //Validate Pin
  void verifyPin(String inputPin){
    if(inputPin==savedPin.value){
      unlock();
    }
    else {
      Get.snackbar("Error", "Incorrect PIN",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  void unlock() =>islocked.value=false;
  void lock(){
    if(isAppLocked.value && savedPin.isNotEmpty){
      islocked.value=true;
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(state==AppLifecycleState.paused || state==AppLifecycleState.inactive){
      lock();
    }
  }

}