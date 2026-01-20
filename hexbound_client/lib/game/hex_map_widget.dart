import 'package:flutter/material.dart';
import 'dart:math';
import 'hex_engine/hex.dart';
import 'hex_engine/layout.dart';
import 'hex_engine/pathfinding.dart';
import 'painters/terrain_painter.dart';
import 'painters/dynamic_painter.dart';
import 'painters/debug_overlay_painter.dart';
import 'painters/fog_hex_painter.dart';
import 'models/hex_map_data.dart';
import 'ui/combat_overlay.dart';
import 'package:signalr_netcore/signalr_client.dart';

class HexMapWidget extends StatefulWidget {
  const HexMapWidget({super.key});

  @override
  State<HexMapWidget> createState() => _HexMapWidgetState();
}

class _HexMapWidgetState extends State<HexMapWidget> {
  final TransformationController _transformationController = TransformationController();
  
  // Map Data (30x20 rectangular)
  late HexMapData _mapData;
  late Layout _layout;
  late Size _canvasSize;
  
  // Viewport Culling (O2) - will be set in initState
  late Rect _visibleWorldRect;
  
  // Interaction State
  Hex? _startHex;
  Hex? _endHex;
  List<Hex> _currentPath = [];
  final Set<Hex> _obstacles = {}; 

  // SignalR & Game State
  late HubConnection _hubConnection;
  Map<String, Hex> _tokens = {};
  String? _myTokenId;

  // Combat State
  List<String> _combatLog = [];
  List<String> _turnOrder = [];
  int _currentTurnIndex = 0;
  bool _isCombatActive = false;

  // Debug State
  bool _showDebugGrid = false;
  bool _showDebugCoords = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize map data (30x20 rectangular)
    _mapData = HexMapData.generateRandom(30, 20, seed: 42);
    
    // Reveal random starting area (1 center + 6 neighbors = 7 hexes)
    _mapData.revealRandomStart(radius: 1);
    
    // Initialize layout
    _layout = Layout(
      HexOrientation.pointy,
      const Size(32, 32),
      const Offset(100, 100),
    );
    
    // Calculate canvas size
    final hexWidth = _layout.size.width * sqrt(3);
    final hexHeight = _layout.size.height * 2;
    _canvasSize = Size(
      _mapData.width * hexWidth + hexWidth,
      _mapData.height * hexHeight * 0.75 + hexHeight,
    );
    
