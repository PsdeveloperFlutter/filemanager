import 'dart:convert';
import 'dart:typed_data';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:filemanager/FileManagement/gestureUI/gestureUi.dart';
import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
class VerifyGestureScreen extends StatefulWidget {
  const VerifyGestureScreen({Key? key}) : super(key: key);

  @override
  State<VerifyGestureScreen> createState() => _VerifyGestureScreenState();
}

class _VerifyGestureScreenState extends State<VerifyGestureScreen> {
  final SignatureController controller = SignatureController(
    penStrokeWidth: 4,
    penColor: Colors.black,
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

    final points = controller.points
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
       // Launch the app by package name if operation is not empty
        launchExternalApp(operation);
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
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Gesture")),
      body: Column(
        children: [
          Expanded(
            child: Signature(
              controller: controller,
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
                onPressed: () => controller.clear(), // Gesture clear
                text: "Clear",
              ),
              _buildElevatedButton(
                onPressed: () {
                  if (controller.isNotEmpty) {
                    controller.undo(); // Gesture undo
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
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            backgroundColor: Colors.orangeAccent.shade200,
          ),
          onPressed: onPressed,
          child: Text(text),
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

}
