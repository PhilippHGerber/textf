// ignore_for_file: avoid-non-null-assertion

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

void main() {
  group('TextfStyleResolver Without TextfOptions', () {
    const Color black = Color(0xFF000000);
    const baseStyle = TextStyle(fontSize: 16, color: black);
    final palette = TextfPalette(baseStyle);

    // No options and no BuildContext: the resolver is context-free.
    final resolver = TextfStyleResolver.withState(options: null);

    test('resolves bold using DefaultStyles fallback', () {
      final result = resolver.resolveStyle(FormatMarkerType.bold, baseStyle, palette);

      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontSize, baseStyle.fontSize);
    });

    test('resolves italic using DefaultStyles fallback', () {
      final result = resolver.resolveStyle(FormatMarkerType.italic, baseStyle, palette);

      expect(result.fontStyle, FontStyle.italic);
    });

    test('resolves boldItalic using DefaultStyles fallback', () {
      final result = resolver.resolveStyle(FormatMarkerType.boldItalic, baseStyle, palette);

      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontStyle, FontStyle.italic);
    });

    test('resolves strikethrough with default thickness', () {
      final result = resolver.resolveStyle(FormatMarkerType.strikethrough, baseStyle, palette);

      expect(result.decoration, TextDecoration.lineThrough);
      expect(result.decorationThickness, DefaultStyles.defaultStrikethroughThickness);
    });

    test('resolves code with the neutral palette-derived styling', () {
      final result = resolver.resolveStyle(FormatMarkerType.code, baseStyle, palette);

      expect(result.fontFamily, 'monospace');
      expect(result.fontFamilyFallback, DefaultStyles.defaultCodeFontFamilyFallback);
      expect(result.color, black, reason: 'code text keeps the segment color');
      expect(result.backgroundColor, black.withValues(alpha: 0.05));
    });

    test('code background derives from the palette, not the segment color', () {
      final darkSurface = TextfPalette(const TextStyle(color: Color(0xFFFFFFFF)));

      final result = resolver.resolveStyle(FormatMarkerType.code, baseStyle, darkSurface);

      expect(result.backgroundColor, const Color(0xFFFFFFFF).withValues(alpha: 0.15));
      expect(result.color, black);
    });

    test('resolves underline using DefaultStyles fallback', () {
      final result = resolver.resolveStyle(FormatMarkerType.underline, baseStyle, palette);

      expect(result.decoration, TextDecoration.underline);
    });

    test('resolves highlight with the neutral light-surface tint', () {
      final result = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle, palette);

      expect(result.backgroundColor, const Color(0xFFFFEB3B).withValues(alpha: 0.5));
      expect(result.color, black);
    });

    test('highlight on a dark surface uses the dark tint and white fallback text', () {
      final darkSurface = TextfPalette(const TextStyle(color: Color(0xFFFFFFFF)));

      final result = resolver.resolveStyle(
        FormatMarkerType.highlight,
        const TextStyle(fontSize: 16),
        darkSurface,
      );

      expect(result.backgroundColor, const Color(0xFFFBC02D).withValues(alpha: 0.4));
      expect(result.color, const Color(0xFFFFFFFF));
    });

    test('resolves superscript with scaled font size', () {
      final result = resolver.resolveStyle(FormatMarkerType.superscript, baseStyle, palette);

      expect(result.fontSize, baseStyle.fontSize! * DefaultStyles.scriptFontSizeFactor);
    });

    test('resolves subscript with scaled font size', () {
      final result = resolver.resolveStyle(FormatMarkerType.subscript, baseStyle, palette);

      expect(result.fontSize, baseStyle.fontSize! * DefaultStyles.scriptFontSizeFactor);
    });

    test('resolves link configuration using neutral defaults and DefaultStyles fallback', () {
      final config = resolver.resolveLinkConfiguration(baseStyle);

      expect(config.style.color, const Color(0xFF1A73E8));
      expect(config.style.decoration, TextDecoration.underline);
      expect(config.style.decorationColor, const Color(0xFF1A73E8));
      expect(config.hoverStyle, config.style);
      expect(config.cursor, DefaultStyles.linkMouseCursor);
      expect(config.onTap, isNull);
      expect(config.onHover, isNull);
      expect(config.alignment, PlaceholderAlignment.baseline);
    });
  });
}
