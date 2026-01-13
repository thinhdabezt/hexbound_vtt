import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'dart:ui';
import 'package:hexbound_client/game/hex_engine/hex.dart';
import 'package:hexbound_client/game/hex_engine/layout.dart';

void main() {
  group('Hex Core Tests', () {
    test('Hex Constructor validates sum to 0', () {
      expect(() => Hex(1, 1, 1), throwsArgumentError);
      expect(Hex(1, -1, 0).s, 0);
    });

    test('Hex Axial Constructor', () {
      var h = Hex.axial(2, -5);
      expect(h.q, 2);
      expect(h.r, -5);
      expect(h.s, 3); // -2 - (-5) = 3
    });

    test('Hex Arithmetic', () {
      var h1 = Hex(1, -2, 1);
      var h2 = Hex(-3, 4, -1);
      var sum = h1 + h2;
      expect(sum, Hex(-2, 2, 0));
    });

    test('Conversion Roundtrip (Pointy)', () {
      var layout = Layout(Orientation.pointy, Size(32, 32), Offset.zero);
      var h = Hex(3, -7, 4);
      
      var pixel = layout.hexToPixel(h);
      var roundtripHex = layout.pixelToHex(pixel).round();
      
      expect(roundtripHex, h);
    });

    test('Conversion Precision', () {
      var layout = Layout(Orientation.pointy, Size(10, 10), Offset(100, 100));
      // Pick a pixel slightly off center of a hex
      var h = Hex(1, 2, -3); // Expected hex
      var center = layout.hexToPixel(h);
      var offCenter = center + Offset(1, 1); // Small offset should still be within hex
      
      var calculated = layout.pixelToHex(offCenter).round();
      expect(calculated, h);
    });
  });
}
