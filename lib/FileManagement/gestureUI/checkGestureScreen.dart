import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signature/signature.dart';

class _AlwaysWinGestureRecognizer extends OneSequenceGestureRecognizer {
  GestureDragStartCallback? onPanStart;
  GestureDragUpdateCallback? onPanUpdate;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      onPanStart?.call(DragStartDetails(localPosition: event.localPosition));
    } else if (event is PointerMoveEvent) {
      onPanUpdate?.call(DragUpdateDetails(
        localPosition: event.localPosition,
        globalPosition: event.position,
      ));
    }
  }

  @override
  String get debugDescription => 'AlwaysWinGesture';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

class VerifyGestureScreen extends StatefulWidget {
  const VerifyGestureScreen({super.key});

  @override
  State<VerifyGestureScreen> createState() => _VerifyGestureScreenState();
}

class _VerifyGestureScreenState extends State<VerifyGestureScreen> {
  final SignatureController _controller = SignatureController(penStrokeWidth: 2);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Offset> _rawDrawnPoints = [];
  String? _storedHash;
  bool? _isVerified;

  @override
  void initState() {
    super.initState();
    _loadStoredHash();
  }

  Future<void> _loadStoredHash() async {
    final hash = await _storage.read(key: 'signature_hash');
    debugPrint("\n Loaded stored hash: $hash");
    setState(() {
      _storedHash = hash;
    });
  }

  List<Offset> _normalizePoints(List<Offset> points, Size canvasSize) {
    return points.map((e) => Offset(
      e.dx / canvasSize.width,
      e.dy / canvasSize.height,
    )).toList();
  }

  String _generateHash(List<Offset> points, Size canvasSize) {
    final normalized = _normalizePoints(points, canvasSize);
    final pointStr = normalized
        .map((e) => '${e.dx.toStringAsFixed(3)},${e.dy.toStringAsFixed(3)}')
        .join(';');
    final bytes = utf8.encode(pointStr);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _verifyGesture() {
    if (_rawDrawnPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please draw your gesture first.")));
      return;
    }

    if (_storedHash == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No stored gesture hash found. Please set one.")));
      return;
    }

    // Get the size of the Signature widget for normalization
    final RenderBox? signatureBox = context.findRenderObject() as RenderBox?;
    final drawnHash = _generateHash(_rawDrawnPoints, signatureBox!.size);
    debugPrint("Drawn Hash: $drawnHash");
    debugPrint("Stored Hash: $_storedHash");

    setState(() {
      _isVerified = drawnHash == _storedHash;
    });
  }

  void _clear() {
    _controller.clear();
    _rawDrawnPoints.clear();
    setState(() => _isVerified = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Signature')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          RawGestureDetector(
            gestures: {
              _AlwaysWinGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<_AlwaysWinGestureRecognizer>(
                    () => _AlwaysWinGestureRecognizer(),
                    (_AlwaysWinGestureRecognizer instance) {
                  instance
                    ..onPanStart = (details) {
                      setState(() => _rawDrawnPoints.add(details.localPosition));
                    }
                    ..onPanUpdate = (details) {
                      setState(() => _rawDrawnPoints.add(details.localPosition));
                    };
                },
              ),
            },
            child: Signature(
              controller: _controller,
              width: 300,
              height: 300,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _verifyGesture,
                child: const Text("Verify"),
              ),
              ElevatedButton(
                onPressed: _clear,
                child: const Text("Clear"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isVerified != null)
            Text(
              _isVerified! ? "✅ Signature Matched" : "❌ Signature Not Matched",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isVerified! ? Colors.green : Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
