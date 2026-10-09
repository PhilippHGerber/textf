// T-PAL-01: TextfPalette unit tests.
//
// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/styling/textf_palette.dart';

void main() {
  group('T-PAL-01 TextfPalette', () {
    group('foreground', () {
      test('is the color of the effective style', () {
        final palette = TextfPalette(const TextStyle(color: Color(0xFF336699)));

        expect(palette.foreground, const Color(0xFF336699));
      });

      test('defaults to opaque black when the style has no color', () {
        expect(TextfPalette(const TextStyle(fontSize: 20)).foreground, const Color(0xFF000000));
      });

      test('defaults to opaque black when there is no style at all', () {
        expect(TextfPalette(null).foreground, const Color(0xFF000000));
      });
    });

    group('surface', () {
      Brightness surfaceFor(int argb) => TextfPalette(TextStyle(color: Color(argb))).surface;

      test('dark text implies a light surface', () {
        expect(surfaceFor(0xFF000000), Brightness.light);
        expect(surfaceFor(0xDD000000), Brightness.light); // black87: alpha is ignored
        expect(surfaceFor(0xFF1D1B20), Brightness.light); // M3 onSurface (light)
        expect(surfaceFor(0xFF757575), Brightness.light); // grey-600
      });

      test('light text implies a dark surface', () {
        expect(surfaceFor(0xFFFFFFFF), Brightness.dark);
        expect(surfaceFor(0xFFE6E0E9), Brightness.dark); // M3 onSurface (dark)
      });

      test('an unset color implies a light surface', () {
        expect(TextfPalette(null).surface, Brightness.light);
        expect(TextfPalette(const TextStyle()).surface, Brightness.light);
      });

      // (L + 0.05)^2 > 0.15  <=>  L > sqrt(0.15) - 0.05 ≈ 0.33730.
      // #9D9D9D has L ≈ 0.3372 (just below), #9E9E9E (grey-500) L ≈ 0.3419 (just above).
      test('classifies across the (L + 0.05)^2 > 0.15 threshold', () {
        expect(const Color(0xFF9D9D9D).computeLuminance(), lessThan(0.3373));
        expect(const Color(0xFF9E9E9E).computeLuminance(), greaterThan(0.3373));

        expect(surfaceFor(0xFF9D9D9D), Brightness.light);
        expect(surfaceFor(0xFF9E9E9E), Brightness.dark);
      });
    });

    group('equality', () {
      test('palettes from styles with the same color are equal, whatever else differs', () {
        final a = TextfPalette(const TextStyle(color: Color(0xFF336699), fontSize: 12));
        final b = TextfPalette(
          const TextStyle(color: Color(0xFF336699), fontSize: 28, fontWeight: FontWeight.bold),
        );

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('a missing color and explicit opaque black give equal palettes', () {
        final implicit = TextfPalette(null);
        final explicit = TextfPalette(const TextStyle(color: Color(0xFF000000)));

        expect(implicit, equals(explicit));
        expect(implicit.hashCode, explicit.hashCode);
      });

      test('palettes with different foregrounds are not equal', () {
        final black = TextfPalette(const TextStyle(color: Color(0xFF000000)));
        final white = TextfPalette(const TextStyle(color: Color(0xFFFFFFFF)));
        // Same surface, different foreground: still distinct.
        final navy = TextfPalette(const TextStyle(color: Color(0xFF000080)));

        expect(black, isNot(equals(white)));
        expect(black, isNot(equals(navy)));
        expect(black.surface, navy.surface);
      });

      test('is usable as a map key', () {
        final cache = <TextfPalette, String>{
          TextfPalette(const TextStyle(color: Color(0xFFFFFFFF))): 'dark',
        };

        expect(cache[TextfPalette(const TextStyle(color: Color(0xFFFFFFFF), fontSize: 9))], 'dark');
        expect(cache[TextfPalette(null)], isNull);
      });
    });
  });
}
