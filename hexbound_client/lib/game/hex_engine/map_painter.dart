import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

class HexMapPainter extends CustomPainter {
  final Layout layout;
  final int radius;
  final ui.Image tileset;
  final Hex? selectedHex;
  final List<Hex>? path;
  final Map<String, Hex>? tokens;

  HexMapPainter(this.layout, this.radius, this.tileset, [this.selectedHex, this.path, this.tokens]);

  @override
  void paint(Canvas canvas, Size size) {
    // ... (Existing Batch Rendering for Map)
    // Same batch rendering code...
    // 1. Prepare Batches
    final List<RSTransform> transforms = [];
    final List<Rect> rects = [];
    
    // ... (rest of batch setup logic: scaleX, scaleY, etc. same as before)
    final double hexWidth = layout.size.width * sqrt(3);
    final double hexHeight = layout.size.height * 2;
    final double scaleX = hexWidth / tileset.width;
    final double scaleY = hexHeight / tileset.height; // Logic from previous step
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
          translateY: center.dy
        ));
        rects.add(srcRect);
      }
    }
    
    final Paint paint = Paint();
    canvas.drawAtlas(tileset, transforms, rects, null, null, null, paint);


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
    
    // Debug layer...
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final outlinePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
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
        // Draw Token as Circle
        canvas.drawCircle(center, layout.size.width * 0.8, tokenPaint);
        canvas.drawCircle(center, layout.size.width * 0.8, tokenOutline);

        // Draw Token ID (Optional Debug)
        // final textSpan = TextSpan(text: id.substring(0, 3), style: const TextStyle(color: Colors.black, fontSize: 10));
        // final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        // tp.layout();
        // tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      });
    }

    // Draw Overlays (Debug)
    for (int q = -radius; q <= radius; q++) {
      for (int r = -radius; r <= radius; r++) {
        Hex h = Hex(q, r, -q - r);
        _drawDebugOverlay(canvas, h, outlinePaint, textPainter);
      }
    }
  }
// ... rest of class


  void _drawHexPoly(Canvas canvas, Hex h, Paint paint) {
    Path path = Path();
    List<Offset> corners = _polygonCorners(layout, h);
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < 6; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDebugOverlay(Canvas canvas, Hex h, Paint outlinePaint, TextPainter textPainter) {
    Offset center = layout.hexToPixel(h);
    
    // Draw edges
    Path path = Path();
    List<Offset> corners = _polygonCorners(layout, h);
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < 6; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();
    canvas.drawPath(path, outlinePaint);

    // Draw Coord Text
    textPainter.text = TextSpan(
      text: "${h.q},${h.r}",
      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
