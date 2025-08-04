import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signature/signature.dart';

class SetSignatureScreen extends StatefulWidget {
  const SetSignatureScreen({super.key, required String operation});
  @override
  State<SetSignatureScreen> createState() => _SetSignatureScreenState();
}

class _SetSignatureScreenState extends State<SetSignatureScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  final List<Offset> rawGesturePoints = []; // Capture gesture points manually
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // Save normalized points (0 to 1 scale)
  Future<void> saveGesturePoints(Size canvasSize) async {
    if (rawGesturePoints.isEmpty) return;

    final normalized = rawGesturePoints.map((point) {
      return {
        'x': point.dx / canvasSize.width,
        'y': point.dy / canvasSize.height,
      };
    }).toList();
    // Convert to a consistent string
    final gestureString = normalized.map((p) => '${p['x']},${p['y']}').join(';');

    // Hash the gesture string using SHA-256
    final hash = sha256.convert(utf8.encode(gestureString)).toString();


    await secureStorage.write(key: 'signature_hash', value: hash);
    debugPrint('Saved gesture hash: $hash');

    // final encoded = jsonEncode(normalized);
    // await secureStorage.write(key: 'signature_points', value: encoded);
    // debugPrint('Saved signature points: $encoded');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gesture saved to secure storage')),
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Signature'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight * 0.6);

          return Column(
            children: [
              RawGestureDetector(
                gestures: {
                  _AlwaysWinGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<_AlwaysWinGestureRecognizer>(
                        () => _AlwaysWinGestureRecognizer(),
                        (_AlwaysWinGestureRecognizer instance) {
                      instance.onPanStart = (details) {
                        setState(() {
                          rawGesturePoints.clear();
                          rawGesturePoints.add(details.localPosition);
                        });
                      };
                      instance.onPanUpdate = (details) {
                        setState(() {
                          rawGesturePoints.add(details.localPosition);
                        });
                      };
                    },
                  ),
                },
                child: Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[200],
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _signatureController.clear(),
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: () => saveGesturePoints(canvasSize),
                    child: const Text('Save'),
                  ),
                ],
              ),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }
}

/// Custom Gesture Recognizer that always wins (prevents gesture conflicts)
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
      onPanUpdate?.call(DragUpdateDetails(localPosition: event.localPosition, globalPosition: event.position));
    }
  }

  @override
  String get debugDescription => 'AlwaysWinGesture';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
