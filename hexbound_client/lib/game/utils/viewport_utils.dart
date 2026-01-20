import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';
import 'package:flutter/material.dart';

/// Utility functions for viewport culling calculations
class ViewportUtils {
  /// Calculate the range of hex coordinates visible in the given world rect
  static ({int qMin, int qMax, int rMin, int rMax}) getVisibleHexRange(
    Layout layout,
    Rect worldRect,
    {int padding = 1}
  ) {
    // Convert rect corners to hex coordinates
    final topLeftHex = layout.pixelToHex(worldRect.topLeft).round();
    final topRightHex = layout.pixelToHex(worldRect.topRight).round();
    final bottomLeftHex = layout.pixelToHex(worldRect.bottomLeft).round();
    final bottomRightHex = layout.pixelToHex(worldRect.bottomRight).round();
    
    // Find min/max from all corners
    final allQ = [topLeftHex.q, topRightHex.q, bottomLeftHex.q, bottomRightHex.q];
    final allR = [topLeftHex.r, topRightHex.r, bottomLeftHex.r, bottomRightHex.r];
    
    final qMin = allQ.reduce((a, b) => a < b ? a : b) - padding;
    final qMax = allQ.reduce((a, b) => a > b ? a : b) + padding;
    final rMin = allR.reduce((a, b) => a < b ? a : b) - padding;
    final rMax = allR.reduce((a, b) => a > b ? a : b) + padding;
    
    return (qMin: qMin, qMax: qMax, rMin: rMin, rMax: rMax);
  }
  
  /// Check if a hex center is within the visible rect (with some margin)
  static bool isHexVisible(Layout layout, Hex hex, Rect visibleRect, {double margin = 50}) {
    final center = layout.hexToPixel(hex);
    final expandedRect = visibleRect.inflate(margin);
    return expandedRect.contains(center);
  }
}
