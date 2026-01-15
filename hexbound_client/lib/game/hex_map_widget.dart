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
  final TransformationController _transformationController = TransformationController();
  Hex? _selectedHex;

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

  void _handleTap(TapUpDetails details, Layout layout) {
    // Current assumption: GestureDetector is CHILD of InteractiveViewer -> CustomPaint
    // So localPosition is in world coordinates (unscaled).
    Offset local = details.localPosition;
    Hex clickedHex = layout.pixelToHex(local).round();
    
    setState(() {
      _selectedHex = clickedHex;
    });

    debugPrint("Clicked: $clickedHex at ${local.dx}, ${local.dy}");
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Selected: $_selectedHex"), duration: const Duration(milliseconds: 200)),
    );
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
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(500.0), // Allow scrolling far
        minScale: 0.1,
        maxScale: 4.0,
        constrained: false, // Infinite Canvas
        child: SizedBox(
          width: 2000, 
          height: 2000,
          child: GestureDetector(
              onTapUp: (details) => _handleTap(details, layout),
              child: CustomPaint(
                painter: HexMapPainter(layout, 10, _tilesetImage!, _selectedHex), // Pass selected hex
              ),
          ),
        ),
      ),
    );
  }
}
