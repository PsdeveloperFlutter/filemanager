import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final _storage = FlutterSecureStorage();
  final _auth = LocalAuthentication();
  static const _localKey="APP_LOCK_ENABLED";
  //This Code is For set Pin
  Future<void> SetPin(String pin) async {
    await _storage.write(key: "app_pin", value: pin);
    await _storage.write(key: _localKey, value: true.toString());
    print("\n $pin Pin set successfully");
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

  //This Code is For Check Biometric
  Future<bool> isBiometricAvailable() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
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
    return _storage.write(key:_localKey , value: value.toString());
}
}
