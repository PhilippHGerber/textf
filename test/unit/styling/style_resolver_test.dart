import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

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

    // Helper to build a widget tree with a Builder to capture context.
    // Optionally wraps the Builder with TextfOptions.
    Future<BuildContext> pumpWithContext(
      WidgetTester tester, {
      TextfOptions? options,
      TextfOptions? parentOptions,
    }) async {
      // ignore: avoid-late-keyword
      late BuildContext capturedContext;
      Widget child = Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      );

      // Apply inner options first if they exist
      if (options != null) {
        child = TextfOptions(
          key: options.key,
          boldStyle: options.boldStyle,
          italicStyle: options.italicStyle,
          boldItalicStyle: options.boldItalicStyle,
          strikethroughStyle: options.strikethroughStyle,
          strikethroughThickness: options.strikethroughThickness,
          codeStyle: options.codeStyle,
          underlineStyle: options.underlineStyle,
          highlightStyle: options.highlightStyle,
          linkStyle: options.linkStyle,
          linkHoverStyle: options.linkHoverStyle,
          linkMouseCursor: options.linkMouseCursor,
          linkAlignment: options.linkAlignment,
          linkColor: options.linkColor,
          onLinkTap: options.onLinkTap,
          onLinkHover: options.onLinkHover,
          child: child,
        );
      }

      // Then wrap with parent options if they exist
      if (parentOptions != null) {
        child = TextfOptions(
          key: parentOptions.key,
          boldStyle: parentOptions.boldStyle,
          italicStyle: parentOptions.italicStyle,
          boldItalicStyle: parentOptions.boldItalicStyle,
          strikethroughStyle: parentOptions.strikethroughStyle,
          strikethroughThickness: parentOptions.strikethroughThickness,
          codeStyle: parentOptions.codeStyle,
          underlineStyle: parentOptions.underlineStyle,
          highlightStyle: parentOptions.highlightStyle,
          linkStyle: parentOptions.linkStyle,
          linkHoverStyle: parentOptions.linkHoverStyle,
          linkMouseCursor: parentOptions.linkMouseCursor,
          linkAlignment: parentOptions.linkAlignment,
          linkColor: parentOptions.linkColor,
          onLinkTap: parentOptions.onLinkTap,
          onLinkHover: parentOptions.onLinkHover,
          child: child,
        );
      }

      // No design-system app: the resolver only reads TextfOptions from the context.
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: child));
      return capturedContext;
    }

    group('No TextfOptions (Fallback to Defaults)', () {
      // ignore: avoid-late-keyword
      late BuildContext testContext;
      // ignore: avoid-late-keyword
      late TextfStyleResolver resolver;

      // setUp needs to be called within testWidgets or use a helper that takes tester
      // For simplicity, we'll get context and resolver inside each testWidgets.

      testWidgets('Initializes correctly and resolver can be created', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        expect(resolver, isNotNull);
      });

      testWidgets('resolveStyle for bold uses DefaultStyles.boldStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(FormatMarkerType.bold, baseStyle, palette);
        expect(resolved.fontWeight, FontWeight.bold);
        expect(resolved.fontSize, baseStyle.fontSize);
        expect(resolved.color, baseStyle.color);
      });

      testWidgets('resolveStyle for italic uses DefaultStyles.italicStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(FormatMarkerType.italic, baseStyle, palette);
        expect(resolved.fontStyle, FontStyle.italic);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for boldItalic uses DefaultStyles.boldItalicStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(FormatMarkerType.boldItalic, baseStyle, palette);
        expect(resolved.fontWeight, FontWeight.bold);
        expect(resolved.fontStyle, FontStyle.italic);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets(
        'resolveStyle for strikethrough uses DefaultStyles.strikethroughStyle with default thickness',
        (tester) async {
          testContext = await pumpWithContext(tester);
          resolver = TextfStyleResolver(testContext);
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

      testWidgets('resolveStyle for code uses the neutral default', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(FormatMarkerType.code, baseStyle, palette);
        expect(resolved.fontFamily, 'monospace');
        expect(resolved.fontFamilyFallback, DefaultStyles.defaultCodeFontFamilyFallback);
        expect(resolved.backgroundColor, defaultCodeBackground);
        expect(resolved.color, baseStyle.color); // Code text keeps the segment color
        expect(resolved.fontSize, baseStyle.fontSize); // Base font size
      });

      testWidgets('resolveStyle for underline uses DefaultStyles.underlineStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(FormatMarkerType.underline, baseStyle, palette);
        expect(resolved.decoration, TextDecoration.underline);
        expect(resolved.decorationColor, baseStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for highlight uses the neutral default', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(FormatMarkerType.highlight, baseStyle, palette);
        expect(resolved.backgroundColor, const Color(0xFFFFEB3B).withValues(alpha: 0.5));
        expect(resolved.color, baseStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveLinkConfiguration uses neutral defaults', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
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

      final options = TextfOptions(
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
        child: const SizedBox.shrink(),
      );

      testWidgets('resolveStyle for bold uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveStyle(
          FormatMarkerType.bold,
          baseStyle,
          palette,
        );
        expect(resolved.fontWeight, optionBoldStyle.fontWeight);
        expect(resolved.color, optionBoldStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for italic uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveStyle(
          FormatMarkerType.italic,
          baseStyle,
          palette,
        );
        expect(resolved.fontStyle, optionItalicStyle.fontStyle);
        expect(resolved.color, optionItalicStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for strikethrough uses TextfOptions.strikethroughStyle', (
        tester,
      ) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
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

      testWidgets(
        'resolveStyle for strikethrough uses TextfOptions.strikethroughThickness if style is null',
        (tester) async {
          const optionsWithThickness = TextfOptions(
            strikethroughThickness: optionStrikeThickness,
            child: SizedBox.shrink(),
          );
          final context = await pumpWithContext(tester, options: optionsWithThickness);
          final resolver = TextfStyleResolver(context);

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

      testWidgets('resolveStyle for code uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveStyle(
          FormatMarkerType.code,
          baseStyle,
          palette,
        );
        expect(resolved.backgroundColor, optionCodeStyle.backgroundColor);
        expect(resolved.fontFamily, optionCodeStyle.fontFamily);
        expect(resolved.color, baseStyle.color);
      });

      testWidgets('resolveLinkConfiguration uses TextfOptions overrides for all fields', (
        tester,
      ) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
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

      testWidgets('resolveLinkConfiguration respects linkColor option when no linkStyle is set', (
        tester,
      ) async {
        const customLinkColor = Color(0xFF009688);
        const optionsWithLinkColor = TextfOptions(
          linkColor: customLinkColor,
          child: SizedBox.shrink(),
        );
        final testContext = await pumpWithContext(tester, options: optionsWithLinkColor);
        final resolver = TextfStyleResolver(testContext);
        final config = resolver.resolveLinkConfiguration(baseStyle);

        expect(config.style.color, customLinkColor);
        expect(config.style.decoration, TextDecoration.underline);
        expect(config.style.decorationColor, customLinkColor);
      });

      testWidgets('explicit linkStyle takes precedence over linkColor option', (tester) async {
        const customLinkColor = Color(0xFF009688);
        const explicitLinkStyle = TextStyle(color: Color(0xFFFF5722));
        const optionsWithBoth = TextfOptions(
          linkColor: customLinkColor,
          linkStyle: explicitLinkStyle,
          child: SizedBox.shrink(),
        );
        final testContext = await pumpWithContext(tester, options: optionsWithBoth);
        final resolver = TextfStyleResolver(testContext);
        final config = resolver.resolveLinkConfiguration(baseStyle);

        expect(config.style.color, explicitLinkStyle.color);
      });
    });

    group('With Nested TextfOptions', () {
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
        final context = await pumpWithContext(
          tester,
          parentOptions: parentOpts,
          options: childOptsWithOverride,
        );
        final resolver = TextfStyleResolver(context);

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
        final context = await pumpWithContext(
          tester,
          parentOptions: parentOpts, // Outer (provides linkStyle, italicStyle from parentOpts)
          options: const TextfOptions(
            child: SizedBox.shrink(),
          ), // Inner (linkStyle is implicitly null)
        );
        final resolver = TextfStyleResolver(context);

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

        final context = await pumpWithContext(tester, parentOptions: parent, options: child);
        final resolver = TextfStyleResolver(context);

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
      testWidgets('baseStyle properties are preserved if not overridden', (tester) async {
        const specificBaseStyle = TextStyle(
          fontSize: 20,
          fontFamily: 'Arial',
          letterSpacing: 1.5,
          color: Color(0xFF673AB7),
        );
        const options = TextfOptions(
          boldStyle: TextStyle(fontWeight: FontWeight.w900),
          child: SizedBox.shrink(),
        );
        final context = await pumpWithContext(tester, options: options);
        final resolver = TextfStyleResolver(context);

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

      testWidgets('Option properties override baseStyle properties', (tester) async {
        const options = TextfOptions(
          boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4CAF50)),
          child: SizedBox.shrink(),
        );
        final context = await pumpWithContext(tester, options: options);
        final resolver = TextfStyleResolver(context);

        final resolvedBold = resolver.resolveStyle(FormatMarkerType.bold, baseStyle, palette);
        expect(resolvedBold.fontWeight, FontWeight.w900);
        expect(resolvedBold.color, const Color(0xFF4CAF50));
        expect(resolvedBold.fontSize, baseStyle.fontSize);
      });

      testWidgets('Neutral defaults override baseStyle color for links, not for code text', (
        tester,
      ) async {
        // No options, so link style and code style come from the neutral defaults
        final context = await pumpWithContext(tester);
        final resolver = TextfStyleResolver(context);

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

      testWidgets(
        'Default properties DO NOT override baseStyle for bold/italic if no option',
        (tester) async {
          // No options, so bold/italic come from DefaultStyles applied to baseStyle
          final context = await pumpWithContext(tester);
          final resolver = TextfStyleResolver(context);

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
        },
      );
    });
  });
}
