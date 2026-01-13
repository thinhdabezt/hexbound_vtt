import 'dart:math';
import 'dart:ui';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/fractional_hex.dart';

class HexOrientation {
  final double f0, f1, f2, f3;
  final double b0, b1, b2, b3;
  final double startAngle;

  const HexOrientation(this.f0, this.f1, this.f2, this.f3, this.b0, this.b1, this.b2,
      this.b3, this.startAngle);

  static const HexOrientation pointy = HexOrientation(
      sqrt3, sqrt3 / 2.0, 0.0, 3.0 / 2.0, sqrt3 / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5);
  
  static const HexOrientation flat = HexOrientation(
      3.0 / 2.0, 0.0, sqrt3 / 2.0, sqrt3, 2.0 / 3.0, 0.0, -1.0 / 3.0, sqrt3 / 3.0, 0.0);
  
  static const double sqrt3 = 1.7320508075688772;
}

class Layout {
  final HexOrientation orientation;
  final Size size;
  final Offset origin;

  Layout(this.orientation, this.size, this.origin);

  Offset hexToPixel(Hex h) {
    HexOrientation M = orientation;
    double x = (M.f0 * h.q + M.f1 * h.r) * size.width;
    double y = (M.f2 * h.q + M.f3 * h.r) * size.height;
    return Offset(x + origin.dx, y + origin.dy);
  }

  FractionalHex pixelToHex(Offset p) {
    HexOrientation M = orientation;
    Offset pt = Offset(
        (p.dx - origin.dx) / size.width, (p.dy - origin.dy) / size.height);
    double q = M.b0 * pt.dx + M.b1 * pt.dy;
    double r = M.b2 * pt.dx + M.b3 * pt.dy;
    return FractionalHex(q, r, -q - r);
  }
}
