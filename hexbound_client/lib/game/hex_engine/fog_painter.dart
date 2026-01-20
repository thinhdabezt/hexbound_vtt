import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

/// Simple Fog of War Painter - straightforward approach
/// Draws fog rect, then draws clear circles for each token's vision
class FogOfWarPainter extends CustomPainter {
  final Layout layout;
  final Map<String, Hex> tokens;
  final int visionRange;

  FogOfWarPainter({
    required this.layout,
    required this.tokens,
    this.visionRange = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Debug: Print token count
    debugPrint("FogOfWarPainter: ${tokens.length} tokens");
    
    // If there are tokens, create holes in the fog
    if (tokens.isNotEmpty) {
      // Use saveLayer to composite the fog with holes
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );

      // Draw full fog background
      final fogPaint = Paint()..color = const Color(0xDD000000); // 87% black
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fogPaint);

      // Clear circles around tokens
      final clearPaint = Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear;

      for (var entry in tokens.entries) {
        final center = layout.hexToPixel(entry.value);
        final radius = visionRange * layout.size.width * 1.5;
        
        debugPrint("Drawing vision at: $center with radius: $radius");
        
        canvas.drawCircle(center, radius, clearPaint);
      }

      canvas.restore();
    } else {
      // No tokens = full fog
      final fogPaint = Paint()..color = const Color(0xDD000000);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fogPaint);
    }
  }

  @override
  bool shouldRepaint(FogOfWarPainter oldDelegate) {
    return tokens.length != oldDelegate.tokens.length;
  }
}
