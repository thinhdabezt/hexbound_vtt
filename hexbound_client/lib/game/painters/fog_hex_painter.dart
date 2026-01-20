import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';
import 'package:hexbound_client/game/models/hex_map_data.dart';
import 'package:hexbound_client/game/utils/viewport_utils.dart';

/// Hex-based Fog of War Painter
/// Draws fog hexagons only on unexplored tiles
class FogHexPainter extends CustomPainter {
  final Layout layout;
  final HexMapData mapData;
  final Rect visibleRect;

  FogHexPainter({
    required this.layout,
    required this.mapData,
    required this.visibleRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fogPaint = Paint()
      ..color = const Color(0xF2000000) // ~95% black
      ..style = PaintingStyle.fill;

    final fogBorderPaint = Paint()
      ..color = const Color(0x40000000) // Subtle border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Get visible hex range for culling
    final range = ViewportUtils.getVisibleHexRange(layout, visibleRect);

    for (int r = range.rMin; r <= range.rMax; r++) {
      for (int q = range.qMin; q <= range.qMax; q++) {
        // Skip if outside map bounds
        if (!mapData.isInBounds(q, r)) continue;

        // Only draw fog on UNEXPLORED hexes
        if (!mapData.isExplored(q, r)) {
          final hex = Hex(q, r, -q - r);
          _drawHexPoly(canvas, hex, fogPaint);
          _drawHexPoly(canvas, hex, fogBorderPaint);
        }
      }
    }
  }

  void _drawHexPoly(Canvas canvas, Hex h, Paint paint) {
    Path hexPath = Path();
    List<Offset> corners = _polygonCorners(h);
    hexPath.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < 6; i++) {
      hexPath.lineTo(corners[i].dx, corners[i].dy);
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);
  }

  List<Offset> _polygonCorners(Hex h) {
    List<Offset> corners = [];
    Offset center = layout.hexToPixel(h);
    for (int i = 0; i < 6; i++) {
      Offset offset = _hexCornerOffset(i);
      corners.add(center + offset);
    }
    return corners;
  }

  Offset _hexCornerOffset(int corner) {
    HexOrientation M = layout.orientation;
    double angle = 2.0 * pi * (M.startAngle - corner) / 6.0;
    return Offset(layout.size.width * cos(angle), layout.size.height * sin(angle));
  }

  @override
  bool shouldRepaint(FogHexPainter old) {
    // Repaint when visible area changes or explored tiles change
    return visibleRect != old.visibleRect ||
        mapData.exploredCount != old.mapData.exploredCount;
  }
}
