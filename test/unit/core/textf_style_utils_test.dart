import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/textf_style_utils.dart';

const _baseFontSize = 14.0;
const _optionsFontSize = 18.0;
const _spanThickness = 1.0;
const _linkThickness = 3.0;

void main() {
  group('mergeTextStyles', () {
    test('applies options decoration when base has none', () {
      const base = TextStyle();
      const options = TextStyle(decoration: TextDecoration.underline);

      final result = mergeTextStyles(base, options);

      expect(result.decoration, TextDecoration.underline);
    });

    test('preserves base decoration when options decoration is null', () {
      const base = TextStyle(decoration: TextDecoration.underline);
      const options = TextStyle(color: Color(0xFFFF0000));

      final result = mergeTextStyles(base, options);

      expect(result.decoration, TextDecoration.underline);
      expect(result.color, const Color(0xFFFF0000));
    });

    test('removes all decorations when options sets TextDecoration.none', () {
      const base = TextStyle(decoration: TextDecoration.underline);
      const options = TextStyle(decoration: TextDecoration.none);

      final result = mergeTextStyles(base, options);

      expect(result.decoration, TextDecoration.none);
    });

    test('combines distinct decorations from base and options', () {
      const base = TextStyle(decoration: TextDecoration.underline);
      const options = TextStyle(decoration: TextDecoration.lineThrough);

      final result = mergeTextStyles(base, options);

      final combined = TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
      expect(result.decoration, combined);
    });

    test('preserves base when options adds a duplicate decoration', () {
      final base = TextStyle(
        decoration: TextDecoration.combine([
          TextDecoration.underline,
          TextDecoration.lineThrough,
        ]),
      );
      const options = TextStyle(decoration: TextDecoration.underline);

      final result = mergeTextStyles(base, options);

      // Should keep the full base decoration, not downgrade to just underline
      expect(result.decoration, base.decoration);
    });

    test('merges non-decoration properties normally', () {
      const base = TextStyle(fontSize: _baseFontSize, color: Color(0xFF000000));
      const options = TextStyle(fontSize: _optionsFontSize, fontWeight: FontWeight.bold);

      final result = mergeTextStyles(base, options);

      expect(result.fontSize, _optionsFontSize);
      expect(result.fontWeight, FontWeight.bold);
      expect(result.color, const Color(0xFF000000));
    });
  });

  group('applyLinkStyleToSpan', () {
    test('applies link underline to span with no decoration', () {
      const span = TextStyle(color: Color(0xFF000000));
      const link = TextStyle(decoration: TextDecoration.underline);

      final result = applyLinkStyleToSpan(span, link);

      expect(result.decoration, TextDecoration.underline);
    });

    test('combines link underline with span strikethrough', () {
      const span = TextStyle(decoration: TextDecoration.lineThrough);
      const link = TextStyle(decoration: TextDecoration.underline);

      final result = applyLinkStyleToSpan(span, link);

      final combined = TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
      expect(result.decoration, combined);
    });

    test('does not duplicate decoration when span already has it', () {
      const span = TextStyle(decoration: TextDecoration.underline);
      const link = TextStyle(decoration: TextDecoration.underline);

      final result = applyLinkStyleToSpan(span, link);

      expect(result.decoration, TextDecoration.underline);
    });

    test('applies link color over span color', () {
      const span = TextStyle(color: Color(0xFF000000));
      const link = TextStyle(color: Color(0xFF0000FF));

      final result = applyLinkStyleToSpan(span, link);

      expect(result.color, const Color(0xFF0000FF));
    });

    test('preserves span color when link has no color', () {
      const span = TextStyle(color: Color(0xFF000000));
      const link = TextStyle(decoration: TextDecoration.underline);

      final result = applyLinkStyleToSpan(span, link);

      expect(result.color, const Color(0xFF000000));
    });

    test('uses link decorationColor over span decorationColor', () {
      const span = TextStyle(decorationColor: Color(0xFFFF0000));
      const link = TextStyle(decorationColor: Color(0xFF00FF00));

      final result = applyLinkStyleToSpan(span, link);

      expect(result.decorationColor, const Color(0xFF00FF00));
    });

    test('falls back to span decorationColor when link has none', () {
      const span = TextStyle(decorationColor: Color(0xFFFF0000));
      const link = TextStyle();

      final result = applyLinkStyleToSpan(span, link);

      expect(result.decorationColor, const Color(0xFFFF0000));
    });

    test('uses link decorationThickness over span decorationThickness', () {
      const span = TextStyle(decorationThickness: _spanThickness);
      const link = TextStyle(decorationThickness: _linkThickness);

      final result = applyLinkStyleToSpan(span, link);

      expect(result.decorationThickness, _linkThickness);
    });

    test('preserves span decoration when link has no decoration', () {
      const span = TextStyle(decoration: TextDecoration.lineThrough);
      const link = TextStyle(color: Color(0xFF0000FF));

      final result = applyLinkStyleToSpan(span, link);

      expect(result.decoration, TextDecoration.lineThrough);
      expect(result.color, const Color(0xFF0000FF));
    });
  });
}
