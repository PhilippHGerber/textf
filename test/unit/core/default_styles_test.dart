import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';

void main() {
  group('DefaultStyles Tests', () {
    const baseStyle = TextStyle(fontSize: 16, color: Colors.blue, fontFamily: 'Roboto');

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
      test('applies highlight for a light theme color', () {
        const lightBaseStyle = TextStyle(color: Colors.black);
        final newStyle = DefaultStyles.highlightStyle(lightBaseStyle);
        expect(newStyle.backgroundColor, isNotNull);
        expect(newStyle.color, lightBaseStyle.color); // Should preserve text color
      });

      test('applies highlight for a dark theme color', () {
        const darkBaseStyle = TextStyle(color: Colors.white);
        final newStyle = DefaultStyles.highlightStyle(darkBaseStyle);
        expect(newStyle.backgroundColor, isNotNull);
        expect(newStyle.color, darkBaseStyle.color); // Should preserve text color
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
        const styleWithDecoColor = TextStyle(decorationColor: Colors.red);
        final newStyle = DefaultStyles.strikethroughStyle(styleWithDecoColor);
        expect(newStyle.decorationColor, Colors.red);
      });

      test('falls back to base color for decorationColor if decorationColor is null', () {
        const styleWithColor = TextStyle(color: Colors.green);
        final newStyle = DefaultStyles.strikethroughStyle(styleWithColor);
        expect(newStyle.decorationColor, Colors.green);
      });

      test('applies specified thickness', () {
        final newStyle = DefaultStyles.strikethroughStyle(baseStyle, thickness: 3.0);
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
        const styleWithDecoColor = TextStyle(decorationColor: Colors.red);
        final newStyle = DefaultStyles.underlineStyle(styleWithDecoColor);
        expect(newStyle.decorationColor, Colors.red);
      });

      test('falls back to base color for decorationColor if decorationColor is null', () {
        const styleWithColor = TextStyle(color: Colors.green);
        final newStyle = DefaultStyles.underlineStyle(styleWithColor);
        expect(newStyle.decorationColor, Colors.green);
      });

      test('uses decorationThickness from baseStyle if available', () {
        const styleWithDecoThickness = TextStyle(decorationThickness: 2.5);
        final newStyle = DefaultStyles.underlineStyle(styleWithDecoThickness);
        expect(newStyle.decorationThickness, 2.5);
      });
    });
  });
}
