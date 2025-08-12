import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:filemanager/FileManagement/gestureUI/gestureUi.dart';
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
  List<List<double>> savedSignatures = [];
  List<Uint8List> gestureImages = [];
  Uint8List? matchedGestureImage;
  String status = '';

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
            .where((gestureData) => gestureData.containsKey('gesture_signature'))
            .map((gestureData) =>
        List<double>.from(jsonDecode(gestureData['gesture_signature'])))
            .toList();

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
      setState(() => status = '❌ कोई Gesture Save नहीं है');
      return;
    }

    final points = controller.points
        ?.map((e) => Offset(e.offset.dx, e.offset.dy))
        .toList() ??
        [];

    if (points.length < 2) {
      setState(() => status = 'Gesture और draw करें।');
      return;
    }
     debugPrint("\n Gesture Debug 1 ");
    final currentSignature = gestureObject.generateShapeSignature(points);
    debugPrint("\n Gesture Debug 2 ");
    bool matchFound = false;
    matchedGestureImage = null;
    debugPrint("\n Gesture Debug 3 ");
    for (int i = 0; i < savedSignatures.length; i++) {
      debugPrint("\n Gesture Debug 4 ");
      final similarity =
      gestureObject.compareGestureSignatures(currentSignature, savedSignatures[i]);
      debugPrint("\n Gesture Debug similarity: $similarity");
      if (similarity > 0.60) {
        debugPrint("\n Gesture Debug 5 ");
        matchFound = true;
        matchedGestureImage = gestureImages[i]; // Match मिलने पर image सेट
        break;
      }
    }

    debugPrint("\n Gesture Debug matchFound: $matchFound");
    if (matchFound) {
      debugPrint("\n Gesture Debug 6 ");
      setState(() => status = '✅ Gesture Match हुआ!');
    } else {
      debugPrint("\n Gesture Debug 7 ");
      setState(() => status = '❌ Gesture Match नहीं हुआ');
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
              Expanded(
                child: ElevatedButton(
                  onPressed: verifyGesture,
                  child: const Text("Verify Gesture"),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.clear(),
                  child: const Text("Clear"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
