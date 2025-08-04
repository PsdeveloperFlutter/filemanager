import 'dart:convert';
import 'dart:typed_data';

import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'checkGestureScreen.dart';
import 'gestureScreen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SettingGesture(),
  ));
}

List<Uint8List> gestureImages = [];

class SettingGesture extends StatefulWidget {
  const SettingGesture({Key? key}) : super(key: key);

  @override
  State<SettingGesture> createState() => _SettingGestureState();
}

class _SettingGestureState extends State<SettingGesture> {
  bool isGestureEnabled = false;
  final storage = const FlutterSecureStorage();
  final uiObj = uiUtility();

  @override
  void initState() {
    super.initState();
    checkGestureEnable();
    loadGestureImages(); //Load images from Flutter Secure storage
  }

  //Load images from Flutter Secure storage
  List<Uint8List> gestureImages = [];

  Future<void> loadGestureImages() async {
    final storedData = await storage.read(key: 'gesture_image');

    if (storedData != null) {
      try {
        List<String> base64List = List<String>.from(jsonDecode(storedData));
        debugPrint("\n Base64 List :- $base64List");
        // Decode all base64 strings to Uint8List
        gestureImages = base64List.map((b64) => base64Decode(b64)).toList();
        debugPrint("\n Gesture Images :- $gestureImages");
      } catch (e) {
        print("Error loading gesture images: $e");
      }
    } else {
      debugPrint("\n Error Occur make sure of that gesture images ");
    }
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

    // showModalBottomSheet(
    //   context: context,
    //   builder: (_) {
    //     return Wrap(
    //       children: [
    //         ListTile(
    //           leading: Icon(Icons.create_new_folder),
    //           title: Text("Create New Folder"),
    //           onTap: () {
    //             Navigator.pop(context);
    //             Future.delayed(Duration(milliseconds: 2000), () {
    //               Navigator.push(
    //                 context,
    //                 MaterialPageRoute(
    //                   builder: (_) =>
    //                       SetSignatureScreen(operation: "Create_Folder"),
    //                 ),
    //               );
    //             });
    //           },
    //         ),
    //         // Add more operations here
    //       ],
    //     );
    //   },
    // );
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return GestureScreen();
    })).then((value) {
      loadGestureImages();
      setState(() {});
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
                  itemCount: gestureImages.length,
                  itemBuilder: (context, index) {
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
                              width: 130,
                              height: 130,
                              child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Image.memory(
                                    gestureImages[index],
                                    fit: BoxFit.cover,
                                  )),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor:
                                      Colors.orangeAccent.shade200),
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor:
                                      Colors.orangeAccent.shade200),
                              child: Text(
                                "Redraw",
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
}
