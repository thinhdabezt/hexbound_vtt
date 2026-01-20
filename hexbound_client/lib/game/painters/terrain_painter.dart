import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';
import 'package:hexbound_client/game/models/hex_map_data.dart';
import 'package:hexbound_client/game/models/terrain_type.dart';

/// Static Terrain Layer - draws hex tiles with terrain colors and icons
/// This painter should NEVER repaint after initial render
class TerrainPainter extends CustomPainter {
  final Layout layout;
  final HexMapData mapData;

  TerrainPainter(this.layout, this.mapData);

  @override
  void paint(Canvas canvas, Size size) {
    for (final coord in mapData.allCoordinates) {
      final hex = Hex(coord.q, coord.r, -coord.q - coord.r);
      final terrain = mapData.getTerrain(coord.q, coord.r);

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
  bool shouldRepaint(TerrainPainter oldDelegate) => false; // NEVER repaint
}
