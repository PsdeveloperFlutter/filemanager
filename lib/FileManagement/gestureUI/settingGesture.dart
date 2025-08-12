import 'dart:io';

import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'checkGestureScreen.dart';
import 'gestureEditScreen.dart';
import 'gestureUi.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SettingGesture(),
  ));
}

class SettingGesture extends StatefulWidget {
  const SettingGesture({Key? key}) : super(key: key);

  @override
  State<SettingGesture> createState() => SettingGestureState();
}

class SettingGestureState extends State<SettingGesture> {
  bool isGestureEnabled = false;
  final storage = const FlutterSecureStorage();
  final uiObj = uiUtility();
  String? selectedpath;
  GestureUi gestureUi = GestureUi();

  @override
  void initState() {
    super.initState();
    checkGestureEnable();
    gestureUi.loadGestureImages(); //Load images from Flutter Secure storage
  }

  void checkGestureEnable() async {
    String? value = await storage.read(key: 'gestureEnabled');
    setState(() {
      isGestureEnabled = value == 'true';
    });
  }

  Future<void> toggleGestureLock(bool value) async {
    await storage.write(key: 'gestureEnabled', value: value.toString());
    setState(() {
      isGestureEnabled = value;
    });
  }

  void _selectOperationAndAddGesture() {
    if (!isGestureEnabled) {
      uiObj.flushBars(
          "Gesture Lock is Disabled", "Enable it first", Colors.red, context);
      return;
    }

    gestureUi.showMainOptionDialog(context, setState).whenComplete(() {
      debugPrint("\n Gesture Images Loaded");
      gestureUi.loadGestureImages();

      setState(() {});
      debugPrint("\n Gesture setState");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gesture Setup',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _selectOperationAndAddGesture,
          ),
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerifyGestureScreen(),
                  ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Enable Gesture Lock'),
              value: isGestureEnabled,
              onChanged: toggleGestureLock,
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: gestureUi.gestureImages.length,
                  itemBuilder: (context, index) {
                    if (index < 0) {
                      return Center(child: Text("No Gesture Found"));
                    }

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              width: 100,
                              height: 100,
                              child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Image.memory(
                                    gestureUi.gestureImages[index],
                                    fit: BoxFit.cover,
                                  )),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text("Delete Gesture"),
                                      content: Text(
                                          "Are you sure you want to delete this gesture?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text("Delete",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmed == true) {

                                  Future.delayed(Duration(seconds: 1))
                                      .then((_) {
                                    // Call your delete function
                                    gestureUi.deleteGestureImage(
                                        index, setState);
                                  }).then((_) {
                                    gestureUi.loadGestureImages();
                                  });
                                  // set this
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.orangeAccent.shade200,
                              ),
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (_) => EditGestureScreen(index: index), // Pass the index
                                   ),
                                 );

                                // Check the result from EditGestureScreen
                                if (result == true) {
                                  // Handle true case: e.g., refresh data or show a success message
                                  debugPrint("\n Gesture edit was successful.");
                                  gestureUi.loadGestureImages(); // Reload images if needed
                                  setState(() {});
                                } else {
                                  debugPrint("\n Gesture edit was cancelled or failed.");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor:
                                      Colors.orangeAccent.shade200),
                              child: Text(
                                "Edit",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }))
        ],
      ),
    );
  }

  // make sure of that
  Future<void> showFolderDialog() async {
    // Request storage permission
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission not granted')),
      );
      return;
    }

    Directory currentDir = Directory('/storage/emulated/0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<FileSystemEntity> contents = [];
            if (currentDir.existsSync()) {
              contents = currentDir
                  .listSync()
                  .where(
                      (entity) => FileSystemEntity.isDirectorySync(entity.path))
                  .toList();
            }

            return AlertDialog(
              title: Row(
                children: [
                  if (p.dirname(currentDir.path) != currentDir.path &&
                      p.dirname(currentDir.path) !=
                          '/storage/emulated/0') // Prevent going above root
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          currentDir = Directory(p.dirname(currentDir.path));
                        });
                      },
                    ),
                  Expanded(
                    child: Text(
                      // Check if the path is the root directory
                      currentDir.path == '/storage/emulated/0'
                          ? 'Internal Storage'
                          : p.basename(currentDir.path),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: contents.length,
                  itemBuilder: (context, index) {
                    final folder = contents[index];
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.folder),
                        title: Text(p.basename(folder.path)),
                        onTap: () {
                          setState(() {
                            currentDir =
                                Directory(folder.path); // Navigate deeper
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                )
              ],
            );
          },
        );
      },
    );
  }
}
