import 'package:flutter/material.dart';
import 'hex_engine/hex.dart';
import 'hex_engine/layout.dart';
import 'hex_engine/map_painter.dart';
import 'hex_engine/pathfinding.dart';
import 'hex_engine/fog_painter.dart';
import 'ui/combat_overlay.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class HexMapWidget extends StatefulWidget {
  const HexMapWidget({super.key});

  @override
  State<HexMapWidget> createState() => _HexMapWidgetState();
}

class _HexMapWidgetState extends State<HexMapWidget> {
  ui.Image? _tilesetImage;
  bool _isLoading = true;
  final TransformationController _transformationController = TransformationController();
  
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

  @override
  void initState() {
    super.initState();
    _loadTileset();
    _initSignalR();
  }
  
  Future<void> _initSignalR() async {
    const serverUrl = "http://localhost:5292/gameHub";
    _hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();

    _hubConnection.onclose(({error}) => debugPrint("SignalR Closed: $error"));

    // Game State Listeners
    _hubConnection.on("GameStateSync", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<dynamic, dynamic>;
        setState(() {
          _tokens = data.map((key, value) {
             final pos = value as Map<dynamic, dynamic>;
             return MapEntry(key.toString(), Hex(pos['q'] as int, pos['r'] as int, - (pos['q'] as int) - (pos['r'] as int)));
          });
        });
        debugPrint("GameState Synced: ${_tokens.length} tokens");
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
         debugPrint("Token Moved: $tokenId -> ($q, $r)");
       }
    });

    // Combat Listeners
    _hubConnection.on("CombatStarted", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final state = arguments[0] as Map<dynamic, dynamic>;
        setState(() {
          _turnOrder = (state['TurnOrder'] as List<dynamic>).cast<String>();
          _currentTurnIndex = state['CurrentTurnIndex'] as int;
          _isCombatActive = state['IsActive'] as bool;
          _combatLog = ["Combat Started! Round 1"];
        });
        debugPrint("Combat Started: ${_turnOrder.length} participants");
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

  Future<void> _loadTileset() async {
    try {
      final ByteData data = await rootBundle.load('assets/tiles/hex_tile_texture.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Image image = await decodeImageFromList(bytes);
      setState(() {
        _tilesetImage = image;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading tileset: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleTap(TapUpDetails details, Layout layout) {
    Offset local = details.localPosition;
    Hex clickedHex = layout.pixelToHex(local).round();
    
    setState(() {
      if (_startHex == null) {
        _startHex = clickedHex;
         if (_hubConnection.state == HubConnectionState.Connected && _myTokenId != null) {
           _hubConnection.invoke("MoveToken", args: [_myTokenId!, clickedHex.q, clickedHex.r]);
         }
      } else {
        if (_endHex == null) {
             _endHex = clickedHex;
            _currentPath = Pathfinding.findPath(_startHex!, _endHex!, _obstacles);
        } else {
            _startHex = clickedHex;
            _endHex = null;
            _currentPath = [];
             if (_hubConnection.state == HubConnectionState.Connected && _myTokenId != null) {
               _hubConnection.invoke("MoveToken", args: [_myTokenId!, clickedHex.q, clickedHex.r]);
             }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_tilesetImage == null) {
      return const Scaffold(body: Center(child: Text("Failed to load tileset")));
    }

    final layout = Layout(
      HexOrientation.pointy,
      Size(32, 32),
      Offset.zero,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(500.0),
            minScale: 0.1,
            maxScale: 4.0,
            constrained: false, 
            child: SizedBox(
              width: 2000, 
              height: 2000,
              child: GestureDetector(
                  onTapUp: (details) => _handleTap(details, layout),
                  child: CustomPaint(
                    painter: HexMapPainter(
                      layout, 
                      10, 
                      _tilesetImage!, 
                      _startHex, 
                      _currentPath,
                      _tokens
                    ), 
                  ),
              ),
            ),
          ),

          // Fog of War Layer
          IgnorePointer(
            child: CustomPaint(
              size: const Size(2000, 2000),
              painter: FogOfWarPainter(
                layout: layout,
                tokens: _tokens,
                visionRange: 4,
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
        ],
      ),
    );
  }
}
