import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'hex_engine/hex.dart';
import 'hex_engine/layout.dart';
import 'hex_engine/pathfinding.dart';
import 'painters/terrain_painter.dart';
import 'painters/dynamic_painter.dart';
import 'painters/debug_overlay_painter.dart';
import 'painters/fog_hex_painter.dart';
import 'providers/game_state_provider.dart';
import 'models/token_stats.dart';
import 'ui/combat_overlay.dart';

class HexMapWidget extends ConsumerStatefulWidget {
  const HexMapWidget({super.key});

  @override
  ConsumerState<HexMapWidget> createState() => _HexMapWidgetState();
}

class _HexMapWidgetState extends ConsumerState<HexMapWidget> {
  final TransformationController _transformationController = TransformationController();
  
  // Layout (static)
  late Layout _layout;
  late Size _canvasSize;
  
  // Viewport Culling
  Rect _visibleWorldRect = Rect.largest;
  
  // Debug State
  bool _showDebugGrid = false;
  bool _showDebugCoords = false;

  // Combat State (local for now)
  List<String> _combatLog = [];
  List<String> _turnOrder = [];
  int _currentTurnIndex = 0;
  bool _isCombatActive = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize layout
    _layout = Layout(
      HexOrientation.pointy,
      const Size(32, 32),
      const Offset(100, 100),
    );
    
    // Calculate canvas size (30x20 map)
    final hexWidth = _layout.size.width * sqrt(3);
    final hexHeight = _layout.size.height * 2;
    _canvasSize = Size(
      30 * hexWidth + hexWidth,
      20 * hexHeight * 0.75 + hexHeight,
    );
    
