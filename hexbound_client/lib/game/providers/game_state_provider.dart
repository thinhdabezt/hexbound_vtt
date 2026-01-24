import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../hex_engine/hex.dart';
import '../models/hex_map_data.dart';
import '../models/token_stats.dart';

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

// ===== TOKEN STATS PROVIDER =====
final tokenStatsProvider = StateNotifierProvider<TokenStatsNotifier, Map<String, TokenStats>>((ref) {
  return TokenStatsNotifier();
});

class TokenStatsNotifier extends StateNotifier<Map<String, TokenStats>> {
  TokenStatsNotifier() : super({});
  
  void syncAll(List<TokenStats> statsList) {
    state = {for (var s in statsList) s.tokenId: s};
  }
  
  void update(TokenStats stats) {
    state = {...state, stats.tokenId: stats};
  }
  
  TokenStats? get(String tokenId) => state[tokenId];
}

// ===== MAP DATA PROVIDER =====
final mapDataProvider = StateNotifierProvider<MapDataNotifier, HexMapData>((ref) {
  return MapDataNotifier();
});

class MapDataNotifier extends StateNotifier<HexMapData> {
  MapDataNotifier() : super(HexMapData.generateRandom(30, 20, seed: 42)) {
    state.revealRandomStart(radius: 1);
  }
  
  void revealArea(int q, int r, {int radius = 2}) {
    state.revealArea(q, r, radius: radius);
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
    
    _connection!.onclose(({error}) {});

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

    // Token Stats Sync
    _connection!.on("TokenStatsSync", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rawList = arguments[0] as List<dynamic>;
        final list = rawList
            .map((e) => TokenStats.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        ref.read(tokenStatsProvider.notifier).syncAll(list);
      }
    });

    // Token Stats Updated
    _connection!.on("TokenStatsUpdated", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rawData = arguments[0] as Map;
        final stats = TokenStats.fromJson(Map<String, dynamic>.from(rawData));
        ref.read(tokenStatsProvider.notifier).update(stats);
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
    ref.read(tokensProvider.notifier).updateToken(tokenId, Hex.axial(q, r));
  }

  Future<void> updateTokenStats(TokenStats stats) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke("UpdateTokenStats", args: [stats.toJson()]);
    }
    ref.read(tokenStatsProvider.notifier).update(stats);
  }

  Future<void> dealDamage(String tokenId, int damage) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke("DealDamage", args: [tokenId, damage]);
    }
  }
}

