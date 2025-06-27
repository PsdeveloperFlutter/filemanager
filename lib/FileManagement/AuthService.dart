import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final _storage = FlutterSecureStorage();
  final _auth = LocalAuthentication();
  static const _localKey="APP_LOCK_ENABLED";
  static const _biometricKey = "BIOMETRIC_ENABLED";

  //This Code is For set Pin
  Future<void> SetPin(Map<String,dynamic> pin) async {
    await _storage.write(key: "app_pin", value: pin['password']);
    String jsonString=jsonEncode(pin); //Convert the map to json format
    await _storage.write(key: "app_pin_details", value: jsonString);//store the jsonString to the flutter secure storage
    await _storage.write(key: _localKey, value: true.toString());
    print("\n $pin Pin set successfully $jsonString");
  }

  //This Code is For get Pin
  Future<String?> GetPin() async {
    return await _storage.read(key: "app_pin");
  }

  //This Code is For Check Pin
  Future<bool> VerifyPin(String pin) async {
    final StoredPin = await _storage.read(key: "app_pin");
    return StoredPin == pin;
  }
  //This Function help to ResetPin
  Future<bool>resetPin()async{
    await _storage.delete(key: "app_pin");
    return await _storage.read(key: "app_pin")==null?true:false;
  }


  //This Code is For Get Pin Details from flutter secure storage
  Future<Map<String, dynamic>> GetPinDetails()async{
    final jsonString=await _storage.read(key:"app_pin_details");
    if(jsonString!=null){
      return jsonDecode(jsonString);
    }
    return {};
  }
  //This Code is For Check Biometric
  Future<bool> isBiometricAvailable() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
  }
  //This function for the biometric value
  Future<bool> isBiometricToggleEnabled() async {
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }
  Future<bool>setBiometricToggle(bool enable)async{
    if(enable){
      bool isAvailable=await isBiometricAvailable();
      bool isTrulyAvailable=await isBiometricTrulyAvailable();
      if(isTrulyAvailable && isAvailable){
        bool didAuthenticate=await authenticateWithBiometric();
        if(didAuthenticate){
            await _storage.write(key:_biometricKey, value: 'true');
            print("Biometric enabled Via Toggle");
            return true;
        }
        else {
          print("User cancelled biometric auth");
          return false;
        }
      }
      else{
        print("Biometric not available or enrolled");
        return false;
      }
    }
    else{
      await _storage.write(key: _biometricKey, value: 'false');
      print("Biometric disabled via toggle");
      return true;
    }
  }

  //Ye wala function Explain karta hi ki biometric jo lagi hoi hai kya nhi
  Future<bool>isBiometricTrulyAvailable() async {
    final result= await _auth.getAvailableBiometrics();
   if(result.isNotEmpty){
     return true;
    }
   else{
     return false;
    }
  }

  //This code is for the authenticate with Biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      bool isAvailable = await _auth.canCheckBiometrics;
      bool isSupported = await _auth.isDeviceSupported();

      if (!isAvailable || !isSupported) {
        print("Biometric not available or not supported.");
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: "Authenticate to unlock the app",
        options: const AuthenticationOptions(
          biometricOnly: true,       // ✅ No fallback to PIN
          stickyAuth: true,          // ✅ Keep auth active across screens
          useErrorDialogs: true,     // ✅ Show system dialogs if errors occur
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }

  //Check if the app is Enabled
Future<bool>isAppLockEnabled()async{
    final isEnabled=await _storage.read(key: _localKey);
    return isEnabled=='true';
}
//Enable /Disable App Lock
Future<void>setAppLockEnabled(bool value)async{
    print("\n Value of the Set App Lock Enabled $value");
    return _storage.write(key:_localKey , value: value.toString());
}
}
