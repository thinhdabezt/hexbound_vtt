import 'dart:math';

class Hex {
  final int q;
  final int r;
  final int s;

  Hex(this.q, this.r, this.s) {
    if (q + r + s != 0) {
      throw ArgumentError("Hex coordinates q, r, s must sum to 0");
    }
  }

  factory Hex.axial(int q, int r) {
    return Hex(q, r, -q - r);
  }

  Hex operator +(Hex other) => Hex(q + other.q, r + other.r, s + other.s);
  Hex operator -(Hex other) => Hex(q - other.q, r - other.r, s - other.s);
  Hex operator *(int k) => Hex(q * k, r * k, s * k);

  int length() => (q.abs() + r.abs() + s.abs()) ~/ 2;
  int distanceTo(Hex other) => (this - other).length();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hex &&
          runtimeType == other.runtimeType &&
          q == other.q &&
          r == other.r &&
          s == other.s;

  @override
  int get hashCode => Object.hash(q, r, s);

  @override
  String toString() => "Hex($q, $r, $s)";
}
