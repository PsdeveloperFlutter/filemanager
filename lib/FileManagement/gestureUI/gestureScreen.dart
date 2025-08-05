import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:shared_preferences/shared_preferences.dart';



class GestureScreen extends StatefulWidget {
  final String operation;
  GestureScreen({Key?key ,required this.operation}):super(key:key);
  @override
  _GestureScreenState createState() => _GestureScreenState();
}

class _GestureScreenState extends State<GestureScreen> {
  final SignatureController controller = SignatureController(penColor: Colors.black);
  String status = '';
  Uint8List? _signatureImage;

  Future<void> saveGesture() async {
    final prefs = await SharedPreferences.getInstance();
    final points = controller.points?.map((e) => Offset(e.offset.dx, e.offset.dy)).toList() ?? [];
    if (points.length < 2) {
      setState(() => status = 'Gesture और draw करें।');
      return;
    }

    // Generate and store the shape signature
    final signature = generateShapeSignature(points);
    final encoded = jsonEncode(signature);
    await prefs.setString('gesture_signature', encoded);

    // Save gesture image
    List<String> imageList = [];
    final fetchData = prefs.getString('gesture_image');
    if (fetchData != null) {
      imageList = List<String>.from(jsonDecode(fetchData));
    }

    final Uint8List? data = await controller.toPngBytes();
    if (data != null) {
      final image64base = base64Encode(data);
      imageList.add(image64base);
      await prefs.setString('gesture_image', jsonEncode(imageList));

      setState(() {
        status = "✔ Gesture and Image Saved!";
      });
    } else {
      setState(() => status = "✔ Gesture Saved, but failed to save image.");
    }
    controller.clear();
  }

  Future<void> verifyGesture() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('gesture_signature');
    if (stored == null) {
      setState(() => status = '❌ कोई Gesture Save नहीं है');
      return;
    }

    final points = controller.points.map((e) => Offset(e.offset.dx, e.offset.dy)).toList();
    if (points.length < 2) {
      setState(() => status = 'Gesture और draw करें।');
      return;
    }

    final currentSignature = generateShapeSignature(points);
    final savedSignature = List<double>.from(jsonDecode(stored));

    final similarity = compareGestureSignatures(currentSignature, savedSignature);

    if (similarity > 0.90) {
      setState(() => status = '✅ Gesture Match हुआ!');
    } else {
      setState(() => status = '❌ Gesture Match नहीं हुआ');
    }

    controller.clear();
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

  List<double> generateShapeSignature(List<Offset> points, {int sampleSize = 32}) {
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gesture Hashing')),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text(
            status,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          if (_signatureImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.memory(_signatureImage!, height: 100),
            ),
          Expanded(
            child: Signature(
              controller: controller,
              backgroundColor: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Save'),
                onPressed: saveGesture,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.check),
                label: Text('Verify'),
                onPressed: verifyGesture,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.clear),
                label: Text('Clear'),
                onPressed: () => controller.clear(),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
