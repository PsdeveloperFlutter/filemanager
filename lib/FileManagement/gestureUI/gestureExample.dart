import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:signature/signature.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /// Initialize the signature controller with custom configurations
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.red,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
    exportBackgroundColor: Colors.transparent,
    exportPenColor: Colors.black,
    onDrawStart: () => log('Drawing started'),
    onDrawEnd: () => log('Drawing ended'),
  );

  @override
  void initState() {
    super.initState();

    // Add a listener to update the UI when drawing ends
    _controller.addListener(() {
      log('Signature updated');
      setState(() {}); // Triggers UI update for label
    });
  }

  @override
  void dispose() {
    // Dispose the controller to free up resources
    _controller.dispose();
    super.dispose();
  }

  /// Export signature to PNG format and display
  Future<void> exportImage(BuildContext context) async {

    if (_controller.isEmpty) {
      showMessage(context, 'No content to export as PNG');
      return;
    }
      savegesture(); // Save gesture points for debugging
    final Uint8List? data = await _controller.toPngBytes(
      height: 1000,
      width: 1000,
    );

    if (data == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('PNG Image')),
          body: Center(
            child: Container(
              color: Colors.grey[300],
              child: Image.memory(data),
            ),
          ),
        ),
      ),
    );
  }

  /// Export signature to SVG format and display
  Future<void> exportSVG(BuildContext context) async {
    if (_controller.isEmpty) {
      showMessage(context, 'No content to export as SVG');
      return;
    }

    final String? rawSVG = _controller.toRawSVG();

    if (rawSVG == null || !mounted) return;

    final SvgPicture? svgWidget = _controller.toSVG();

    if (svgWidget == null) {
      showMessage(context, 'Error converting to SVG');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('SVG Image')),
          body: Center(
            child: Container(
              color: Colors.grey[300],
              child: svgWidget,
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to show SnackBar messages
  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void savegesture() {
    final points = _controller.points;
    if (points == null) {
      debugPrint("Points is null $points");
    } else {
      debugPrint("Points are not null $points");
      final gesture= points.whereType<Offset>();
      debugPrint("\nGesture Points: $gesture");

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature Pad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(
            height: 300,
            child: Center(child: Text('Scroll Test (Top)')),
          ),
          Signature(
            key: const Key('signature'),
            controller: _controller,
            height: 300,
            backgroundColor: Colors.grey[300]!,
          ),
          const SizedBox(height: 10),
          Text(
            _controller.isEmpty
                ? "Signature pad is empty"
                : "Signature pad is not empty",
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 300,
            child: Center(child: Text('Scroll Test (Bottom)')),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                key: const Key('exportPNG'),
                icon: const Icon(Icons.image),
                color: Colors.blue,
                onPressed: () => exportImage(context),
                tooltip: 'Export PNG',
              ),
              IconButton(
                key: const Key('exportSVG'),
                icon: const Icon(Icons.share),
                color: Colors.blue,
                onPressed: () => exportSVG(context),
                tooltip: 'Export SVG',
              ),
              IconButton(
                icon: const Icon(Icons.undo),
                color: Colors.blue,
                onPressed: () => setState(() => _controller.undo()),
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                color: Colors.blue,
                onPressed: () => setState(() => _controller.redo()),
                tooltip: 'Redo',
              ),
              IconButton(
                key: const Key('clear'),
                icon: const Icon(Icons.clear),
                color: Colors.blue,
                onPressed: () => setState(() => _controller.clear()),
                tooltip: 'Clear',
              ),
              IconButton(
                key: const Key('stop'),
                icon: Icon(
                  _controller.disabled ? Icons.play_arrow : Icons.pause,
                ),
                color: Colors.blue,
                onPressed: () {
                  setState(() => _controller.disabled = !_controller.disabled);
                },
                tooltip:
                    _controller.disabled ? 'Resume Drawing' : 'Pause Drawing',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
