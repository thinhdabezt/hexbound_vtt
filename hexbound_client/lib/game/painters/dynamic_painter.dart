import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';
import 'package:hexbound_client/game/models/token_stats.dart';

/// Dynamic Layer with Viewport Culling
/// Tokens, Path Highlight, Selection - only renders visible elements
class DynamicPainter extends CustomPainter {
  final Layout layout;
  final Rect visibleRect;
  final Hex? selectedHex;
  final List<Hex>? path;
  final Map<String, Hex>? tokens;
  final Map<String, TokenStats>? tokenStats;
  final Set<Hex>? movementRange; // Hexes reachable with remaining movement

  DynamicPainter({
    required this.layout,
    required this.visibleRect,
    this.selectedHex,
    this.path,
    this.tokens,
    this.tokenStats,
    this.movementRange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final expandedRect = visibleRect.inflate(50); // Small margin

    // Draw Movement Range (reachable hexes in combat)
    if (movementRange != null && movementRange!.isNotEmpty) {
      final Paint rangePaint = Paint()
        ..color = Colors.cyan.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      
      final Paint rangeOutline = Paint()
        ..color = Colors.cyan.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      for (var h in movementRange!) {
        final center = layout.hexToPixel(h);
        if (!expandedRect.contains(center)) continue;
        
        _drawHexPoly(canvas, h, rangePaint);
        _drawHexPoly(canvas, h, rangeOutline);
      }
    }

    // Draw Path Highlight (filter to visible)
    if (path != null && path!.isNotEmpty) {
      final Paint pathPaint = Paint()
        ..color = Colors.blue.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      
      final Paint pathOutline = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (var h in path!) {
        final center = layout.hexToPixel(h);
        if (!expandedRect.contains(center)) continue; // Cull
        
        _drawHexPoly(canvas, h, pathPaint);
        _drawHexPoly(canvas, h, pathOutline);
      }
    }

    // Draw Selection Highlight (check visibility)
    if (selectedHex != null) {
      final center = layout.hexToPixel(selectedHex!);
      if (expandedRect.contains(center)) {
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
    }

    // Draw Tokens as Flag icons (filter to visible)
    if (tokens != null) {
      tokens!.forEach((id, hex) {
        Offset center = layout.hexToPixel(hex);
        if (!expandedRect.contains(center)) return; // Cull
        
        final stats = tokenStats?[id];
        final isUnconscious = stats?.isUnconscious ?? false;
        final isDead = stats?.isDead ?? false;
        
        // Apply opacity for death states
        final tokenOpacity = isDead ? 0.3 : 1.0;
        
        // Save canvas state for applying effects
        canvas.save();
        
        // Draw flag pole
        final polePaint = Paint()
          ..color = (isUnconscious ? Colors.grey : Colors.brown[700]!).withOpacity(tokenOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        final poleStart = center + Offset(0, layout.size.height * 0.3);
        final poleEnd = center - Offset(0, layout.size.height * 0.6);
        canvas.drawLine(poleStart, poleEnd, polePaint);
        
        // Draw flag triangle
        final flagColor = isDead ? Colors.grey[800]! : (isUnconscious ? Colors.grey : Colors.red);
        final flagPaint = Paint()
          ..color = flagColor.withOpacity(tokenOpacity)
          ..style = PaintingStyle.fill;
        
        final flagPath = Path()
          ..moveTo(poleEnd.dx, poleEnd.dy)
          ..lineTo(poleEnd.dx + layout.size.width * 0.6, poleEnd.dy + layout.size.height * 0.25)
          ..lineTo(poleEnd.dx, poleEnd.dy + layout.size.height * 0.5)
          ..close();
        
        canvas.drawPath(flagPath, flagPaint);
        
        // Flag border
        final borderColor = isDead ? Colors.grey[900]! : (isUnconscious ? Colors.grey[600]! : Colors.red[900]!);
        final flagBorder = Paint()
          ..color = borderColor.withOpacity(tokenOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(flagPath, flagBorder);
        
        // Draw death state icon
        if (isDead) {
          _drawDeathIcon(canvas, center, "💀");
        } else if (isUnconscious) {
          _drawDeathIcon(canvas, center, "💤");
        } else if (stats != null && stats.conditions.isNotEmpty) {
          // Draw condition badges (excluding death states)
          final visibleConditions = stats.conditions
              .where((c) => c != "Unconscious" && c != "Dead")
              .take(3) // Max 3 badges
              .toList();
          _drawConditionBadges(canvas, center, visibleConditions);
        }
        
        canvas.restore();
        
        // Draw HP bar if stats available (not for dead tokens)
        if (stats != null && !isDead) {
          _drawHpBar(canvas, center, stats.currentHp, stats.maxHp);
        }
      });
    }
  }
  
  void _drawHpBar(Canvas canvas, Offset tokenCenter, int current, int max) {
    final barWidth = layout.size.width * 1.2;
    final barHeight = 4.0;
    final barTop = tokenCenter.dy + layout.size.height * 0.4;
    
    // Background (dark gray)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tokenCenter.dx - barWidth/2, barTop, barWidth, barHeight),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.grey[800]!,
    );
    
    // HP fill (green → yellow → red based on %)
    final ratio = max > 0 ? current.toDouble() / max.toDouble() : 0.0;
    Color barColor;
    if (ratio > 0.5) {
      barColor = Colors.green;
    } else if (ratio > 0.25) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tokenCenter.dx - barWidth/2, barTop, barWidth * ratio, barHeight),
        const Radius.circular(2),
      ),
      Paint()..color = barColor,
    );
  }

  void _drawDeathIcon(Canvas canvas, Offset center, String emoji) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: layout.size.height * 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawConditionBadges(Canvas canvas, Offset center, List<String> conditions) {
    if (conditions.isEmpty) return;
    
    final badgeSize = layout.size.height * 0.3;
    final startX = center.dx - (conditions.length * badgeSize) / 2;
    final badgeY = center.dy - layout.size.height * 0.8;
    
    for (int i = 0; i < conditions.length; i++) {
      final condition = conditions[i];
      final icon = TokenStats.conditionIcons[condition] ?? "❓";
      final badgeX = startX + i * badgeSize;
      
      // Draw badge background
      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(badgeX + badgeSize / 2, badgeY), badgeSize / 2, bgPaint);
      
      // Draw icon
      final textPainter = TextPainter(
        text: TextSpan(
          text: icon,
          style: TextStyle(fontSize: badgeSize * 0.7),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas,
        Offset(badgeX + badgeSize / 2 - textPainter.width / 2, badgeY - textPainter.height / 2),
      );
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
    return visibleRect != oldDelegate.visibleRect
        || selectedHex != oldDelegate.selectedHex 
        || path != oldDelegate.path 
        || tokens != oldDelegate.tokens
        || tokenStats != oldDelegate.tokenStats
        || movementRange != oldDelegate.movementRange;
  }
}
