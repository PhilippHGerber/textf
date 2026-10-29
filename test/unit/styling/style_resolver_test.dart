import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

void main() {
  group('TextfStyleResolver Tests', () {
    // A base style to be used in tests.
    const TextStyle baseStyle = TextStyle(
      fontSize: 16,
      color: Color(0xFF000000),
      fontFamily: 'Roboto',
      decoration: TextDecoration.none, // Explicitly none for easier testing
    );

    // The render pass's palette: dark text, so a light surface is implied.
    final palette = TextfPalette(baseStyle);

    // Neutral defaults (no design-system theme is consulted).
    const Color defaultLinkColor = Color(0xFF1A73E8);
    final Color defaultCodeBackground = const Color(0xFF000000).withValues(alpha: 0.05);

    group('No TextfOptions (Fallback to Defaults)', () {
      final resolver = TextfStyleResolver(options: null);

      test('resolveStyle for bold applies the relative default', () {
        final resolved = resolver.resolveStyle(FormatMarkerType.bold, baseStyle, palette);
        expect(resolved.fontWeight, FontWeight.bold);
        expect(resolved.fontSize, baseStyle.fontSize);
        expect(resolved.color, baseStyle.color);
      });

      test('resolveStyle for italic applies the relative default', () {
        final resolved = resolver.resolveStyle(FormatMarkerType.italic, baseStyle, palette);
        expect(resolved.fontStyle, FontStyle.italic);
        expect(resolved.fontSize, baseStyle.fontSize);
        expect(resolved.color, baseStyle.color);
      });

      test('resolveStyle for boldItalic applies the relative default', () {
        final resolved = resolver.resolveStyle(FormatMarkerType.boldItalic, baseStyle, palette);
        expect(resolved.fontWeight, FontWeight.bold);
        expect(resolved.fontStyle, FontStyle.italic);
        expect(resolved.fontSize, baseStyle.fontSize);
        expect(resolved.color, baseStyle.color);
      });

      test(
        'resolveStyle for strikethrough applies the relative default with default thickness',
        () {
          final resolved = resolver.resolveStyle(
            FormatMarkerType.strikethrough,
            baseStyle,
            palette,
          );
          expect(resolved.decoration, TextDecoration.lineThrough);
          expect(resolved.decorationThickness, DefaultStyles.defaultStrikethroughThickness);
          expect(resolved.decorationColor, baseStyle.color); // Inherits base color for decoration
          expect(resolved.fontSize, baseStyle.fontSize);
        },
      );

      test('resolveStyle for code uses the neutral default', () {
        final resolved = resolver.resolveStyle(FormatMarkerType.code, baseStyle, palette);
        expect(resolved.fontFamily, 'monospace');
        expect(resolved.fontFamilyFallback, DefaultStyles.defaultCodeFontFamilyFallback);
        expect(resolved.backgroundColor, defaultCodeBackground);
        expect(resolved.color, baseStyle.color); // Code text keeps the segment color
        expect(resolved.fontSize, baseStyle.fontSize); // Base font size
      });

      test('resolveStyle for underline applies the relative default', () {
        final resolved = resolver.resolveStyle(FormatMarkerType.underline, baseStyle, palette);
        expect(resolved.decoration, TextDecoration.underline);
        expect(resolved.decorationColor, baseStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      // Decoration edge cases of the strikethrough and underline relative
      // defaults. The base style above already covers `TextDecoration.none`.
      group('relative decoration defaults', () {
        final resolver = TextfStyleResolver(options: null);

        TextStyle resolve(FormatMarkerType type, TextStyle base) =>
            resolver.resolveStyle(type, base, palette);

        group('strikethrough', () {
          test('adds lineThrough to a base style with a null decoration', () {
            final resolved = resolve(FormatMarkerType.strikethrough, const TextStyle());
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

      test('resolveStyle for highlight uses the neutral default', () {
        final resolved = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle, palette);
        expect(resolved.backgroundColor, const Color(0xFFFFEB3B).withValues(alpha: 0.5));
        expect(resolved.color, baseStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      test('resolveLinkConfiguration uses neutral defaults', () {
        final config = resolver.resolveLinkConfiguration(baseStyle);
        expect(config.style.color, defaultLinkColor);
        expect(config.style.decoration, TextDecoration.underline);
        expect(config.style.decorationColor, defaultLinkColor);
        expect(config.style.fontSize, baseStyle.fontSize);
        expect(config.hoverStyle, config.style);
        expect(config.cursor, DefaultStyles.linkMouseCursor);
        expect(config.onTap, isNull);
        expect(config.onHover, isNull);
        expect(config.alignment, PlaceholderAlignment.baseline);
      });
    });

    group('With TextfOptions (Single Level)', () {
      const optionBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF44336));
      const optionItalicStyle = TextStyle(fontStyle: FontStyle.normal, color: Color(0xFF4CAF50));
      // CORRECTED: optionStrikeStyle now includes the decoration itself
      const optionStrikeStyle = TextStyle(
        decoration: TextDecoration.lineThrough, // Added this
        decorationColor: Color(0xFF9C27B0),
        decorationThickness: 3,
      );
      const optionStrikeThickness = 2.5;
      const optionCodeStyle = TextStyle(backgroundColor: Color(0xFF9E9E9E), fontFamily: 'Courier');
      const optionLinkStyle = TextStyle(
        color: Color(0xFFFF9800),
        decoration: TextDecoration.overline,
      );
      const optionLinkHoverStyle = TextStyle(color: Color(0xFFE91E63), letterSpacing: 2);
      const optionCursor = SystemMouseCursors.help;

      void testOnTap(String u, String d) {
        debugPrint('Tapped URL: $u with display text: $d');
      }

      void testOnHover(String u, String d, {required bool isHovering}) {
        debugPrint('Hovered URL: $u with display text: $d, isHovering: $isHovering');
      }

      final options = TextfOptionsData(
        boldStyle: optionBoldStyle,
        italicStyle: optionItalicStyle,
        strikethroughStyle: optionStrikeStyle,
        codeStyle: optionCodeStyle,
        linkStyle: optionLinkStyle,
        linkHoverStyle: optionLinkHoverStyle,
        linkMouseCursor: optionCursor,
        linkAlignment: PlaceholderAlignment.middle,
        onLinkTap: testOnTap,
        onLinkHover: testOnHover,
      );
      final resolverWithOptions = TextfStyleResolver(options: options);

      test('resolveStyle for bold uses TextfOptions', () {
        final resolved = resolverWithOptions.resolveStyle(
          FormatMarkerType.bold,
          baseStyle,
          palette,
        );
        expect(resolved.fontWeight, optionBoldStyle.fontWeight);
        expect(resolved.color, optionBoldStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      test('resolveStyle for italic uses TextfOptions', () {
        final resolved = resolverWithOptions.resolveStyle(
          FormatMarkerType.italic,
          baseStyle,
          palette,
        );
        expect(resolved.fontStyle, optionItalicStyle.fontStyle);
        expect(resolved.color, optionItalicStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      test('resolveStyle for strikethrough uses TextfOptions.strikethroughStyle', () {
        final resolved = resolverWithOptions.resolveStyle(
          FormatMarkerType.strikethrough,
          baseStyle,
          palette,
        );
        // Now it should have the decoration from optionStrikeStyle
        expect(resolved.decoration, optionStrikeStyle.decoration); // CORRECTED EXPECTATION
        expect(resolved.decorationColor, optionStrikeStyle.decorationColor);
        expect(resolved.decorationThickness, optionStrikeStyle.decorationThickness);
      });

      test(
        'resolveStyle for strikethrough uses TextfOptions.strikethroughThickness if style is null',
        () {
          final resolver = TextfStyleResolver(
            options: const TextfOptionsData(strikethroughThickness: optionStrikeThickness),
          );

          final resolved = resolver.resolveStyle(
            FormatMarkerType.strikethrough,
            baseStyle,
            palette,
          );
          expect(resolved.decoration, TextDecoration.lineThrough);
          expect(resolved.decorationThickness, optionStrikeThickness);
          expect(resolved.decorationColor, baseStyle.color);
        },
      );

      test('resolveStyle for code uses TextfOptions', () {
        final resolved = resolverWithOptions.resolveStyle(
          FormatMarkerType.code,
          baseStyle,
          palette,
        );
        expect(resolved.backgroundColor, optionCodeStyle.backgroundColor);
        expect(resolved.fontFamily, optionCodeStyle.fontFamily);
        expect(resolved.color, baseStyle.color);
      });

      test('resolveLinkConfiguration uses TextfOptions overrides for all fields', () {
        final normalLinkStyleWithOptions = baseStyle.merge(optionLinkStyle);
        final config = resolverWithOptions.resolveLinkConfiguration(baseStyle);

        // Style (Precedence 1: optionLinkStyle overrides built-in default)
        expect(config.style.color, optionLinkStyle.color);
        expect(config.style.decoration, optionLinkStyle.decoration);
        expect(config.style.fontSize, baseStyle.fontSize);

        // Hover style (merges optionLinkHoverStyle onto normal link style)
        expect(config.hoverStyle.color, optionLinkHoverStyle.color);
        expect(config.hoverStyle.letterSpacing, optionLinkHoverStyle.letterSpacing);
        expect(config.hoverStyle.decoration, normalLinkStyleWithOptions.decoration);
        expect(config.hoverStyle.fontSize, baseStyle.fontSize);

        // Cursor & callbacks & alignment
        expect(config.cursor, optionCursor);
        expect(config.onTap, testOnTap);
        expect(config.onHover, testOnHover);
        expect(config.alignment, PlaceholderAlignment.middle);
      });

      test('resolveLinkConfiguration respects linkColor option when no linkStyle is set', () {
        const customLinkColor = Color(0xFF009688);
        final resolver = TextfStyleResolver(
          options: const TextfOptionsData(linkColor: customLinkColor),
        );
        final config = resolver.resolveLinkConfiguration(baseStyle);

        expect(config.style.color, customLinkColor);
        expect(config.style.decoration, TextDecoration.underline);
        expect(config.style.decorationColor, customLinkColor);
      });

      test('explicit linkStyle takes precedence over linkColor option', () {
        const customLinkColor = Color(0xFF009688);
        const explicitLinkStyle = TextStyle(color: Color(0xFFFF5722));
        final resolver = TextfStyleResolver(
          options: const TextfOptionsData(
            linkColor: customLinkColor,
            linkStyle: explicitLinkStyle,
          ),
        );
        final config = resolver.resolveLinkConfiguration(baseStyle);

        expect(config.style.color, explicitLinkStyle.color);
      });
    });

    group('With Nested TextfOptions', () {
      // Pumps [options] nested inside [parentOptions] and returns the
      // TextfOptionsData the inner TextfOptions provides, so these tests cover
      // the real inheritance lookup through the widget tree.
      Future<TextfOptionsData?> pumpNestedOptions(
        WidgetTester tester, {
        required TextfOptions parentOptions,
        required TextfOptions options,
      }) async {
        TextfOptionsData? captured;
        final Widget child = TextfOptions(
          boldStyle: options.boldStyle,
          italicStyle: options.italicStyle,
          linkStyle: options.linkStyle,
          onLinkTap: options.onLinkTap,
          onLinkHover: options.onLinkHover,
          child: Builder(
            builder: (context) {
              captured = TextfOptions.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        );

        // No design-system app: only TextfOptions is looked up from the context.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextfOptions(
              boldStyle: parentOptions.boldStyle,
              italicStyle: parentOptions.italicStyle,
              linkStyle: parentOptions.linkStyle,
              onLinkTap: parentOptions.onLinkTap,
              onLinkHover: parentOptions.onLinkHover,
              child: child,
            ),
          ),
        );
        return captured;
      }

      const parentBoldStyle = TextStyle(color: Color(0xFFFFC107));
      // parentLinkStyle defines no color, so baseStyle provides it
      const parentLinkStyle = TextStyle(decoration: TextDecoration.none /* no color here */);
      void parentTap(String u, String d) {
        debugPrint('Parent tapped URL: $u with display text: $d');
      }

      final parentOpts = TextfOptions(
        boldStyle: parentBoldStyle,
        linkStyle: parentLinkStyle,
        onLinkTap: parentTap,
        italicStyle: const TextStyle(color: Color(0xFF00BCD4)),
        child: const SizedBox.shrink(),
      );

      testWidgets('Nested options correctly merge with and override ancestor values', (
        tester,
      ) async {
        // SETUP:
        // parentOpts provides a red color for bold text.
        // childOptsWithOverride provides a light font weight for bold text.
        // The expected result is a MERGE of both.

        const parentBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF44336));
        const parentItalicStyle = TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF9C27B0));
        void parentTap(String u, String d) {
          return;
        }

        void parentHover(String u, String d, {required bool isHovering}) {
          return;
        }

        const childBoldStyle = TextStyle(fontWeight: FontWeight.w300); // No color specified.
        const childItalicStyle = TextStyle(
          fontStyle: FontStyle.normal,
          backgroundColor: Color(0xFFFFEB3B),
        );
        void childTap(String u, String d) {
          return;
        }

        void childHover(String u, String d, {required bool isHovering}) {
          return;
        }

        final parentOpts = TextfOptions(
          boldStyle: parentBoldStyle,
          italicStyle: parentItalicStyle,
          onLinkTap: parentTap,
          onLinkHover: parentHover,
          child: const SizedBox.shrink(),
        );

        final childOptsWithOverride = TextfOptions(
          boldStyle: childBoldStyle,
          italicStyle: childItalicStyle,
          onLinkTap: childTap,
          onLinkHover: childHover,
          child: const SizedBox.shrink(),
        );

        // ARRANGE: Pump the widget tree.
        final options = await pumpNestedOptions(
          tester,
          parentOptions: parentOpts,
          options: childOptsWithOverride,
        );
        final resolver = TextfStyleResolver(options: options);

        // --- ASSERT BOLD STYLE (MERGED) ---
        final resolvedBold = resolver.resolveStyle(FormatMarkerType.bold, baseStyle, palette);
        // The fontWeight should come from the child (it overrides the parent).
        expect(resolvedBold.fontWeight, childBoldStyle.fontWeight);
        // The color should be inherited from the parent (since the child didn't specify one).
        expect(
          resolvedBold.color,
          parentBoldStyle.color, // This is the key change in the test's expectation.
          reason: 'Color should be inherited from the parent TextfOptions.',
        );
        expect(resolvedBold.fontSize, baseStyle.fontSize); // Inherited from baseStyle.

        // --- ASSERT ITALIC STYLE (MERGED) ---
        final resolvedItalic = resolver.resolveStyle(FormatMarkerType.italic, baseStyle, palette);
        // It should have properties from both parent and child.
        expect(
          resolvedItalic.color,
          parentItalicStyle.color, // From parent.
          reason: 'Italic color should be inherited from parent.',
        );
        expect(
          resolvedItalic.backgroundColor,
          childItalicStyle.backgroundColor, // From child.
          reason: 'Italic background color should come from child.',
        );
        expect(
          resolvedItalic.fontStyle,
          childItalicStyle.fontStyle, // From child (overriding parent).
          reason: 'Italic fontStyle should be overridden by child.',
        );

        // --- ASSERT CALLBACK (NEAREST WINS) ---
        // Callbacks do not merge, so "nearest wins" logic is still correct here.
        final linkConfig = resolver.resolveLinkConfiguration(baseStyle);
        expect(
          linkConfig.onTap,
          childTap,
          reason: 'Callback should be taken from the nearest (child) TextfOptions.',
        );
        expect(
          linkConfig.onHover,
          childHover,
          reason: 'Hover callback should be taken from the nearest (child) TextfOptions.',
        );
      });

      testWidgets('Falls back to ancestor if nearest option is null for a property', (
        tester,
      ) async {
        final options = await pumpNestedOptions(
          tester,
          parentOptions: parentOpts, // Outer (provides linkStyle, italicStyle from parentOpts)
          options: const TextfOptions(
            child: SizedBox.shrink(),
          ), // Inner (linkStyle is implicitly null)
        );
        final resolver = TextfStyleResolver(options: options);

        final resolvedLink = resolver.resolveLinkConfiguration(baseStyle).style;
        expect(resolvedLink.decoration, parentLinkStyle.decoration); // From parent
        // An explicit linkStyle (even one without a color) replaces the default link style,
        // so the color comes from merging baseStyle with the option style.
        expect(
          resolvedLink.color,
          baseStyle.color,
          reason: "Color should be from baseStyle as parentLinkStyle didn't set it.",
        );

        final resolvedItalic = resolver.resolveStyle(FormatMarkerType.italic, baseStyle, palette);
        expect(resolvedItalic.color, const Color(0xFF00BCD4));
      });

      testWidgets('Falls back to neutral/DefaultStyles if all ancestors have null', (tester) async {
        const specificOptionItalicStyle = TextStyle(
          fontStyle: FontStyle.italic,
          color: Color(0xFF607D8B),
        );
        const parent = TextfOptions(boldStyle: parentBoldStyle, child: SizedBox.shrink());
        const child = TextfOptions(
          italicStyle: specificOptionItalicStyle,
          child: SizedBox.shrink(),
        );

        final options = await pumpNestedOptions(tester, parentOptions: parent, options: child);
        final resolver = TextfStyleResolver(options: options);

        final resolvedCode = resolver.resolveStyle(FormatMarkerType.code, baseStyle, palette);
        expect(resolvedCode.fontFamily, 'monospace');
        expect(resolvedCode.backgroundColor, defaultCodeBackground);
        expect(resolvedCode.color, baseStyle.color);

        final resolvedHighlight = resolver.resolveStyle(
          FormatMarkerType.highlight,
          baseStyle,
          palette,
        );
        expect(resolvedHighlight.backgroundColor, isNotNull);
      });
    });

    group('Style Merging Details', () {
      test('baseStyle properties are preserved if not overridden', () {
        const specificBaseStyle = TextStyle(
          fontSize: 20,
          fontFamily: 'Arial',
          letterSpacing: 1.5,
          color: Color(0xFF673AB7),
        );
        final resolver = TextfStyleResolver(
          options: const TextfOptionsData(boldStyle: TextStyle(fontWeight: FontWeight.w900)),
        );

        final resolvedBold = resolver.resolveStyle(
          FormatMarkerType.bold,
          specificBaseStyle,
          palette,
        );
        expect(resolvedBold.fontWeight, FontWeight.w900);
        expect(resolvedBold.fontSize, specificBaseStyle.fontSize);
        expect(resolvedBold.fontFamily, specificBaseStyle.fontFamily);
        expect(resolvedBold.letterSpacing, specificBaseStyle.letterSpacing);
        expect(resolvedBold.color, specificBaseStyle.color);
      });

      test('Option properties override baseStyle properties', () {
        final resolver = TextfStyleResolver(
          options: const TextfOptionsData(
            boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4CAF50)),
          ),
        );

        final resolvedBold = resolver.resolveStyle(FormatMarkerType.bold, baseStyle, palette);
        expect(resolvedBold.fontWeight, FontWeight.w900);
        expect(resolvedBold.color, const Color(0xFF4CAF50));
        expect(resolvedBold.fontSize, baseStyle.fontSize);
      });

      test('Neutral defaults override baseStyle color for links, not for code text', () {
        // No options, so link style and code style come from the neutral defaults
        final resolver = TextfStyleResolver(options: null);

        // Link
        final resolvedLink = resolver
            .resolveLinkConfiguration(baseStyle)
            .style; // baseStyle is black
        expect(
          resolvedLink.color,
          defaultLinkColor,
          reason: 'Link color should be the fixed default link blue',
        );
        expect(resolvedLink.decoration, TextDecoration.underline);
        expect(resolvedLink.fontSize, baseStyle.fontSize);

        // Code
        final resolvedCode = resolver.resolveStyle(
          FormatMarkerType.code,
          baseStyle,
          palette,
        ); // baseStyle is black
        expect(
          resolvedCode.color,
          baseStyle.color,
          reason: 'Code text keeps the segment color',
        );
        expect(resolvedCode.backgroundColor, defaultCodeBackground);
        expect(resolvedCode.fontFamily, 'monospace');
        expect(resolvedCode.fontSize, baseStyle.fontSize);
      });

      test('Default properties DO NOT override baseStyle for bold/italic if no option', () {
        // No options, so bold/italic come from DefaultStyles applied to baseStyle
        final resolver = TextfStyleResolver(options: null);

        // Bold
        final resolvedBold = resolver.resolveStyle(
          FormatMarkerType.bold,
          baseStyle,
          palette,
        ); // baseStyle is black
        expect(
          resolvedBold.color,
          baseStyle.color,
          reason: 'Bold color should be from baseStyle',
        ); // Unchanged by the relative default
        expect(resolvedBold.fontWeight, FontWeight.bold);
        expect(resolvedBold.fontSize, baseStyle.fontSize);

        // Italic
        final resolvedItalic = resolver.resolveStyle(FormatMarkerType.italic, baseStyle, palette);
        expect(
          resolvedItalic.color,
          baseStyle.color,
          reason: 'Italic color should be from baseStyle',
        ); // Unchanged by the relative default
        expect(resolvedItalic.fontStyle, FontStyle.italic);
        expect(resolvedItalic.fontSize, baseStyle.fontSize);
      });
    });
  });
}
