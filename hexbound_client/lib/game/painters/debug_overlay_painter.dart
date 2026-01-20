import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

/// Debug Overlay Layer - Grid lines and coordinate text
/// Can be toggled on/off for performance
class DebugOverlayPainter extends CustomPainter {
  final Layout layout;
  final int radius;
  final bool showGrid;
  final bool showCoordinates;

  DebugOverlayPainter({
    required this.layout,
    required this.radius,
    this.showGrid = false,
    this.showCoordinates = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Skip entirely if nothing to draw
    if (!showGrid && !showCoordinates) return;

    final outlinePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int q = -radius; q <= radius; q++) {
      for (int r = -radius; r <= radius; r++) {
        Hex h = Hex(q, r, -q - r);
        Offset center = layout.hexToPixel(h);

        // Draw grid edges
        if (showGrid) {
          Path hexPath = Path();
          List<Offset> corners = _polygonCorners(layout, h);
          hexPath.moveTo(corners[0].dx, corners[0].dy);
          for (int i = 1; i < 6; i++) {
            hexPath.lineTo(corners[i].dx, corners[i].dy);
          }
          hexPath.close();
          canvas.drawPath(hexPath, outlinePaint);
        }

        // Draw coordinate text
        if (showCoordinates) {
          textPainter.text = TextSpan(
            text: "${h.q},${h.r}",
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            center - Offset(textPainter.width / 2, textPainter.height / 2),
          );
        }
      }
    }
  }

  List<Offset> _polygonCorners(Layout layout, Hex h) {
    List<Offset> corners = [];
    Offset center = layout.hexToPixel(h);
    for (int i = 0; i < 6; i++) {
      Offset offset = _hexCornerOffset(layout, i);
      corners.add(center + offset);
    }
    return corners;
  }

  Offset _hexCornerOffset(Layout layout, int corner) {
    HexOrientation M = layout.orientation;
    double angle = 2.0 * pi * (M.startAngle - corner) / 6.0;
    return Offset(layout.size.width * cos(angle), layout.size.height * sin(angle));
  }

  @override
  bool shouldRepaint(DebugOverlayPainter oldDelegate) {
    return showGrid != oldDelegate.showGrid 
        || showCoordinates != oldDelegate.showCoordinates;
  }
}
