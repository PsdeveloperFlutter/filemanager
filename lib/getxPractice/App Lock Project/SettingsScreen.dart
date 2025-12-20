import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lockController.dart';
class SettingsScreen extends StatelessWidget
{
  final LockController controller = Get.find<LockController>();
  final TextEditingController pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ App Lock Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          return Column(
            children: [
              SwitchListTile(
                title: const Text('Enable App Lock'),
                value: controller.isAppLocked.value,
                onChanged: (val) => controller.setAppLock(val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Set/Change PIN'),
                      content: TextField(
                        controller: pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            if (pinController.text.length == 4) {
                              controller.setAppPin(pinController.text);
                              Get.back();
                            } else {
                              Get.snackbar(
                                  'Invalid', 'PIN must be 4 digits long');
                            }
                          },
                          child: const Text('Save'),
                        )
                      ],
                    ),
                  );
                },
                child: const Text('Set / Change PIN'),
              ),
            ],
          );
        }),
      ),
    );
  }
}
