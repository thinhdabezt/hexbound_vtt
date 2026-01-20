import 'dart:math';
import 'terrain_type.dart';

/// Represents a rectangular hex map with terrain data
class HexMapData {
  final int width;
  final int height;
  final Map<String, TerrainType> _tiles;

  HexMapData._({
    required this.width,
    required this.height,
    required Map<String, TerrainType> tiles,
  }) : _tiles = tiles;

  /// Generate a random map with weighted terrain distribution
  factory HexMapData.generateRandom(int width, int height, {int? seed}) {
    final random = Random(seed);
    final tiles = <String, TerrainType>{};

    for (int r = 0; r < height; r++) {
      // Odd-r offset: odd rows are shifted right
      int qStart = -(r ~/ 2);
      int qEnd = qStart + width;

      for (int q = qStart; q < qEnd; q++) {
        final roll = random.nextDouble();
        TerrainType type;

        // Weighted random selection
        if (roll < 0.50) {
          type = TerrainType.grass;
        } else if (roll < 0.70) {
          type = TerrainType.forest;
        } else if (roll < 0.80) {
          type = TerrainType.water;
        } else if (roll < 0.95) {
          type = TerrainType.stone;
        } else {
          type = TerrainType.sand;
        }

        tiles["$q,$r"] = type;
      }
    }

    return HexMapData._(width: width, height: height, tiles: tiles);
  }

  /// Get terrain at specific coordinates
  TerrainType getTerrain(int q, int r) {
    return _tiles["$q,$r"] ?? TerrainType.grass;
  }

  /// Check if coordinates are within map bounds
  bool isInBounds(int q, int r) {
    if (r < 0 || r >= height) return false;
    int qStart = -(r ~/ 2);
    int qEnd = qStart + width;
    return q >= qStart && q < qEnd;
  }

  /// Get all hex coordinates in the map
  Iterable<({int q, int r})> get allCoordinates sync* {
    for (int r = 0; r < height; r++) {
      int qStart = -(r ~/ 2);
      int qEnd = qStart + width;
      for (int q = qStart; q < qEnd; q++) {
        yield (q: q, r: r);
      }
    }
  }

  /// Total number of hexes
  int get totalHexes => width * height;
}
