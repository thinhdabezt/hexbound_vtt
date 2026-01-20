import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

/// Dynamic Layer - Tokens, Path Highlight, Selection
/// Repaints only when these elements change
class DynamicPainter extends CustomPainter {
  final Layout layout;
  final Hex? selectedHex;
  final List<Hex>? path;
  final Map<String, Hex>? tokens;

  DynamicPainter({
    required this.layout,
    this.selectedHex,
    this.path,
    this.tokens,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Path Highlight
    if (path != null && path!.isNotEmpty) {
      final Paint pathPaint = Paint()
        ..color = Colors.blue.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      
      final Paint pathOutline = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (var h in path!) {
        _drawHexPoly(canvas, h, pathPaint);
        _drawHexPoly(canvas, h, pathOutline);
      }
    }

    // Draw Selection Highlight (Start Point)
    if (selectedHex != null) {
      final Paint highlightPaint = Paint()
        ..color = Colors.green.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      
      _drawHexPoly(canvas, selectedHex!, highlightPaint);
      
      final Paint highlightOutline = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      _drawHexPoly(canvas, selectedHex!, highlightOutline);
    }

    // Draw Tokens
    if (tokens != null) {
      final Paint tokenPaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill;
        
      final Paint tokenOutline = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      tokens!.forEach((id, hex) {
        Offset center = layout.hexToPixel(hex);
        canvas.drawCircle(center, layout.size.width * 0.8, tokenPaint);
        canvas.drawCircle(center, layout.size.width * 0.8, tokenOutline);
      });
    }
  }

  void _drawHexPoly(Canvas canvas, Hex h, Paint paint) {
    Path hexPath = Path();
    List<Offset> corners = _polygonCorners(layout, h);
    hexPath.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < 6; i++) {
      hexPath.lineTo(corners[i].dx, corners[i].dy);
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);
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
  bool shouldRepaint(DynamicPainter oldDelegate) {
    return selectedHex != oldDelegate.selectedHex 
        || path != oldDelegate.path 
        || tokens != oldDelegate.tokens;
  }
}
