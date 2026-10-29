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
    final resolver = TextfStyleResolver(options: null);

    test('resolves bold with the relative default', () {
      final result = resolver.resolveStyle(FormatMarkerType.bold, baseStyle, palette);

      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontSize, baseStyle.fontSize);
      expect(result.color, baseStyle.color);
    });

    test('resolves italic with the relative default', () {
      final result = resolver.resolveStyle(FormatMarkerType.italic, baseStyle, palette);

      expect(result.fontStyle, FontStyle.italic);
      expect(result.fontSize, baseStyle.fontSize);
      expect(result.color, baseStyle.color);
    });

    test('resolves boldItalic with the relative default', () {
      final result = resolver.resolveStyle(FormatMarkerType.boldItalic, baseStyle, palette);

      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontStyle, FontStyle.italic);
      expect(result.fontSize, baseStyle.fontSize);
      expect(result.color, baseStyle.color);
    });

    test('resolves strikethrough with the relative default and default thickness', () {
      final result = resolver.resolveStyle(FormatMarkerType.strikethrough, baseStyle, palette);

      expect(result.decoration, TextDecoration.lineThrough);
      expect(result.decorationThickness, DefaultStyles.defaultStrikethroughThickness);
      expect(result.decorationColor, baseStyle.color);
      expect(result.fontSize, baseStyle.fontSize);
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

    test('resolves underline with the relative default', () {
      final result = resolver.resolveStyle(FormatMarkerType.underline, baseStyle, palette);

      expect(result.decoration, TextDecoration.underline);
      expect(result.decorationColor, baseStyle.color);
      expect(result.fontSize, baseStyle.fontSize);
    });

    test('resolves highlight with the neutral light-surface tint', () {
      final result = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle, palette);

      expect(result.backgroundColor, const Color(0xFFFFEB3B).withValues(alpha: 0.5));
      expect(result.color, black);
    });

    test('highlight on a dark surface uses the dark tint and the palette text color', () {
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

    test('resolves link configuration using the neutral defaults', () {
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

    // Decoration edge cases of the strikethrough and underline relative
    // defaults.
    group('relative decoration defaults', () {
      TextStyle resolve(FormatMarkerType type, TextStyle base) =>
          resolver.resolveStyle(type, base, palette);

      group('strikethrough', () {
        test('adds lineThrough to a base style with a null decoration', () {
          final resolved = resolve(FormatMarkerType.strikethrough, const TextStyle());
          expect(resolved.decoration, TextDecoration.lineThrough);
        });

        test('adds lineThrough to a base style with TextDecoration.none', () {
          final resolved = resolve(
            FormatMarkerType.strikethrough,
            const TextStyle(decoration: TextDecoration.none),
          );
          expect(resolved.decoration, TextDecoration.lineThrough);
        });

        test('combines lineThrough with an existing different decoration', () {
          final resolved = resolve(
            FormatMarkerType.strikethrough,
            const TextStyle(decoration: TextDecoration.underline),
          );
          expect(
            resolved.decoration,
            TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]),
          );
        });

        test('does not re-add lineThrough when the base already has it', () {
          final resolved = resolve(
            FormatMarkerType.strikethrough,
            TextStyle(
              decoration: TextDecoration.combine([
                TextDecoration.lineThrough,
                TextDecoration.overline,
              ]),
            ),
          );
          expect(
            resolved.decoration,
            TextDecoration.combine([TextDecoration.lineThrough, TextDecoration.overline]),
          );
        });

        test('takes the decoration color from the base decoration color', () {
          final resolved = resolve(
            FormatMarkerType.strikethrough,
            const TextStyle(color: Color(0xFF4CAF50), decorationColor: Color(0xFFF44336)),
          );
          expect(resolved.decorationColor, const Color(0xFFF44336));
        });

        test('falls back to the base color for the decoration color', () {
          final resolved = resolve(
            FormatMarkerType.strikethrough,
            const TextStyle(color: Color(0xFF4CAF50)),
          );
          expect(resolved.decorationColor, const Color(0xFF4CAF50));
        });

        test('uses thickness 1.5 even when the base sets its own thickness', () {
          final resolved = resolve(
            FormatMarkerType.strikethrough,
            const TextStyle(decorationThickness: 2.5),
          );
          expect(resolved.decorationThickness, 1.5);
        });
      });

      group('underline', () {
        test('adds underline to a base style with a null decoration', () {
          final resolved = resolve(FormatMarkerType.underline, const TextStyle());
          expect(resolved.decoration, TextDecoration.underline);
        });

        test('adds underline to a base style with TextDecoration.none', () {
          final resolved = resolve(
            FormatMarkerType.underline,
            const TextStyle(decoration: TextDecoration.none),
          );
          expect(resolved.decoration, TextDecoration.underline);
        });

        test('combines underline with an existing different decoration', () {
          final resolved = resolve(
            FormatMarkerType.underline,
            const TextStyle(decoration: TextDecoration.lineThrough),
          );
          expect(
            resolved.decoration,
            TextDecoration.combine([TextDecoration.lineThrough, TextDecoration.underline]),
          );
        });

        test('does not re-add underline when the base already has it', () {
          final resolved = resolve(
            FormatMarkerType.underline,
            TextStyle(
              decoration: TextDecoration.combine([
                TextDecoration.underline,
                TextDecoration.overline,
              ]),
            ),
          );
          expect(
            resolved.decoration,
            TextDecoration.combine([TextDecoration.underline, TextDecoration.overline]),
          );
        });

        test('takes the decoration color from the base decoration color', () {
          final resolved = resolve(
            FormatMarkerType.underline,
            const TextStyle(color: Color(0xFF4CAF50), decorationColor: Color(0xFFF44336)),
          );
          expect(resolved.decorationColor, const Color(0xFFF44336));
        });

        test('falls back to the base color for the decoration color', () {
          final resolved = resolve(
            FormatMarkerType.underline,
            const TextStyle(color: Color(0xFF4CAF50)),
          );
          expect(resolved.decorationColor, const Color(0xFF4CAF50));
        });

        test('keeps the base decoration thickness', () {
          final resolved = resolve(
            FormatMarkerType.underline,
            const TextStyle(decorationThickness: 2.5),
          );
          expect(resolved.decorationThickness, 2.5);
        });

        test('uses thickness 1.0 when the base sets none', () {
          final resolved = resolve(FormatMarkerType.underline, const TextStyle());
          expect(resolved.decorationThickness, 1.0);
        });
      });
    });
  });
}
