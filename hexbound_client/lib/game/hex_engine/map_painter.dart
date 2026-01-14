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
    // 1. Prepare Batches
    final List<RSTransform> transforms = [];
    final List<Rect> rects = [];
    
    // Calculate sprite dimensions and scale once
    // Target Hex Size: width = sqrt(3) * size, height = 2 * size
    final double hexWidth = layout.size.width * sqrt(3);
    final double hexHeight = layout.size.height * 2;
    
    // Scale factor to fit the sprite into the hex
    // Sprite is tileset.width x tileset.height
    final double scaleX = hexWidth / tileset.width;
    final double scaleY = hexHeight / tileset.height;
    
    // Use the Full Image as the source (Single Tile Tileset for now)
    final Rect srcRect = Rect.fromLTWH(0, 0, tileset.width.toDouble(), tileset.height.toDouble());
    // Anchor point for rotation/scaling is the center of the sprite
    final double anchorX = tileset.width / 2.0;
    final double anchorY = tileset.height / 2.0;

    // 2. Debug Tools
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final outlinePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 3. Build Batch
    for (int q = -radius; q <= radius; q++) {
      for (int r = -radius; r <= radius; r++) {
        Hex h = Hex(q, r, -q - r);
        Offset center = layout.hexToPixel(h);

        // Add to batch
        // RSTransform.fromComponents:
        //   rotation: 0 (no rotation)
        //   scale: we assume uniform scale or use transform matrix logic directly if non-uniform?
        //   RSTransform only supports one scale value (uniform). 
        //   If our hex is non-square but image is square, we might need non-uniform scaling which drawAtlas RSTransform doesn't support well directly?
        //   Wait, RSTransform(scos, ssin, tx, ty). It implies simpler transforms. 
        //   Actually scos = scale * cos(rot). 
        //   If we need non-uniform scaling (stretch), drawAtlas might be limited or we need to pre-transform.
        //   For now, assume uniform scale based on Width (or Height) to fill. Let's use scale based on Width.
        
        transforms.add(RSTransform.fromComponents(
          rotation: 0,
          scale: scaleX, // Assuming uniform scale effectively for now
          anchorX: anchorX,
          anchorY: anchorY,
          translateX: center.dx,
          translateY: center.dy,
        ));
        
        rects.add(srcRect);
      }
    }

    // 4. Draw Batch (One Draw Call!)
    final Paint paint = Paint();
    canvas.drawAtlas(tileset, transforms, rects, null, null, null, paint);

    // 5. Draw Overlays (Debug) - These are still individual calls, acceptable for debug
    for (int q = -radius; q <= radius; q++) {
      for (int r = -radius; r <= radius; r++) {
         Hex h = Hex(q, r, -q - r);
        _drawDebugOverlay(canvas, h, outlinePaint, textPainter);
      }
    }
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
