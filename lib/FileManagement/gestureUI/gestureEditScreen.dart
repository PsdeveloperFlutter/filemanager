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
    penColor: Colors.blue,
    exportBackgroundColor: Colors.white,

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

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Rounded corners
          ),
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15), // Button padding
        ),
        onPressed: onPressed,
        child: Text(text,style: TextStyle(color: Colors.white),),
      ),
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildButton("Clear", () => _controller.clear()),
              _buildButton("Undo",()=>_controller.undo()),
              _buildButton("Redo",()=> _controller.redo()),
             ],
          )
        ],
      ),
    );
  }
}
