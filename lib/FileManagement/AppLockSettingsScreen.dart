import 'package:flutter/material.dart';
import 'AuthService.dart';

class AppLockSettingsScreen extends StatefulWidget {
  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAppLockStatus();
  }

  Future<void> _loadAppLockStatus() async {
    final status = await _authService.isAppLockEnabled();
    setState(() {
      _isAppLockEnabled = status;
    });
  }

  Future<void> _updateAppLockStatus(bool enable) async {
    await _authService.setAppLockEnabled(enable);
    setState(() {
      _isAppLockEnabled = enable;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(enable ? 'App Lock Enabled' : 'App Lock Disabled'),
      duration: Duration(seconds: 2),
    ));
  }

  void _confirmChange(bool newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? "Enable App Lock?" : "Disable App Lock?"),
        content: Text(newStatus
            ? "Do you want to enable PIN or biometric lock?"
            : "Are you sure you want to disable app lock?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateAppLockStatus(newStatus);
              },
              child: Text("Yes")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Lock Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _isAppLockEnabled ? Icons.lock : Icons.lock_open,
              size: 100,
              color: _isAppLockEnabled ? Colors.green : Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              _isAppLockEnabled
                  ? "App Lock is currently ENABLED"
                  : "App Lock is currently DISABLED",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _confirmChange(!_isAppLockEnabled),
              icon: Icon(_isAppLockEnabled ? Icons.lock_open : Icons.lock),
              label: Text(
                _isAppLockEnabled ? "Disable App Lock" : "Enable App Lock",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _isAppLockEnabled ? Colors.red : Colors.green,
              ),
            )
          ],
        ),
      ),
    );
  }
}
