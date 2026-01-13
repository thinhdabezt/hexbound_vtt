import 'package:hexbound_client/game/hex_engine/hex.dart';

class FractionalHex {
  final double q;
  final double r;
  final double s;

  FractionalHex(this.q, this.r, this.s) {
    if ((q + r + s).abs() > 0.001) {
      throw ArgumentError("FractionalHex coordinates must sum to ~0");
    }
  }

  Hex round() {
    int qi = q.round();
    int ri = r.round();
    int si = s.round();

    double qDiff = (qi - q).abs();
    double rDiff = (ri - r).abs();
    double sDiff = (si - s).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      qi = -ri - si;
    } else if (rDiff > sDiff) {
      ri = -qi - si;
    } else {
      si = -qi - ri;
    }

    return Hex(qi, ri, si);
  }
}
