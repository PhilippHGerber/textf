// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';

void main() {
  group('DefaultStyles Tests', () {
    // Expected values are the literals from the PRD's defaults table (§6),
    // not re-derived from DefaultStyles. The palette colors (T-DEF-02 to
    // T-DEF-04 and the editing marker) are tested in textf_palette_test.dart.
    group('T-DEF neutral defaults', () {
      test('T-DEF-01: the default link color is #1A73E8', () {
        expect(DefaultStyles.defaultLinkColor, const Color(0xFF1A73E8));
      });

      group('T-DEF-05: link color meets WCAG AA without surface inference', () {
        // WCAG 2.x contrast ratio: (L_lighter + 0.05) / (L_darker + 0.05).
        double contrast(Color a, Color b) {
          final double la = a.computeLuminance();
          final double lb = b.computeLuminance();
          return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
        }

        test('reaches >= 4.5:1 against white', () {
          final ratio = contrast(DefaultStyles.defaultLinkColor, const Color(0xFFFFFFFF));
          expect(ratio, greaterThanOrEqualTo(4.5));
          expect(ratio, closeTo(4.51, 0.005));
        });

        test('reaches ≈4.16:1 against the #121212 dark surface', () {
          final ratio = contrast(DefaultStyles.defaultLinkColor, const Color(0xFF121212));
          // The PRD's "4.16:1" is rounded: the exact ratio is ≈ 4.1584, just
          // under 4.16. Assert the quoted figure within rounding, plus a floor.
          expect(ratio, closeTo(4.16, 0.005));
          expect(ratio, greaterThanOrEqualTo(4.15));
          expect(ratio, greaterThan(3)); // WCAG AA large-text / non-text floor
        });
      });
    });
  });
}
