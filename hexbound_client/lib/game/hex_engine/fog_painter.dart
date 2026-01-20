import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

class FogOfWarPainter extends CustomPainter {
  final Layout layout;
  final Map<String, Hex> tokens;
  final int visionRange; // How many hexes a token can see

  FogOfWarPainter({
    required this.layout,
    required this.tokens,
    this.visionRange = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tokens.isEmpty) return;

    // Create a path that covers the entire canvas
    final fogPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cut out visible areas around each token
    for (var entry in tokens.entries) {
      final hex = entry.value;
      final center = layout.hexToPixel(hex);
      
      // Create a circular "hole" for each token's vision
      // Vision radius = visionRange * hex width
      final visibleRadius = visionRange * layout.size.width * 1.5;
      
      fogPath.addOval(Rect.fromCircle(center: center, radius: visibleRadius));
    }

    // Use evenOdd fill type to create the "holes"
    fogPath.fillType = PathFillType.evenOdd;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fogPath, paint);
  }

  @override
  bool shouldRepaint(FogOfWarPainter oldDelegate) {
    return tokens != oldDelegate.tokens;
  }
}
