import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

/// Static Terrain Layer - draws hex tiles using drawAtlas
/// This painter should NEVER repaint after initial render
class TerrainPainter extends CustomPainter {
  final Layout layout;
  final int radius;
  final ui.Image tileset;

  TerrainPainter(this.layout, this.radius, this.tileset);

  @override
  void paint(Canvas canvas, Size size) {
    final List<RSTransform> transforms = [];
    final List<Rect> rects = [];
    
    final double hexWidth = layout.size.width * sqrt(3);
    final double hexHeight = layout.size.height * 2;
    final double scaleX = hexWidth / tileset.width;
    final Rect srcRect = Rect.fromLTWH(0, 0, tileset.width.toDouble(), tileset.height.toDouble());
    final double anchorX = tileset.width / 2.0;
    final double anchorY = tileset.height / 2.0;

    for (int q = -radius; q <= radius; q++) {
      for (int r = -radius; r <= radius; r++) {
        Hex h = Hex(q, r, -q - r);
        Offset center = layout.hexToPixel(h);

        transforms.add(RSTransform.fromComponents(
          rotation: 0, 
          scale: scaleX, 
          anchorX: anchorX, 
          anchorY: anchorY, 
          translateX: center.dx, 
          translateY: center.dy,
        ));
        rects.add(srcRect);
      }
    }
    
    canvas.drawAtlas(tileset, transforms, rects, null, null, null, Paint());
  }

  @override
  bool shouldRepaint(TerrainPainter oldDelegate) => false; // NEVER repaint
}
