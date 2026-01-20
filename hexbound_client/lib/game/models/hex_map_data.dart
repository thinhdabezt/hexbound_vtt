import 'dart:math';
import 'terrain_type.dart';

/// Represents a rectangular hex map with terrain and fog data
class HexMapData {
  final int width;
  final int height;
  final Map<String, TerrainType> _tiles;
  final Set<String> _exploredTiles; // Fog of War state

  HexMapData._({
    required this.width,
    required this.height,
    required Map<String, TerrainType> tiles,
  })  : _tiles = tiles,
        _exploredTiles = {};

  /// Generate a random map with weighted terrain distribution
  factory HexMapData.generateRandom(int width, int height, {int? seed}) {
    final random = Random(seed);
    final tiles = <String, TerrainType>{};

    for (int r = 0; r < height; r++) {
      int qStart = -(r ~/ 2);
      int qEnd = qStart + width;

      for (int q = qStart; q < qEnd; q++) {
        final roll = random.nextDouble();
        TerrainType type;

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

  // ===== FOG OF WAR METHODS =====

  /// Check if a hex has been explored
  bool isExplored(int q, int r) => _exploredTiles.contains("$q,$r");

  /// Reveal a single hex
  void revealHex(int q, int r) {
    if (isInBounds(q, r)) {
      _exploredTiles.add("$q,$r");
    }
  }

  /// Reveal hex and all neighbors within radius
  void revealArea(int centerQ, int centerR, {int radius = 1}) {
    // Reveal center
    revealHex(centerQ, centerR);
    
    // Reveal neighbors using cube coordinates
    for (int dq = -radius; dq <= radius; dq++) {
      for (int dr = max(-radius, -dq - radius); dr <= min(radius, -dq + radius); dr++) {
        revealHex(centerQ + dq, centerR + dr);
      }
    }
  }

  /// Reveal random starting area near center
  void revealRandomStart({int radius = 1, int? seed}) {
    final random = Random(seed);
    
    // Pick random hex near center of map
    final centerR = height ~/ 2;
    final centerQ = -(centerR ~/ 2) + width ~/ 2;
    
    // Add some randomness
    final q = centerQ + random.nextInt(5) - 2;
    final r = centerR + random.nextInt(5) - 2;
    
    revealArea(q, r, radius: radius);
  }

  /// Get count of explored hexes
  int get exploredCount => _exploredTiles.length;

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
