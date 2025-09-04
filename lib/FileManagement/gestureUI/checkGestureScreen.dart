import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:filemanager/FileManagement/gestureUI/gestureUi.dart';
import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyGestureScreen extends StatefulWidget {
  const VerifyGestureScreen({Key? key}) : super(key: key);

  @override
  State<VerifyGestureScreen> createState() => _VerifyGestureScreenState();
}

class _VerifyGestureScreenState extends State<VerifyGestureScreen> {
  GestureUi gestureObject = GestureUi();
  uiUtility uiObject = uiUtility();

  List<List<double>> savedSignatures = [];
  List<Uint8List> gestureImages = [];
  List<dynamic> gestureOperations = [];

  List<Offset> drawnPoints = []; // user drawn points
  Offset? fingerPosition; // pointer circle position
  Uint8List? matchedGestureImage;
  String status = "Draw your gesture at Canvas";

  @override
  void initState() {
    super.initState();
    loadGestureImages();
  }

  Future<void> loadGestureImages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gestureDataListString = prefs.getString('gesture_data_list');

    if (gestureDataListString != null) {
      try {
        List<Map<String, dynamic>> gestureDataList =
        List<Map<String, dynamic>>.from(jsonDecode(gestureDataListString)
            .map((item) => Map<String, dynamic>.from(item as Map)));

        gestureImages = gestureDataList
            .where((gestureData) => gestureData.containsKey('gesture_image'))
            .map((gestureData) =>
            base64Decode(gestureData['gesture_image'] as String))
            .toList();

        savedSignatures = gestureDataList
            .where(
                (gestureData) => gestureData.containsKey('gesture_signature'))
            .map((gestureData) =>
        List<double>.from(jsonDecode(gestureData['gesture_signature'])))
            .toList();

        for (var gestureData in gestureDataList) {
          if (gestureData.containsKey('folder_path')) {
            gestureOperations.add(gestureData['folder_path']);
          }
        }
      } catch (e) {
        gestureImages = [];
        savedSignatures = [];
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> verifyGesture() async {
    if (savedSignatures.isEmpty) {
      uiObject.flushBars("No Gesture", "Please set a gesture first.",
          Colors.red, context);
      return;
    }
    if (drawnPoints.length < 2) {
      setState(() => status = "Gesture too short");
      return;
    }

    final currentSignature =
    gestureObject.generateShapeSignature(drawnPoints);

    bool matchFound = false;

    for (int i = 0; i < savedSignatures.length; i++) {
      final savedSignature = savedSignatures[i];
      final similarity = gestureObject.compareGestureSignatures(
          currentSignature, savedSignature);

      if (similarity > 0.80) {
        matchFound = true;
        matchedGestureImage = gestureImages[i];
        String operation = gestureOperations[i];

        if (await Directory(operation).exists()) {
          Navigator.pop(context);
          openFolder(operation);
        } else if (await File(operation).exists()) {
          Navigator.pop(context);
          openFile(operation);
        } else {
          Navigator.pop(context);
          launchExternalApp(operation);
        }
        break;
      }
    }

    setState(() {
      status = matchFound ? "✅ Matched!" : "❌ Not Matched";
    });

    drawnPoints.clear();
    fingerPosition = null;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // light black background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: GestureDetector(

      onPanStart: (details) {
          setState(() {
            drawnPoints = [details.localPosition];
            fingerPosition = details.localPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            drawnPoints.add(details.localPosition);
            fingerPosition = details.localPosition;
          });
        },
        onPanEnd: (details) {
          verifyGesture();
           if(status.compareTo("❌ Not Matched")==0){
            Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                status = "Draw your gesture";
                matchedGestureImage = null;
              });
            });


           }
          },
        child: Stack(
          children: [
            // Draw gesture path
            CustomPaint(
              painter: GesturePainter(drawnPoints),
              size: Size.infinite,
            ),

            // Pointer circle following finger
            if (fingerPosition != null)
              Positioned(
                left: fingerPosition!.dx - 15,
                top: fingerPosition!.dy - 15,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

            // Status text
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ),

            // Matched gesture preview
            if (matchedGestureImage != null)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text("Matched Gesture",
                        style: TextStyle(color: Colors.white)),
                    Image.memory(matchedGestureImage!, height: 150),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> launchExternalApp(String packageName) async {
    try {
      await LaunchApp.openApp(
        androidPackageName: packageName,
        openStore: true,
      );
    } catch (e) {
      debugPrint("Error launching app: $e");
    }
  }

  Future<void> openFolder(String folderPath) async {
    try {
      await OpenFilex.open(folderPath);
    } catch (e) {
      uiObject.flushBars("Error", "Cannot open folder", Colors.red, context);
    }
  }

  Future<void> openFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
    } catch (e) {
      uiObject.flushBars("Error", "Cannot open file", Colors.red, context);
    }
  }
}

class GesturePainter extends CustomPainter {
  final List<Offset> points;
  GesturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(GesturePainter oldDelegate) =>
      oldDelegate.points != points;
}