    // Initialize visible rect to full canvas
    _visibleWorldRect = Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height);
    
    // Listen to transform changes for viewport culling
    _transformationController.addListener(_onTransformChanged);
    
    _initSignalR();
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
    // Calculate initial visible rect after we have context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibleRect();
    });
  }
  
  void _updateVisibleRect() {
    final screenSize = MediaQuery.of(context).size;
    final transform = _transformationController.value;
    
    // Invert transform to get world coordinates
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    
    // Screen corners in world space
    final topLeft = MatrixUtils.transformPoint(inverseTransform, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverseTransform, 
      Offset(screenSize.width, screenSize.height)
    );
    
    final newRect = Rect.fromPoints(topLeft, bottomRight);
    
    // Only update if significantly changed (avoid excessive repaints)
    if ((newRect.left - _visibleWorldRect.left).abs() > 10 ||
        (newRect.top - _visibleWorldRect.top).abs() > 10 ||
        (newRect.right - _visibleWorldRect.right).abs() > 10 ||
        (newRect.bottom - _visibleWorldRect.bottom).abs() > 10) {
      setState(() {
        _visibleWorldRect = newRect;
      });
    }
  }
  
  Future<void> _initSignalR() async {
    const serverUrl = "http://localhost:5292/gameHub";
    _hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();

    _hubConnection.onclose(({error}) => debugPrint("SignalR Closed: $error"));

    _hubConnection.on("GameStateSync", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<dynamic, dynamic>;
        setState(() {
          _tokens = data.map((key, value) {
             final pos = value as Map<dynamic, dynamic>;
             return MapEntry(key.toString(), Hex(pos['q'] as int, pos['r'] as int, - (pos['q'] as int) - (pos['r'] as int)));
          });
        });
      }
    });

    _hubConnection.on("TokenMoved", (arguments) {
       if (arguments != null && arguments.length >= 3) {
         final tokenId = arguments[0] as String;
         final q = arguments[1] as int;
         final r = arguments[2] as int;
         setState(() {
           _tokens[tokenId] = Hex.axial(q, r);
         });
       }
    });

    _hubConnection.on("CombatStarted", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final state = arguments[0] as Map<dynamic, dynamic>;
        setState(() {
          _turnOrder = (state['TurnOrder'] as List<dynamic>).cast<String>();
          _currentTurnIndex = state['CurrentTurnIndex'] as int;
          _isCombatActive = state['IsActive'] as bool;
          _combatLog = ["Combat Started! Round 1"];
        });
      }
    });

    _hubConnection.on("TurnChanged", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final state = arguments[0] as Map<dynamic, dynamic>;
        setState(() {
          _currentTurnIndex = state['CurrentTurnIndex'] as int;
          final round = state['RoundNumber'] as int;
          _combatLog.add("Round $round - ${_turnOrder[_currentTurnIndex]}'s turn");
        });
      }
    });

    _hubConnection.on("CombatLog", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final message = arguments[0] as String;
        setState(() {
          _combatLog.add(message);
        });
      }
    });

    try {
      await _hubConnection.start();
      debugPrint("SignalR Connected");
      _myTokenId = "Player_${DateTime.now().millisecondsSinceEpoch % 1000}";
    } catch (e) {
      debugPrint("SignalR Connection Error: $e");
    }
  }

  void _handleTap(TapUpDetails details) {
    Offset local = details.localPosition;
    Hex clickedHex = _layout.pixelToHex(local).round();
    
    if (!_mapData.isInBounds(clickedHex.q, clickedHex.r)) return;
    
    setState(() {
      // Reveal clicked hex and surrounding area
      _mapData.revealArea(clickedHex.q, clickedHex.r, radius: 2);
      
      // Update selection for pathfinding
      if (_startHex == null) {
        _startHex = clickedHex;
      } else {
        if (_endHex == null) {
          _endHex = clickedHex;
          _currentPath = Pathfinding.findPath(_startHex!, _endHex!, _obstacles);
        } else {
          _startHex = clickedHex;
          _endHex = null;
          _currentPath = [];
        }
      }
      
      // Sync token with backend if connected
      _myTokenId ??= "LocalPlayer_${DateTime.now().millisecondsSinceEpoch % 1000}";
      _tokens[_myTokenId!] = clickedHex;
      
      if (_hubConnection.state == HubConnectionState.Connected) {
        _hubConnection.invoke("MoveToken", args: [_myTokenId!, clickedHex.q, clickedHex.r]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    // Layer 1: Static Terrain with Culling
                    RepaintBoundary(
                      child: CustomPaint(
                        size: _canvasSize,
                        painter: TerrainPainter(_layout, _mapData, _visibleWorldRect),
                        isComplex: true,
                        willChange: false,
                      ),
                    ),
                    
                    // Layer 2: Dynamic Content with Culling
                    RepaintBoundary(
                      child: CustomPaint(
                        size: _canvasSize,
                        painter: DynamicPainter(
                          layout: _layout,
                          visibleRect: _visibleWorldRect,
                          selectedHex: _startHex,
                          path: _currentPath,
                          tokens: _tokens,
                        ),
                      ),
                    ),
                    
                    // Layer 3: Debug Overlay
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
                    
                    // Layer 4: Hex-based Fog of War
                    RepaintBoundary(
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: _canvasSize,
                          painter: FogHexPainter(
                            layout: _layout,
                            mapData: _mapData,
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
                "Map: ${_mapData.width}x${_mapData.height} | Viewport Culling: ON",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
