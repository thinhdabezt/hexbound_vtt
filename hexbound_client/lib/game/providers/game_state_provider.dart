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

// ===== COMBAT STATE =====
class CombatState {
  final List<String> turnOrder;
  final Map<String, int> initiativeRolls;
  final int currentTurnIndex;
  final int roundNumber;
  final bool isActive;

  CombatState({
    this.turnOrder = const [],
    this.initiativeRolls = const {},
    this.currentTurnIndex = 0,
    this.roundNumber = 1,
    this.isActive = false,
  });

  factory CombatState.fromJson(Map<String, dynamic> json) => CombatState(
    turnOrder: List<String>.from(json['turnOrder'] ?? []),
    initiativeRolls: Map<String, int>.from(
      (json['initiativeRolls'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {}
    ),
    currentTurnIndex: json['currentTurnIndex'] ?? 0,
    roundNumber: json['roundNumber'] ?? 1,
    isActive: json['isActive'] ?? false,
  );

  CombatState copyWith({
    List<String>? turnOrder,
    Map<String, int>? initiativeRolls,
    int? currentTurnIndex,
    int? roundNumber,
    bool? isActive,
  }) => CombatState(
    turnOrder: turnOrder ?? this.turnOrder,
    initiativeRolls: initiativeRolls ?? this.initiativeRolls,
    currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
    roundNumber: roundNumber ?? this.roundNumber,
    isActive: isActive ?? this.isActive,
  );
}

final combatStateProvider = StateNotifierProvider<CombatStateNotifier, CombatState>((ref) {
  return CombatStateNotifier();
});

class CombatStateNotifier extends StateNotifier<CombatState> {
  CombatStateNotifier() : super(CombatState());
  
  void setCombatState(CombatState newState) {
    state = newState;
  }
  
  void nextTurn() {
    if (!state.isActive || state.turnOrder.isEmpty) return;
    var nextIndex = state.currentTurnIndex + 1;
    var nextRound = state.roundNumber;
    if (nextIndex >= state.turnOrder.length) {
      nextIndex = 0;
      nextRound++;
    }
    state = state.copyWith(currentTurnIndex: nextIndex, roundNumber: nextRound);
  }
  
  void endCombat() {
    state = CombatState();
  }
}

// ===== COMBAT LOG =====
final combatLogProvider = StateNotifierProvider<CombatLogNotifier, List<String>>((ref) {
  return CombatLogNotifier();
});

class CombatLogNotifier extends StateNotifier<List<String>> {
  CombatLogNotifier() : super([]);
  
  void addLog(String message) {
    state = [...state, message];
  }
  
  void clear() {
    state = [];
  }
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

    // Combat Started
    _connection!.on("CombatStarted", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rawData = arguments[0] as Map;
        final state = CombatState.fromJson(Map<String, dynamic>.from(rawData));
        ref.read(combatStateProvider.notifier).setCombatState(state);
      }
    });

    // Combat Log
    _connection!.on("CombatLog", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final message = arguments[0] as String;
        ref.read(combatLogProvider.notifier).addLog(message);
      }
    });

    // Combat State Updated (Turn changes)
    _connection!.on("CombatStateUpdated", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rawData = arguments[0] as Map;
        final state = CombatState.fromJson(Map<String, dynamic>.from(rawData));
        ref.read(combatStateProvider.notifier).setCombatState(state);
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

  Future<void> startCombat(List<String> participantIds) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke("StartCombat", args: [participantIds]);
    }
  }

  Future<void> endTurn() async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke("EndTurn");
    }
  }

  Future<void> healToken(String tokenId, int amount) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!.invoke("HealToken", args: [tokenId, amount]);
    }
  }
}

