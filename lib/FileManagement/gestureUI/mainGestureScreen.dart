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
    home: mainGesture(),
  ));
}

class mainGesture extends StatefulWidget {
  const mainGesture({Key? key}) : super(key: key);

  @override
  State<mainGesture> createState() => SettingGestureState();
}

class SettingGestureState extends State<mainGesture> {
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

    gestureUi.showMainOptionDialog(context, (fn) {
      setState(fn); // pass main screen setState, not dialog’s
    }).whenComplete(() async {
      await gestureUi.loadGestureImages();
      setState(() {}); // ✅ rebuild with updated list
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
            onPressed: _selectOperationAndAddGesture, // Add new gesture
          ),
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white),
            onPressed: () {
              final parentContext = Navigator.of(context).context;
               Navigator.pop(context); // पहले current screen/dialog बंद करो
               Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
              showModalBottomSheet(
                useRootNavigator: true,
                context: parentContext, // ✅ parent context use करो
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext modalContext) { // Renamed to avoid conflict
                  return Stack(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(modalContext).size.height, // Set to full screen height
                        child: const VerifyGestureScreen(), // ✅ अब ये show होगा
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(modalContext), // Use modalContext here
                        ),
                      ),
                    ],
                  );
                },
                enableDrag: false, // Optional: disable dragging to dismiss
              );
               });
            },
          )
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
                                gestureUi.deleteDialogBox(index, context,
                                    setState); // Show confirmation dialog before deleting
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
                                    builder: (_) => EditGestureScreen(
                                        index: index), // Pass the index
                                  ),
                                );

                                // Check the result from EditGestureScreen
                                if (result == true) {
                                  // Handle true case: e.g., refresh data or show a success message
                                  debugPrint("\n Gesture edit was successful.");
                                  gestureUi
                                      .loadGestureImages(); // Reload images if needed
                                  setState(() {});
                                } else {
                                  debugPrint(
                                      "\n Gesture edit was cancelled or failed.");
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
