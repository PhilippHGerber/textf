// Tests for DefaultStyles fallback methods that aren't exercised when
// TextfOptions provides explicit styles.

// ignore_for_file: avoid-non-null-assertion, binary-expression-operand-order, no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/styling/textf_palette.dart';

void main() {
  group('DefaultStyles Fallback Methods', () {
    const baseStyle = TextStyle(fontSize: 16, color: Color(0xFF000000));

    group('superscriptStyle', () {
      test('applies reduced font size based on scriptFontSizeFactor', () {
        final result = DefaultStyles.superscriptStyle(baseStyle);

        expect(
          result.fontSize,
          baseStyle.fontSize! * DefaultStyles.scriptFontSizeFactor,
          reason: 'Superscript should scale font to 60% of base',
        );
      });

      test('uses defaultFontSize when baseStyle has no fontSize', () {
        const noSizeStyle = TextStyle(color: Color(0xFF2196F3));
        final result = DefaultStyles.superscriptStyle(noSizeStyle);

        expect(
          result.fontSize,
          DefaultStyles.defaultFontSize * DefaultStyles.scriptFontSizeFactor,
          reason: 'Should fallback to defaultFontSize when base has none',
        );
      });

      test('preserves other style properties', () {
        const styledBase = TextStyle(
          fontSize: 20,
          color: Color(0xFFF44336),
          fontWeight: FontWeight.bold,
        );
        final result = DefaultStyles.superscriptStyle(styledBase);

        expect(result.color, const Color(0xFFF44336));
        expect(result.fontWeight, FontWeight.bold);
        expect(result.fontSize, 20 * DefaultStyles.scriptFontSizeFactor);
      });
    });

    group('subscriptStyle', () {
      test('applies reduced font size based on scriptFontSizeFactor', () {
        final result = DefaultStyles.subscriptStyle(baseStyle);

        expect(
          result.fontSize,
          baseStyle.fontSize! * DefaultStyles.scriptFontSizeFactor,
          reason: 'Subscript should scale font to 60% of base',
        );
      });

      test('uses defaultFontSize when baseStyle has no fontSize', () {
        const noSizeStyle = TextStyle(color: Color(0xFF4CAF50));
        final result = DefaultStyles.subscriptStyle(noSizeStyle);

        expect(
          result.fontSize,
          DefaultStyles.defaultFontSize * DefaultStyles.scriptFontSizeFactor,
        );
      });
    });

    group('highlightStyle with the surface inferred by TextfPalette', () {
      TextStyle highlight(TextStyle style) =>
          DefaultStyles.highlightStyle(style, TextfPalette(style).surface);

      test('dark text implies a light surface → light tint at highlightAlphaLight', () {
        final result = highlight(const TextStyle(color: Color(0xFF000000)));

        expect(result.backgroundColor, const Color(0xFFFFEB3B).withValues(alpha: 0.5));
      });

      test('light text implies a dark surface → dark tint at highlightAlphaDark', () {
        final result = highlight(const TextStyle(color: Color(0xFFFFFFFF)));

        expect(result.backgroundColor, const Color(0xFFFBC02D).withValues(alpha: 0.4));
      });

      test('a color-less style is treated as dark text on a light surface', () {
        final result = highlight(const TextStyle(fontSize: 14));

        expect(result.backgroundColor, const Color(0xFFFFEB3B).withValues(alpha: 0.5));
        expect(result.color, isNull);
      });
    });
  });
}
