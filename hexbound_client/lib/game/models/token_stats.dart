/// Token Combat Statistics Model
class TokenStats {
  final String tokenId;
  final String name;
  final int maxHp;
  int currentHp;
  final int armorClass;
  final int speed;
  final int initiativeModifier;
  List<String> conditions;
  int q;
  int r;

  TokenStats({
    required this.tokenId,
    this.name = "Unknown",
    this.maxHp = 10,
    int? currentHp,
    this.armorClass = 10,
    this.speed = 6,
    this.initiativeModifier = 0,
    List<String>? conditions,
    this.q = 0,
    this.r = 0,
  })  : currentHp = currentHp ?? maxHp,
        conditions = conditions ?? [];

  bool get isAlive => currentHp > 0;
  double get hpPercentage => maxHp > 0 ? currentHp.toDouble() / maxHp.toDouble() : 0.0;

  factory TokenStats.fromJson(Map<String, dynamic> json) => TokenStats(
        tokenId: json['tokenId'] ?? '',
        name: json['name'] ?? 'Unknown',
        maxHp: json['maxHp'] ?? 10,
        currentHp: json['currentHp'],
        armorClass: json['armorClass'] ?? 10,
        speed: json['speed'] ?? 6,
        initiativeModifier: json['initiativeModifier'] ?? 0,
        conditions: List<String>.from(json['conditions'] ?? []),
        q: json['q'] ?? 0,
        r: json['r'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'name': name,
        'maxHp': maxHp,
        'currentHp': currentHp,
        'armorClass': armorClass,
        'speed': speed,
        'initiativeModifier': initiativeModifier,
        'conditions': conditions,
        'q': q,
        'r': r,
      };
}
