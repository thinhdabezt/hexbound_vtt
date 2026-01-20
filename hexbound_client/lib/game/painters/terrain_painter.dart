import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';
import 'package:hexbound_client/game/models/hex_map_data.dart';
import 'package:hexbound_client/game/models/terrain_type.dart';
import 'package:hexbound_client/game/utils/viewport_utils.dart';

/// Static Terrain Layer with Viewport Culling
/// Only renders hexes within the visible viewport
class TerrainPainter extends CustomPainter {
  final Layout layout;
  final HexMapData mapData;
  final Rect visibleRect;

  TerrainPainter(this.layout, this.mapData, this.visibleRect);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate visible hex range from viewport
    final range = ViewportUtils.getVisibleHexRange(layout, visibleRect);
    
    int hexesDrawn = 0;
    
    for (int r = range.rMin; r <= range.rMax; r++) {
      for (int q = range.qMin; q <= range.qMax; q++) {
        // Skip if outside map bounds
        if (!mapData.isInBounds(q, r)) continue;
        
        final hex = Hex(q, r, -q - r);
        final terrain = mapData.getTerrain(q, r);

        // Draw filled hex
        final fillPaint = Paint()
          ..color = terrain.color
          ..style = PaintingStyle.fill;
        _drawHexPoly(canvas, hex, fillPaint);

        // Draw border
        final borderPaint = Paint()
          ..color = terrain.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        _drawHexPoly(canvas, hex, borderPaint);

        // Draw icon overlay (if terrain has one)
        if (terrain.icon != null) {
          _drawTerrainIcon(canvas, hex, terrain);
        }
        
        hexesDrawn++;
      }
    }
    
    // Debug: uncomment to see culling stats
    // debugPrint("Viewport Culling: Drew $hexesDrawn/${mapData.totalHexes} hexes");
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

  void _drawTerrainIcon(Canvas canvas, Hex hex, TerrainType terrain) {
    final center = layout.hexToPixel(hex);
    final iconSize = layout.size.width * 0.6;

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(terrain.icon!.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: terrain.icon!.fontFamily,
          package: terrain.icon!.fontPackage,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      center - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );
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
  bool shouldRepaint(TerrainPainter old) {
    // Repaint when visible area changes
    return visibleRect != old.visibleRect;
  }
}
