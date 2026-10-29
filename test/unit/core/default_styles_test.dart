// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';

void main() {
  group('DefaultStyles Tests', () {
    // Expected values are the literals from the PRD's defaults table (§6),
    // not re-derived from DefaultStyles.
    group('T-DEF neutral defaults', () {
      test('T-DEF-01: the default link color is #1A73E8', () {
        expect(DefaultStyles.defaultLinkColor, const Color(0xFF1A73E8));
      });

      group('T-DEF-02: code chip background', () {
        test('alphas are 0.05 on light surfaces and 0.15 on dark surfaces', () {
          expect(DefaultStyles.codeBackgroundAlphaLight, 0.05);
          expect(DefaultStyles.codeBackgroundAlphaDark, 0.15);
        });

        test('tints the foreground at 0.05 on a light surface', () {
          final bg = DefaultStyles.codeBackgroundColor(const Color(0xFF000000), Brightness.light);
          expect(bg, const Color(0xFF000000).withValues(alpha: 0.05));
        });

        test('tints the foreground at 0.15 on a dark surface', () {
          final bg = DefaultStyles.codeBackgroundColor(const Color(0xFFE6E0E9), Brightness.dark);
          expect(bg, const Color(0xFFE6E0E9).withValues(alpha: 0.15));
        });

        test('replaces rather than compounds a translucent foreground alpha', () {
          final bg = DefaultStyles.codeBackgroundColor(const Color(0x80FFFFFF), Brightness.dark);
          expect(bg.a, closeTo(0.15, 1e-9));
        });
      });

      group('T-DEF-03: highlight tint', () {
        test('is yellow #FFEB3B at 0.5 on a light surface', () {
          expect(DefaultStyles.highlightColorLight, const Color(0xFFFFEB3B));
          expect(DefaultStyles.highlightAlphaLight, 0.5);
          expect(
            DefaultStyles.highlightBackgroundColor(Brightness.light),
            const Color(0xFFFFEB3B).withValues(alpha: 0.5),
          );
        });

        test('is dark yellow #FBC02D at 0.4 on a dark surface', () {
          expect(DefaultStyles.highlightColorDark, const Color(0xFFFBC02D));
          expect(DefaultStyles.highlightAlphaDark, 0.4);
          expect(
            DefaultStyles.highlightBackgroundColor(Brightness.dark),
            const Color(0xFFFBC02D).withValues(alpha: 0.4),
          );
        });
      });

      test('T-DEF-04: the thematic break alpha is 0.20', () {
        expect(DefaultStyles.thematicBreakAlpha, 0.20);
      });

      group('editing marker', () {
        test('dims the foreground to alpha 0.4', () {
          expect(DefaultStyles.editingMarkerAlpha, 0.4);
          expect(
            DefaultStyles.editingMarkerColor(const Color(0xFF123456)),
            const Color(0x66123456),
          );
        });

        test('replaces rather than compounds a translucent foreground alpha', () {
          expect(
            DefaultStyles.editingMarkerColor(const Color(0x33FFFFFF)),
            const Color(0x66FFFFFF),
          );
        });
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
