import 'package:collection/collection.dart';
import 'hex.dart';
import 'dart:math';

class Pathfinding {
  
  // A* Algorithm
  static List<Hex> findPath(Hex start, Hex end, Set<Hex> obstacles) {
    if (obstacles.contains(end) || obstacles.contains(start)) {
      return [];
    }

    final PriorityQueue<HexNode> frontier = PriorityQueue<HexNode>((a, b) => a.priority.compareTo(b.priority));
    frontier.add(HexNode(start, 0));

    final Map<Hex, Hex?> cameFrom = {};
    final Map<Hex, int> costSoFar = {};

    cameFrom[start] = null;
    costSoFar[start] = 0;

    while (frontier.isNotEmpty) {
      final current = frontier.removeFirst().hex;

      if (current == end) {
        break;
      }

      for (final next in _getNeighbors(current)) {
        if (obstacles.contains(next)) {
          continue;
        }

        final newCost = costSoFar[current]! + 1; // Assuming uniform cost of 1 per tile

        if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
          costSoFar[next] = newCost;
          final priority = newCost + current.distanceTo(end); // Heuristic: straight line distance
          frontier.add(HexNode(next, priority));
          cameFrom[next] = current;
        }
      }
    }

    if (!cameFrom.containsKey(end)) {
      return []; // No path found
    }

    // Reconstruct path
    final List<Hex> path = [];
    Hex? current = end;
    while (current != null) {
      path.add(current);
      current = cameFrom[current];
    }
    
    return path.reversed.toList();
  }

  static List<Hex> _getNeighbors(Hex h) {
    // 6 directions for pointy top/flat top are the same in cube coords relative logic
    // Directions: 
    // (+1, 0, -1), (+1, -1, 0), (0, -1, +1), 
    // (-1, 0, +1), (-1, +1, 0), (0, +1, -1)
    final directions = [
      Hex(1, 0, -1), Hex(1, -1, 0), Hex(0, -1, 1),
      Hex(-1, 0, 1), Hex(-1, 1, 0), Hex(0, 1, -1)
    ];
    
    return directions.map((d) => h + d).toList();
  }
}

class HexNode {
  final Hex hex;
  final num priority;

  HexNode(this.hex, this.priority);
}