    // Initialize visible rect
    _visibleWorldRect = Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height);
    
    // Listen to transform changes
    _transformationController.addListener(_onTransformChanged);
    
    // Connect SignalR after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signalRServiceProvider).connect("http://localhost:5292/gameHub");
      
      // Add test token with stats for HP bar testing
      _createTestToken();
    });
  }
  
  void _createTestToken() {
    // Create test token at position (10, 10)
    const testTokenId = "TestPlayer1";
    ref.read(tokensProvider.notifier).updateToken(testTokenId, Hex.axial(10, 10));
    
    // Create stats with 70% HP for testing
    final testStats = TokenStats(
      tokenId: testTokenId,
      name: "Hero",
      maxHp: 20,
      currentHp: 14, // 70% HP - should be green
    );
    ref.read(tokenStatsProvider.notifier).update(testStats);
    
    // Create second test token with low HP
    const testTokenId2 = "TestPlayer2";
    ref.read(tokensProvider.notifier).updateToken(testTokenId2, Hex.axial(12, 10));
    
    final testStats2 = TokenStats(
      tokenId: testTokenId2,
      name: "Wounded",
      maxHp: 20,
      currentHp: 4, // 20% HP - should be red
    );
    ref.read(tokenStatsProvider.notifier).update(testStats2);
  }
  
  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }
  
  void _onTransformChanged() {
    _updateVisibleRect();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibleRect();
    });
  }
  
  void _updateVisibleRect() {
    final screenSize = MediaQuery.of(context).size;
    final transform = _transformationController.value;
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    
    final topLeft = MatrixUtils.transformPoint(inverseTransform, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverseTransform, 
      Offset(screenSize.width, screenSize.height)
    );
    
    final newRect = Rect.fromPoints(topLeft, bottomRight);
    
    if ((newRect.left - _visibleWorldRect.left).abs() > 10 ||
        (newRect.top - _visibleWorldRect.top).abs() > 10 ||
        (newRect.right - _visibleWorldRect.right).abs() > 10 ||
        (newRect.bottom - _visibleWorldRect.bottom).abs() > 10) {
      setState(() {
        _visibleWorldRect = newRect;
      });
    }
  }

  void _handleTap(TapUpDetails details) {
    final mapData = ref.read(mapDataProvider);
    final signalR = ref.read(signalRServiceProvider);
    
    Offset local = details.localPosition;
    Hex clickedHex = _layout.pixelToHex(local).round();
    
    if (!mapData.isInBounds(clickedHex.q, clickedHex.r)) return;
    
    // Reveal clicked area
    ref.read(mapDataProvider.notifier).revealArea(clickedHex.q, clickedHex.r, radius: 2);
    
    // Update selection
    final currentSelected = ref.read(selectedHexProvider);
    if (currentSelected == null) {
      ref.read(selectedHexProvider.notifier).state = clickedHex;
    } else {
      final endHex = ref.read(endHexProvider);
      if (endHex == null) {
        ref.read(endHexProvider.notifier).state = clickedHex;
        final path = Pathfinding.findPath(currentSelected, clickedHex, {});
        ref.read(currentPathProvider.notifier).state = path;
      } else {
        ref.read(selectedHexProvider.notifier).state = clickedHex;
        ref.read(endHexProvider.notifier).state = null;
        ref.read(currentPathProvider.notifier).state = [];
      }
    }
    
    // Move token
    signalR.myTokenId ??= "LocalPlayer_${DateTime.now().millisecondsSinceEpoch % 1000}";
    signalR.moveToken(signalR.myTokenId!, clickedHex.q, clickedHex.r);
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final mapData = ref.watch(mapDataProvider);
    final tokens = ref.watch(tokensProvider);
    final tokenStats = ref.watch(tokenStatsProvider);
    final selectedHex = ref.watch(selectedHexProvider);
    final currentPath = ref.watch(currentPathProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Map with InteractiveViewer
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(200.0),
            minScale: 0.3,
            maxScale: 3.0,
            constrained: false,
            onInteractionUpdate: (_) => _updateVisibleRect(),
            child: SizedBox(
              width: _canvasSize.width,
              height: _canvasSize.height,
              child: GestureDetector(
                onTapUp: _handleTap,
                child: Stack(
                  children: [
                    // Layer 1: Terrain
                    RepaintBoundary(
                      child: CustomPaint(
                        size: _canvasSize,
                        painter: TerrainPainter(_layout, mapData, _visibleWorldRect),
                        isComplex: true,
                        willChange: false,
                      ),
                    ),
                    
                    // Layer 2: Dynamic (tokens, path, selection)
                    RepaintBoundary(
                      child: CustomPaint(
                        size: _canvasSize,
                        painter: DynamicPainter(
                          layout: _layout,
                          visibleRect: _visibleWorldRect,
                          selectedHex: selectedHex,
                          path: currentPath,
                          tokens: tokens,
                          tokenStats: tokenStats,
                        ),
                      ),
                    ),
                    
                    // Layer 3: Debug
                    if (_showDebugGrid || _showDebugCoords)
                      RepaintBoundary(
                        child: CustomPaint(
                          size: _canvasSize,
                          painter: DebugOverlayPainter(
                            layout: _layout,
                            radius: 15,
                            showGrid: _showDebugGrid,
                            showCoordinates: _showDebugCoords,
                          ),
                        ),
                      ),
                    
                    // Layer 4: Fog
                    RepaintBoundary(
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: _canvasSize,
                          painter: FogHexPainter(
                            layout: _layout,
                            mapData: mapData,
                            visibleRect: _visibleWorldRect,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Combat UI Overlay
          CombatOverlay(
            combatLog: _combatLog,
            turnOrder: _turnOrder,
            currentTurnIndex: _currentTurnIndex,
            isActive: _isCombatActive,
          ),

          // Debug Toggle FAB
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: "debug_coords",
                  backgroundColor: _showDebugCoords ? Colors.amber : Colors.grey[800],
                  onPressed: () => setState(() => _showDebugCoords = !_showDebugCoords),
                  child: const Text("Q,R", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "debug_grid",
                  backgroundColor: _showDebugGrid ? Colors.amber : Colors.grey[800],
                  onPressed: () => setState(() => _showDebugGrid = !_showDebugGrid),
                  child: Icon(_showDebugGrid ? Icons.grid_off : Icons.grid_on, size: 20),
                ),
              ],
            ),
          ),
          
          // Map Info
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Map: ${mapData.width}x${mapData.height} | Riverpod State",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
