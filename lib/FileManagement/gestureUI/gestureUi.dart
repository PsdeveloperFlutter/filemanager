import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class GestureUi {
  final SignatureController controller = SignatureController(
    penColor: Colors.blue.shade500,
    penStrokeWidth: 4,
  );
  String status = '';

  // List to store loaded gesture images
  List<Uint8List> gestureImages = [];

// List to store loaded gesture signatures
  List<List<double>> savedSignatures = [];

  Function(VoidCallback)? setStateCallback;

  //This code is for the Save Gesture
  Future<void> saveGesture(String folderPath) async {
    final prefs = await SharedPreferences.getInstance();

    final points = controller.points
            ?.map((e) => Offset(e.offset.dx, e.offset.dy))
            .toList() ??
        [];
    debugPrint("\n Points show kana hai $points");
    List<Map<String, dynamic>> gestureDataList = [];
    final String? gestureDataListString = prefs.getString('gesture_data_list');

    if (gestureDataListString != null) {
      try {
        final rawList = jsonDecode(gestureDataListString);
        gestureDataList = List<Map<String, dynamic>>.from(
          rawList.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      } catch (e) {
        debugPrint("❌ Error parsing gestureDataList: $e");
      }
    }

    Map<String, dynamic> currentGestureData = {};
    var signature = generateShapeSignature(points);
    // Clean NaN / Infinity values
    signature = signature.map((v) {
      if (v is double && (v.isNaN || v.isInfinite)) return 0.0;
      return v;
    }).toList();

    debugPrint("\n Signature Fetched :- $signature");
    currentGestureData['gesture_signature'] = jsonEncode(signature);
    debugPrint("\n Signature Encoded :- $signature");

    //This code is for the Gesture Image store into Map and after that store into SharedPreferences
    final imageData = await controller.toPngBytes();
    if (imageData != null) {

      debugPrint("\n ✅ Image Data Found :- $imageData");
      currentGestureData['gesture_image'] = base64Encode(imageData);
    }

    //Now add the Folder to Gesture Data Map and then add the Map to the List of Map and then store into SharedPreferences
    currentGestureData['folder_path'] = folderPath;
    debugPrint("\n Folder Path Added :- $folderPath");
    gestureDataList.add(currentGestureData);
    debugPrint("\n GestureDataList after storing data :-  $gestureDataList");
    await prefs.setString('gesture_data_list', jsonEncode(gestureDataList));

    debugPrint("\n This is the Gesture Data List $gestureDataList");
    setStateCallback?.call(() {
      status = imageData != null
          ? "✔ Gesture and Image Saved!"
          : "✔ Gesture Saved, but image failed.";
    });
    controller.clear();
  }

  Future<void> loadGestureImages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gestureDataListString = prefs.getString('gesture_data_list');

    gestureImages = [];
    savedSignatures = [];

    if (gestureDataListString != null) {
      try {
        final rawList = jsonDecode(gestureDataListString);
        List<Map<String, dynamic>> gestureDataList =
            List<Map<String, dynamic>>.from(
          rawList.map((item) => Map<String, dynamic>.from(item as Map)),
        );

        for (var data in gestureDataList) {
          // Load image
          if (data.containsKey('gesture_image')) {
            gestureImages.add(base64Decode(data['gesture_image'] as String));
          }
        }
        debugPrint("\nLoaded ${gestureImages.length} gesture images.");
      } catch (e) {
        debugPrint("Error loading gesture data: $e");
      }
    } else {
      debugPrint("\nNo gesture data found.");
    }
  }

// Safe setState call
  void safeSetState(VoidCallback fn) {
    if (setStateCallback != null) {
      setStateCallback!.call(fn);
    }
  }

  double compareGestureSignatures(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dot = 0, normA = 0, normB = 0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dot / (sqrt(normA) * sqrt(normB)); // Cosine similarity
  }

  List<double> generateShapeSignature(List<Offset> points,
      {int sampleSize = 32}) {
    if (points.isEmpty) return [];

    final minX = points.map((e) => e.dx).reduce(min);
    final maxX = points.map((e) => e.dx).reduce(max);
    final minY = points.map((e) => e.dy).reduce(min);
    final maxY = points.map((e) => e.dy).reduce(max);
    final width = maxX - minX;
    final height = maxY - minY;

    final normalized = points.map((e) {
      return Offset(
        (e.dx - minX) / (width == 0 ? 1 : width),
        (e.dy - minY) / (height == 0 ? 1 : height),
      );
    }).toList();

    final resampled = resamplePoints(normalized, sampleSize);
    return calculateAngleSignature(resampled);
  }

  List<Offset> resamplePoints(List<Offset> points, int count) {
    if (points.length < 2) return points;

    final totalLength = _pathLength(points);
    final interval = totalLength / (count - 1);
    double distAccum = 0;

    final resampled = <Offset>[points.first];
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final d = (curr - prev).distance;

      if ((distAccum + d) >= interval) {
        final ratio = (interval - distAccum) / d;
        final newX = prev.dx + ratio * (curr.dx - prev.dx);
        final newY = prev.dy + ratio * (curr.dy - prev.dy);
        final newPoint = Offset(newX, newY);
        resampled.add(newPoint);
        points.insert(i, newPoint);
        distAccum = 0;
      } else {
        distAccum += d;
      }
    }

    while (resampled.length < count) {
      resampled.add(points.last);
    }

    return resampled;
  }

  double _pathLength(List<Offset> points) {
    double length = 0;
    for (int i = 1; i < points.length; i++) {
      length += (points[i] - points[i - 1]).distance;
    }
    return length;
  }

  List<double> calculateAngleSignature(List<Offset> points) {
    final signature = <double>[];
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].dx - points[i - 1].dx;
      final dy = points[i].dy - points[i - 1].dy;
      signature.add(atan2(dy, dx));
    }
    return signature;
  }

  //  This code is responsible for the Show the main Option Dialog box For Open Folder and Open App
  Future<void> showMainOptionDialog(
      BuildContext context, StateSetter setState) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: 100,
            height: 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // To make the Column take minimum space
              children: [
                TextButton(
                    onPressed: () {
                      showFolderAndFilePickerDialog(context, setState);
                      Navigator.pop(context);
                    },
                    child: Text("Open Storage")),
                Divider(),
                TextButton(
                    onPressed: () {
                      showInstalledAppDialogBox(context, setState);
                    },
                    child: Text("Other App")),
                Divider(),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close")),
              ],
            ),
          ),
        );
      },
    );
  }

  //This function is responsible for showing the folder picker dialog and selecting a folder
  Future<void> showFolderAndFilePickerDialog(
      BuildContext context, StateSetter setState) async {
    if (!await Permission.manageExternalStorage.isGranted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Storage permission denied")));
      return;
    }
    Directory currentDir = Directory("/storage/emulated/0");
    FileSystemEntity? selectedItem;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, dialogSetState) {
            List<FileSystemEntity> items =
                currentDir.listSync(); // Show both files and folders

            // Sort items: folders first, then files, both alphabetically
            items.sort((a, b) {
              if (a is Directory && b is File) {
                return -1; // a (directory) comes before b (file)
              } else if (a is File && b is Directory) {
                return 1; // b (directory) comes before a (file)
              }
              // If both are of the same type, sort alphabetically
              return p
                  .basename(a.path)
                  .toLowerCase()
                  .compareTo(p.basename(b.path).toLowerCase());
            });

            return AlertDialog(
              title: Row(
                children: [
                  if (p.dirname(currentDir.path) != currentDir.path &&
                      currentDir.path !=
                          "/storage/emulated/0") // Check if not root
                    IconButton(
                        icon: Icon(Icons.arrow_left),
                        onPressed: () {
                          dialogSetState(() {
                            // Use dialog's setState
                            currentDir = Directory(p.dirname(currentDir.path));
                          });
                        }),
                  Expanded(
                    child: Text(
                      currentDir.path != '/storage/emulated/0'
                          ? p.basename(currentDir.path)
                          : "Internal Storage",
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      " ✨ Hint :- Long Press to Select a File or Folder",
                      style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final entity = items[index];
                          final isDirectory = entity is Directory;
                          final isSelected = selectedItem?.path == entity.path;

                          return Card(
                            elevation: 3,
                            child: ListTile(
                              leading: Icon(
                                isDirectory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                color: isDirectory
                                    ? Colors.orange
                                    : Colors.blue.shade700,
                              ),
                              title: Text(p.basename(entity.path)),
                              tileColor: isSelected
                                  ? Colors.blue.withOpacity(0.2)
                                  : null,
                              onTap: () {
                                if (isDirectory) {
                                  dialogSetState(() {
                                    // Use dialog's setState
                                    currentDir = entity;
                                    selectedItem =
                                        null; // Deselect on navigation
                                  });
                                } else {
                                  // Open file directly using open_file_plus
                                  OpenFilex.open(entity.path);
                                }
                                // Optionally handle file tap if needed
                              },
                              onLongPress: () {
                                dialogSetState(() {
                                  // Use dialog's setState
                                  selectedItem = entity;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                  ),
                  child: Text("Close"),
                  onPressed: () => Navigator.pop(context), // Close the dialog
                ),
                ElevatedButton(
                  onPressed: selectedItem != null
                      ? () {
                          Navigator.pop(context);
                          showGestureSaveDialog(
                              selectedItem!.path, context, ()async{
                                await loadGestureImages();
                                setState((){});// ✅ now it refreshes mainGesture list
                          });
                        }
                      : null,
                  child: Text("Use Selected"),
                ),
              ],
            );
          });
        });
  }

  // This function is responsible for showing the dialog of save gesture
  void showGestureSaveDialog(
      String folderPath, BuildContext context, VoidCallback onGestureSaved) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, innerSetState) {
            setStateCallback =
                innerSetState; // Store inner setState if needed elsewhere

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text("Gesture Save Dialog Box",
                  style: TextStyle(fontSize: 22)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    color: Colors.white,
                    child: Signature(
                        backgroundColor: Colors.white, controller: controller),
                  ),
                ],
              ),
              actions: [
                _buildGestureDialogActions(context, folderPath, onGestureSaved)
              ], //This builds the actions for the dialog and return List of the Widgets
            );
          },
        );
      },
    );
  }

  // This function builds the actions for the gesture dialog
  Widget _buildGestureDialogActions(BuildContext context, String folderPath,VoidCallback onGestureSaved) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.orangeAccent.shade200,
                ),
                onPressed: controller.undo,
                child: const Text(
                  "Undo",
                  style: TextStyle(color: Colors.white),
                )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orangeAccent.shade200,
              ),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                controller.clear();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orangeAccent.shade200,
              ),
              onPressed: () async {
                await saveGesture(folderPath);
                if (Navigator.canPop(context)) Navigator.pop(context);
                await loadGestureImages();
                onGestureSaved(); // Notify parent to refresh UI

              },

              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  //This Function is Responsible for the Opening External Apps in the Device
  Future<void> showInstalledAppDialogBox(
      BuildContext context, StateSetter setState) async {
    final apps = await InstalledApps.getInstalledApps(true, true);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select App"),
          content: SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(app.name),
                    leading: Image.memory(app.icon!, height: 32, width: 32),
                    onTap: () {
                      Navigator.pop(context); // पहले app selection dialog बंद
                      // अब gesture dialog खोलें
                      showGestureSaveDialog(
                        app.packageName, // Folder path की जगह app package name
                        context,
                              ()async{
                            await loadGestureImages();
                            setState((){});// ✅ now it refreshes mainGesture list
                          }
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent.shade700,
              ),
              child: Text(
                "Close",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  //Delete Code of the gesture
  Future<void> deleteGestureImage(int index, StateSetter setState) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedata = prefs.getString('gesture_data_list');

    if (storedata != null) {
      try {
        List<Map<String, dynamic>> gestureDataList =
            List<Map<String, dynamic>>.from(
          jsonDecode(storedata)
              .map((item) => Map<String, dynamic>.from(item as Map)),
        );

        if (gestureDataList.isNotEmpty &&
            index >= 0 &&
            index < gestureDataList.length) {
          gestureDataList.removeAt(index);
          await prefs.setString(
              'gesture_data_list', jsonEncode(gestureDataList));

          await loadGestureImages();

          // ✅ Trigger rebuild inside dialog using StatefulBuilder's setState
          setState(() {});
        }
      } catch (e) {
        debugPrint("\n❌ Error in deletion process: $e");
      }
    }
  }

  // make sure of that
  Future<void> deleteDialogBox(
      int index, BuildContext context, setState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Gesture"),
          content: Text("Are you sure you want to delete this gesture?"),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent.shade700,
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent.shade700,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      Future.delayed(Duration(seconds: 1)).then((_) {
        // Call your delete function
        deleteGestureImage(index, setState);
      }).then((_) {
        loadGestureImages();
      });
      // Ensure the UI is interactive by calling setState
      // This will trigger a rebuild of the widget tree, reflecting any changes.
      setState(() {});
    }
  }
}

