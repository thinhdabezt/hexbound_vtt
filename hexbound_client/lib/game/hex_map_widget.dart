import 'package:flutter/material.dart';
import 'hex_engine/hex.dart';
import 'hex_engine/layout.dart';
import 'hex_engine/map_painter.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class HexMapWidget extends StatefulWidget {
  const HexMapWidget({super.key});

  @override
  State<HexMapWidget> createState() => _HexMapWidgetState();
}

class _HexMapWidgetState extends State<HexMapWidget> {
  ui.Image? _tilesetImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTileset();
  }

  Future<void> _loadTileset() async {
    try {
      final ByteData data = await rootBundle.load('assets/tiles/hex_tile_texture.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Image image = await decodeImageFromList(bytes);
      setState(() {
        _tilesetImage = image;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading tileset: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_tilesetImage == null) {
      return const Scaffold(body: Center(child: Text("Failed to load tileset")));
    }

    // Setup Layout: Pointy Top, Radius 32px
    final layout = Layout(
      HexOrientation.pointy,
      Size(32, 32),
      Offset.zero, // Draw from 0,0 locally
    );

    return Scaffold(
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(500.0), // Allow scrolling far
        minScale: 0.1,
        maxScale: 4.0,
        constrained: false, // Infinite Canvas
        child: SizedBox(
          width: 2000, // Arbitrary large size for testing
          height: 2000,
          child: CustomPaint(
            painter: HexMapPainter(layout, 10, _tilesetImage!), // Radius 10 grid
            child: GestureDetector(
              onTapUp: (details) {
                // Handle Click
                // Note: InteractiveViewer transforms touches. 
                // We need more complex logic for correct world coords if scaled/panned.
                // For now, let's assume simple tap on the painter surface.
                Offset local = details.localPosition;
                var h = layout.pixelToHex(local).round();
                print("Clicked: $h");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Clicked: $h"), duration: Duration(milliseconds: 500)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
