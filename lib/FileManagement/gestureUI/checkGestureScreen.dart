import
'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:filemanager/FileManagement/gestureUI/gestureUi.dart';
import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
class VerifyGestureScreen extends StatefulWidget {
  const VerifyGestureScreen({Key? key}) : super(key: key);

  @override
  State<VerifyGestureScreen> createState() => VerifyGestureScreenState();
}

class VerifyGestureScreenState extends State<VerifyGestureScreen> {
  final SignatureController controllers = SignatureController(
    penColor: Colors.blue.shade500, penStrokeWidth: 4.0,
  );
  GestureUi gestureObject = GestureUi();
  uiUtility uiObject = uiUtility();
  List<List<double>> savedSignatures = [];
  List<Uint8List> gestureImages = [];
  Uint8List? matchedGestureImage;
  String status = 'Set it';
  List<dynamic> gestureOperations = [];
  int matchedGestureIndex = -1; // To store the index of the matched gesture

  @override
  void initState() {
    super.initState();
    loadGestureImages();
  }

  /// Gesture Images + Signatures Load करो
  Future<void> loadGestureImages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gestureDataListString = prefs.getString('gesture_data_list');
    debugPrint("\n Gesture Found $gestureDataListString");

    if (gestureDataListString != null) {
      try {
        List<Map<String, dynamic>> gestureDataList =
            List<Map<String, dynamic>>.from(jsonDecode(gestureDataListString)
                .map((item) => Map<String, dynamic>.from(item as Map)));

        // Images load करो
        gestureImages = gestureDataList
            .where((gestureData) => gestureData.containsKey('gesture_image'))
            .map((gestureData) =>
                base64Decode(gestureData['gesture_image'] as String))
            .toList();

        // Signatures load करो
        savedSignatures = gestureDataList
            .where(
                (gestureData) => gestureData.containsKey('gesture_signature'))
            .map((gestureData) =>
                List<double>.from(jsonDecode(gestureData['gesture_signature'])))
            .toList();
        // Print folder_path for each gesture
        for (var gestureData in gestureDataList) {
          if (gestureData.containsKey('folder_path')) {
            setState(() {
              gestureOperations.add(gestureData[
                  'folder_path']); // Store the gesture OPERATIONS FOR THE LATER USE
            });

            debugPrint("\n Gesture Folder Path: $gestureOperations");
            debugPrint("\n Gesture Folder Path: ${gestureData['folder_path']}");
          } else {
            debugPrint("\n Gesture Folder Path not found in data.");
          }
        }
        debugPrint("\n Loaded Gesture Images: ${gestureImages.length}");
        debugPrint("\n Loaded Gesture Signatures: ${savedSignatures.length}");
      } catch (e) {
        debugPrint("Error loading gesture data: $e");
        gestureImages = [];
        savedSignatures = [];
      }
    } else {
      debugPrint("\n No gesture images found.");
      gestureImages = [];
      savedSignatures = [];
    }

    if (mounted) setState(() {});
  }

  /// Gesture Verify करो
  Future<void> verifyGesture() async {
    if (savedSignatures.isEmpty) {
      uiObject.flushBars("Gesture not set yet.", "Please set a gesture first.",
          Colors.red, context);
      return;
    }

    final points = controllers.points
            ?.map((e) => Offset(e.offset.dx, e.offset.dy))
            .toList() ??
        [];

    if (points.length < 2) {
      setState(() => status = 'Please Gesture draw it to short ');
      return;
    }
    debugPrint("\n Gesture Debug 1 ");
    final currentSignature = gestureObject.generateShapeSignature(points);
    debugPrint("\n Gesture Debug 2 ");
    bool matchFound = false;
    matchedGestureImage = null;
    debugPrint("\n Gesture Debug 3 ");
    for (int i = 0; i < savedSignatures.length; i++) {
      final savedSignature = savedSignatures[i];
      debugPrint("\n Gesture Debug 4 ");
      final similarity = gestureObject.compareGestureSignatures(
          currentSignature, savedSignature);
      debugPrint("\n Gesture Debug similarity: $similarity");
      if (similarity > 0.80) {
        debugPrint("\n Gesture Debug 5 ");
        matchFound = true;
        matchedGestureIndex = i; // Store the index of the matched gesture
        matchedGestureImage = gestureImages[matchedGestureIndex]; // Match मिलने पर image सेट
        String operation = gestureOperations[matchedGestureIndex];
        debugPrint("\n Matched Gesture Operation: $operation");
        // Check if the operation is a folder path or an app package name
        if (await Directory(operation).exists()) { // Use await here
          Navigator.pop(context);
          openFolder(operation); // Use openFolder for directories
        }
        else if (await File(operation).exists()) { // Use await here
         Navigator.pop(context);
         openFile(operation);
        }
        else {
          // Assume it's an app package name
          Navigator.pop(context);
          launchExternalApp(operation);
        }
        break;


      }
    }

    debugPrint("\n Gesture Debug matchFound: $matchFound");
    if (matchFound) {
      debugPrint("\n Gesture Debug 6 ");
      setState(() => status = '✅ Gesture Match successfully');
      uiObject.flushBars("Gesture Matched", "The drawn gesture matches a saved gesture.",
          Colors.green, context);
    } else {
      debugPrint("\n Gesture Debug 7 ");
      setState(() => status = '❌ Gesture not Match');
    }
    debugPrint("\n Gesture Debug 8 ");
    // Gesture clear करो
    controllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Signature(
              controller: controllers,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          Text(status, style: const TextStyle(fontSize: 18)),

          // अगर match हुआ है तो image दिखाओ
          if (matchedGestureImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text("Matched Gesture:",
                      style: TextStyle(fontSize: 16)),
                  Image.memory(matchedGestureImage!, height: 150),
                ],
              ),
            ),

          Row(
            children: [
              _buildElevatedButton(
                onPressed: verifyGesture, // Gesture verify
                text: "Verify",
              ),
              _buildElevatedButton(
                onPressed: () => controllers.clear(), // Gesture clear
                text: "Clear",
              ),
              _buildElevatedButton(
                onPressed: () {
                  if (controllers.isNotEmpty) {
                    controllers.undo(); // Gesture undo
                  }
                },
                text: "Undo",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElevatedButton(
      {required VoidCallback onPressed, required String text}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            backgroundColor: Colors.orangeAccent.shade200,
          ),
          onPressed: onPressed,
          child: Text(text,style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // Launch App by Package Name
  Future<void> launchExternalApp(String packagename) async {
    try {
      var openAppResult = await LaunchApp.openApp(
        androidPackageName: packagename,
        openStore: true, // अगर app नहीं मिला तो store खोल देगा
      );

      debugPrint("App open result: $openAppResult");
    } catch (e) {
      debugPrint("Error launching app: $e");
    }
  }

  // Open Folder
  Future<void> openFolder(String folderPath) async {
    try {
      // On Android, you can use OpenFile to open the folder with the default file manager
      final result = await OpenFilex.open(folderPath);
      debugPrint("Folder open result: $result");
    } catch (e) {
      debugPrint("Error opening folder: $e");
      uiObject.flushBars("Error", "Could not open folder: $folderPath", Colors.red, context);
    }
  }

  // Open File
  Future<void> openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      debugPrint("File open result: $result");
    } catch (e) {
      debugPrint("Error opening file: $e");
      uiObject.flushBars("Error", "Could not open file: $filePath", Colors.red, context);
    }
  }
}
