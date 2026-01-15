import 'package:flutter/material.dart';
import 'hex_engine/hex.dart';
import 'hex_engine/layout.dart';
import 'hex_engine/map_painter.dart';
import 'hex_engine/pathfinding.dart';

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
  
  // Interaction State
  Hex? _startHex;
  Hex? _endHex;
  List<Hex> _currentPath = [];
  final Set<Hex> _obstacles = {}; 

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
    Offset local = details.localPosition;
    Hex clickedHex = layout.pixelToHex(local).round();
    
    setState(() {
      if (_startHex == null) {
        _startHex = clickedHex;
        _endHex = null;
        _currentPath = [];
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Start Point Set: $_startHex"), duration: const Duration(milliseconds: 500)),
        );
      } else if (_startHex != null && _endHex == null) {
        _endHex = clickedHex;
        // Calculate Path
        final stopwatch = Stopwatch()..start();
        _currentPath = Pathfinding.findPath(_startHex!, _endHex!, _obstacles);
        stopwatch.stop();
        
        debugPrint("Path found in ${stopwatch.elapsedMilliseconds}ms. Length: ${_currentPath.length}");
         ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Path calculated! Length: ${_currentPath.length}"), duration: const Duration(milliseconds: 1000)),
        );
      } else {
        // Reset if both set
        _startHex = clickedHex;
        _endHex = null;
        _currentPath = [];
         ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reset. New Start Point: $_startHex"), duration: const Duration(milliseconds: 500)),
        );
      }
    });

    debugPrint("Clicked: $clickedHex at ${local.dx}, ${local.dy}");
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_tilesetImage == null) {
      return const Scaffold(body: Center(child: Text("Failed to load tileset")));
    }

    final layout = Layout(
      HexOrientation.pointy,
      Size(32, 32),
      Offset.zero,
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
                painter: HexMapPainter(
                  layout, 
                  10, 
                  _tilesetImage!, 
                  _startHex, 
                  _currentPath
                ), 
              ),
          ),
        ),
      ),
    );
  }
}
