// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';

void main() {
  group('DefaultStyles Tests', () {
    const baseStyle = TextStyle(fontSize: 16, color: Color(0xFF2196F3), fontFamily: 'Roboto');

    group('boldStyle', () {
      test('applies bold font weight and preserves other properties', () {
        final newStyle = DefaultStyles.boldStyle(baseStyle);
        expect(newStyle.fontWeight, FontWeight.bold);
        expect(newStyle.fontSize, baseStyle.fontSize);
        expect(newStyle.color, baseStyle.color);
      });
    });

    group('italicStyle', () {
      test('applies italic font style and preserves other properties', () {
        final newStyle = DefaultStyles.italicStyle(baseStyle);
        expect(newStyle.fontStyle, FontStyle.italic);
        expect(newStyle.fontSize, baseStyle.fontSize);
        expect(newStyle.color, baseStyle.color);
      });
    });

    group('boldItalicStyle', () {
      test('applies both bold and italic and preserves other properties', () {
        final newStyle = DefaultStyles.boldItalicStyle(baseStyle);
        expect(newStyle.fontWeight, FontWeight.bold);
        expect(newStyle.fontStyle, FontStyle.italic);
        expect(newStyle.fontSize, baseStyle.fontSize);
        expect(newStyle.color, baseStyle.color);
      });
    });

    group('highlightStyle', () {
      test('uses the light-surface highlight background and keeps the text color', () {
        const darkText = TextStyle(color: Color(0xFF000000));
        final newStyle = DefaultStyles.highlightStyle(darkText, Brightness.light);
        expect(
          newStyle.backgroundColor,
          DefaultStyles.highlightBackgroundColor(Brightness.light),
        );
        expect(newStyle.color, darkText.color);
      });

      test('uses the dark-surface highlight background and keeps the text color', () {
        const lightText = TextStyle(color: Color(0xFFFFFFFF));
        final newStyle = DefaultStyles.highlightStyle(lightText, Brightness.dark);
        expect(
          newStyle.backgroundColor,
          DefaultStyles.highlightBackgroundColor(Brightness.dark),
        );
        expect(newStyle.color, lightText.color);
      });
    });

    group('strikethroughStyle', () {
      test('applies strikethrough to a style with no existing decoration', () {
        final newStyle = DefaultStyles.strikethroughStyle(baseStyle);
        expect(newStyle.decoration, TextDecoration.lineThrough);
        expect(newStyle.decorationThickness, DefaultStyles.defaultStrikethroughThickness);
      });

      test('combines strikethrough with an existing decoration', () {
        const styleWithUnderline = TextStyle(decoration: TextDecoration.underline);
        final newStyle = DefaultStyles.strikethroughStyle(styleWithUnderline);
        expect(
          newStyle.decoration,
          TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ]),
        );
      });

      test('does not re-combine if strikethrough already exists', () {
        const styleWithStrikethrough = TextStyle(decoration: TextDecoration.lineThrough);
        final newStyle = DefaultStyles.strikethroughStyle(styleWithStrikethrough);
        expect(newStyle.decoration, TextDecoration.lineThrough);
      });

      test('uses decorationColor from baseStyle if available', () {
        const styleWithDecoColor = TextStyle(decorationColor: Color(0xFFF44336));
        final newStyle = DefaultStyles.strikethroughStyle(styleWithDecoColor);
        expect(newStyle.decorationColor, const Color(0xFFF44336));
      });

      test('falls back to base color for decorationColor if decorationColor is null', () {
        const styleWithColor = TextStyle(color: Color(0xFF4CAF50));
        final newStyle = DefaultStyles.strikethroughStyle(styleWithColor);
        expect(newStyle.decorationColor, const Color(0xFF4CAF50));
      });

      test('applies specified thickness', () {
        final newStyle = DefaultStyles.strikethroughStyle(baseStyle, thickness: 3);
        expect(newStyle.decorationThickness, 3.0);
      });
    });

    group('underlineStyle', () {
      test('applies underline to a style with no existing decoration', () {
        final newStyle = DefaultStyles.underlineStyle(baseStyle);
        expect(newStyle.decoration, TextDecoration.underline);
      });

      test('combines underline with an existing decoration', () {
        const styleWithStrikethrough = TextStyle(decoration: TextDecoration.lineThrough);
        final newStyle = DefaultStyles.underlineStyle(styleWithStrikethrough);
        expect(
          newStyle.decoration,
          TextDecoration.combine([
            TextDecoration.lineThrough,
            TextDecoration.underline,
          ]),
        );
      });

      test('does not re-combine if underline already exists', () {
        const styleWithUnderline = TextStyle(decoration: TextDecoration.underline);
        final newStyle = DefaultStyles.underlineStyle(styleWithUnderline);
        expect(newStyle.decoration, TextDecoration.underline);
      });

      test('uses decorationColor from baseStyle if available', () {
        const styleWithDecoColor = TextStyle(decorationColor: Color(0xFFF44336));
        final newStyle = DefaultStyles.underlineStyle(styleWithDecoColor);
        expect(newStyle.decorationColor, const Color(0xFFF44336));
      });

      test('falls back to base color for decorationColor if decorationColor is null', () {
        const styleWithColor = TextStyle(color: Color(0xFF4CAF50));
        final newStyle = DefaultStyles.underlineStyle(styleWithColor);
        expect(newStyle.decorationColor, const Color(0xFF4CAF50));
      });

      test('uses decorationThickness from baseStyle if available', () {
        const styleWithDecoThickness = TextStyle(decorationThickness: 2.5);
        final newStyle = DefaultStyles.underlineStyle(styleWithDecoThickness);
        expect(newStyle.decorationThickness, 2.5);
      });
    });

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
