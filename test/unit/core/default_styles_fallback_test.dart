// Tests for DefaultStyles fallback methods that aren't exercised when
// TextfOptions provides explicit styles.

// ignore_for_file: avoid-non-null-assertion, binary-expression-operand-order, no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';

void main() {
  group('DefaultStyles Fallback Methods', () {
    const baseStyle = TextStyle(fontSize: 16, color: Colors.black);

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
        const noSizeStyle = TextStyle(color: Colors.blue);
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
          color: Colors.red,
          fontWeight: FontWeight.bold,
        );
        final result = DefaultStyles.superscriptStyle(styledBase);

        expect(result.color, Colors.red);
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
        const noSizeStyle = TextStyle(color: Colors.green);
        final result = DefaultStyles.subscriptStyle(noSizeStyle);

        expect(
          result.fontSize,
          DefaultStyles.defaultFontSize * DefaultStyles.scriptFontSizeFactor,
        );
      });
    });

    group('highlightStyle', () {
      test('applies dark alpha when text color is dark', () {
        // Dark text (black) triggers isDark=true → highlightAlphaDark
        const darkTextStyle = TextStyle(color: Colors.black);
        final result = DefaultStyles.highlightStyle(darkTextStyle);

        expect(result.backgroundColor, isNotNull);
        expect(
          result.backgroundColor!.a,
          closeTo(DefaultStyles.highlightAlphaDark, 0.01),
        );
      });

      test('applies light alpha when text color is light', () {
        // Light text (white) triggers isDark=false → highlightAlphaLight
        const lightTextStyle = TextStyle(color: Colors.white);
        final result = DefaultStyles.highlightStyle(lightTextStyle);

        expect(result.backgroundColor, isNotNull);
        expect(
          result.backgroundColor!.a,
          closeTo(DefaultStyles.highlightAlphaLight, 0.01),
        );
      });

      test('handles null color gracefully', () {
        const noColorStyle = TextStyle(fontSize: 14);
        // Null color → isDark=false → uses highlightAlphaLight
        final result = DefaultStyles.highlightStyle(noColorStyle);

        expect(result.backgroundColor, isNotNull);
        expect(
          result.backgroundColor!.a,
          closeTo(DefaultStyles.highlightAlphaLight, 0.01),
        );
      });
    });
  });
}
