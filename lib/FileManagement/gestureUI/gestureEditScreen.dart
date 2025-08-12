import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

import 'gestureUi.dart';
GestureUi gestureObject=GestureUi();
class EditGestureScreen extends StatefulWidget {
  final int index;

  const EditGestureScreen({super.key, required this.index});

  @override
  State<EditGestureScreen> createState() => _EditGestureScreenState();
}

class _EditGestureScreenState extends State<EditGestureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );

  bool _gestureSaved = false;

  Future<void> _saveEditedGesture() async {
    if (_controller.points.isEmpty) {
      // Don't overwrite old gesture if no new points are drawn
      Navigator.pop(context, false); // Return false indicating no save
      return;
    }
    else {
      final prefs = await SharedPreferences.getInstance();
      final gestureDataString = prefs.getString('gesture_data_list');

      if (gestureDataString == null) {
        Navigator.pop(context, false); // Return false if no data to save to
        return;
      }

      List<Map<String, dynamic>> gestureDataList =
      List<Map<String, dynamic>>.from(jsonDecode(gestureDataString)
          .map((item) => Map<String, dynamic>.from(item)));

      // Convert gesture to image
      final image = await _controller.toImage();
      final byteData = await image?.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final base64Image = base64Encode(pngBytes);

      // Update specific index
      gestureDataList[widget.index]['gesture_image'] = base64Image;

      await prefs.setString('gesture_data_list', jsonEncode(gestureDataList));

      setState(() {
        _gestureSaved = true;
      });
      await gestureObject.loadGestureImages();
      Navigator.pop(context, true); // Return true indicating successful save
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Gesture'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveEditedGesture,
          ),
        ],
      ),
      body: Column(
        children: [
          Signature(
            controller: _controller,
            backgroundColor: Colors.grey[200]!,
            height: 300,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _controller.clear(),
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}
