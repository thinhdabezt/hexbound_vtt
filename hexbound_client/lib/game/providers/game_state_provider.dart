import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../hex_engine/hex.dart';
import '../models/hex_map_data.dart';

// ===== TOKEN PROVIDER =====
final tokensProvider = StateNotifierProvider<TokensNotifier, Map<String, Hex>>((ref) {
  return TokensNotifier();
});

class TokensNotifier extends StateNotifier<Map<String, Hex>> {
  TokensNotifier() : super({});
  
  void updateToken(String id, Hex hex) {
    state = {...state, id: hex};
  }
  
  void updateTokens(Map<String, Hex> tokens) {
    state = {...state, ...tokens};
  }
  
  void setAll(Map<String, Hex> tokens) {
    state = tokens;
  }
}

// ===== MAP DATA PROVIDER =====
final mapDataProvider = StateNotifierProvider<MapDataNotifier, HexMapData>((ref) {
  return MapDataNotifier();
});

class MapDataNotifier extends StateNotifier<HexMapData> {
  MapDataNotifier() : super(HexMapData.generateRandom(30, 20, seed: 42)) {
    // Reveal random starting area
    state.revealRandomStart(radius: 1);
  }
  
  void revealArea(int q, int r, {int radius = 2}) {
    state.revealArea(q, r, radius: radius);
    // Trigger rebuild by updating state reference
    state = state;
  }
}

// ===== SELECTION PROVIDER =====
final selectedHexProvider = StateProvider<Hex?>((ref) => null);
final endHexProvider = StateProvider<Hex?>((ref) => null);
final currentPathProvider = StateProvider<List<Hex>>((ref) => []);

// ===== SIGNALR SERVICE =====
final signalRServiceProvider = Provider<SignalRService>((ref) {
  return SignalRService(ref);
});

class SignalRService {
  final Ref ref;
  HubConnection? _connection;
  Timer? _debounceTimer;
  final Map<String, Hex> _pendingTokenUpdates = {};
  String? myTokenId;

  SignalRService(this.ref);

  HubConnection? get connection => _connection;

  Future<void> connect(String url) async {
    _connection = HubConnectionBuilder().withUrl(url).build();
    
    _connection!.onclose(({error}) {
      // Handle disconnection
    });

    // Game State Sync
    _connection!.on("GameStateSync", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<dynamic, dynamic>;
        final tokens = data.map((key, value) {
          final pos = value as Map<dynamic, dynamic>;
          return MapEntry(
            key.toString(),
            Hex(pos['q'] as int, pos['r'] as int, -(pos['q'] as int) - (pos['r'] as int)),
          );
        });
        ref.read(tokensProvider.notifier).setAll(tokens);
      }
    });

    // Token Moved - with debounce
    _connection!.on("TokenMoved", (arguments) {
      if (arguments != null && arguments.length >= 3) {
        final tokenId = arguments[0] as String;
        final q = arguments[1] as int;
        final r = arguments[2] as int;
        _pendingTokenUpdates[tokenId] = Hex.axial(q, r);
        _debounceFlush();
      }
    });

    try {
      await _connection!.start();
      myTokenId = "Player_${DateTime.now().millisecondsSinceEpoch % 1000}";
    } catch (e) {
      // Connection failed
    }
  }

  void _debounceFlush() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (_pendingTokenUpdates.isNotEmpty) {
        ref.read(tokensProvider.notifier).updateTokens(Map.from(_pendingTokenUpdates));
        _pendingTokenUpdates.clear();
      }
    });
  }

  Future<void> moveToken(String tokenId, int q, int r) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke("MoveToken", args: [tokenId, q, r]);
    }
    // Update locally as well
    ref.read(tokensProvider.notifier).updateToken(tokenId, Hex.axial(q, r));
  }
}
