import 'package:flutter/material.dart';

/// Terrain types for hex tiles with associated colors and icons
enum TerrainType {
  grass,
  forest,
  water,
  stone,
  sand,
}

extension TerrainTypeExtension on TerrainType {
  /// Get the base color for this terrain
  Color get color {
    switch (this) {
      case TerrainType.grass:
        return const Color(0xFF4CAF50); // Green
      case TerrainType.forest:
        return const Color(0xFF2E7D32); // Dark Green
      case TerrainType.water:
        return const Color(0xFF2196F3); // Blue
      case TerrainType.stone:
        return const Color(0xFF757575); // Gray
      case TerrainType.sand:
        return const Color(0xFFD7CCC8); // Tan
    }
  }

  /// Get the darker shade for borders
  Color get borderColor {
    switch (this) {
      case TerrainType.grass:
        return const Color(0xFF388E3C);
      case TerrainType.forest:
        return const Color(0xFF1B5E20);
      case TerrainType.water:
        return const Color(0xFF1976D2);
      case TerrainType.stone:
        return const Color(0xFF616161);
      case TerrainType.sand:
        return const Color(0xFFBCAAA4);
    }
  }

  /// Get the icon for this terrain (null = no icon overlay)
  IconData? get icon {
    switch (this) {
      case TerrainType.grass:
        return Icons.grass;
      case TerrainType.forest:
        return Icons.park;
      case TerrainType.water:
        return Icons.water_drop;
      case TerrainType.stone:
        return null; // Plain hex
      case TerrainType.sand:
        return null; // Plain hex
    }
  }

  /// Display name
  String get displayName {
    switch (this) {
      case TerrainType.grass:
        return 'Grass';
      case TerrainType.forest:
        return 'Forest';
      case TerrainType.water:
        return 'Water';
      case TerrainType.stone:
        return 'Stone';
      case TerrainType.sand:
        return 'Sand';
    }
  }
}
