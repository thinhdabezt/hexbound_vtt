import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

class HexMapPainter extends CustomPainter {
  final Layout layout;
  final int radius;
  final ui.Image tileset;

  HexMapPainter(this.layout, this.radius, this.tileset);

  @override
  void paint(Canvas canvas, Size size) {
    // Basic paint for text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Paint for debug outline
    final outlinePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Paint for image
    final imagePaint = Paint();

    for (int q = -radius; q <= radius; q++) {
      for (int r = -radius; r <= radius; r++) {
        Hex h = Hex(q, r, -q - r);
        _drawHex(canvas, h, imagePaint, outlinePaint, textPainter);
      }
    }
  }

  void _drawHex(Canvas canvas, Hex h, Paint imagePaint, Paint outlinePaint, TextPainter textPainter) {
    Offset center = layout.hexToPixel(h);
    
    // Draw Image (Naive Implementation: Draw whole image rect into hex bounding box)
    // Assuming the image is a single hex tile for now.
    // We need to center it.
    // Hex width = sqrt(3) * size
    // Hex height = 2 * size
    double w = layout.size.width * sqrt(3);
    double h_dim = layout.size.height * 2;
    
    Rect dst = Rect.fromCenter(center: center, width: w, height: h_dim);
    // Source: full image
    Rect src = Rect.fromLTWH(0, 0, tileset.width.toDouble(), tileset.height.toDouble());
    
    canvas.drawImageRect(tileset, src, dst, imagePaint);

    // Draw Debug Outline
    Path path = Path();
    List<Offset> corners = _polygonCorners(layout, h);
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < 6; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();
    canvas.drawPath(path, outlinePaint);

    // Draw Coord Text (Debug)
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
