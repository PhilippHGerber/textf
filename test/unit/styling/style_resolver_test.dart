import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';

void main() {
  // Ensure Flutter bindings are initialized for ThemeData access.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('TextfStyleResolver Tests', () {
    // A base style to be used in tests.
    const TextStyle baseStyle = TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontFamily: 'Roboto',
      decoration: TextDecoration.none, // Explicitly none for easier testing
    );

    // A common light theme for consistent testing of theme-based defaults.
    final ThemeData lightTheme = ThemeData.light();

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
          urlStyle: options.urlStyle,
          urlHoverStyle: options.urlHoverStyle,
          urlMouseCursor: options.urlMouseCursor,
          onUrlTap: options.onUrlTap,
          onUrlHover: options.onUrlHover,
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
          urlStyle: parentOptions.urlStyle,
          urlHoverStyle: parentOptions.urlHoverStyle,
          urlMouseCursor: parentOptions.urlMouseCursor,
          onUrlTap: parentOptions.onUrlTap,
          onUrlHover: parentOptions.onUrlHover,
          child: child,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme, // Use the consistent lightTheme
          home: child,
        ),
      );
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

      testWidgets('resolveStyle for boldMarker uses DefaultStyles.boldStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(TokenType.boldMarker, baseStyle);
        expect(resolved.fontWeight, FontWeight.bold);
        expect(resolved.fontSize, baseStyle.fontSize);
        expect(resolved.color, baseStyle.color);
      });

      testWidgets('resolveStyle for italicMarker uses DefaultStyles.italicStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(TokenType.italicMarker, baseStyle);
        expect(resolved.fontStyle, FontStyle.italic);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for boldItalicMarker uses DefaultStyles.boldItalicStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(TokenType.boldItalicMarker, baseStyle);
        expect(resolved.fontWeight, FontWeight.bold);
        expect(resolved.fontStyle, FontStyle.italic);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for strikeMarker uses DefaultStyles.strikethroughStyle with default thickness',
          (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(TokenType.strikeMarker, baseStyle);
        expect(resolved.decoration, TextDecoration.lineThrough);
        expect(resolved.decorationThickness, DefaultStyles.defaultStrikethroughThickness);
        expect(resolved.decorationColor, baseStyle.color); // Inherits base color for decoration
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for codeMarker uses theme-based default', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(TokenType.codeMarker, baseStyle);
        expect(resolved.fontFamily, 'monospace');
        expect(resolved.fontFamilyFallback, DefaultStyles.defaultCodeFontFamilyFallback);
        expect(resolved.backgroundColor, lightTheme.colorScheme.surfaceContainer);
        expect(resolved.color, lightTheme.colorScheme.onSurfaceVariant); // Theme color for text
        expect(resolved.fontSize, baseStyle.fontSize); // Base font size
      });

      testWidgets('resolveStyle for underlineMarker uses DefaultStyles.underlineStyle', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(TokenType.underlineMarker, baseStyle);
        expect(resolved.decoration, TextDecoration.underline);
        expect(resolved.decorationColor, baseStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for highlightMarker uses theme-based default', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveStyle(TokenType.highlightMarker, baseStyle);
        expect(resolved.backgroundColor, isNotNull);
        expect(resolved.backgroundColor, isNot(baseStyle.backgroundColor));
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveLinkStyle uses theme-based default', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolved = resolver.resolveLinkStyle(baseStyle);
        expect(resolved.color, lightTheme.colorScheme.primary);
        expect(resolved.decoration, TextDecoration.underline);
        expect(resolved.decorationColor, lightTheme.colorScheme.primary);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveLinkHoverStyle defaults to normal link style', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        final resolvedNormal = resolver.resolveLinkStyle(baseStyle);
        final resolvedHover = resolver.resolveLinkHoverStyle(baseStyle);
        expect(resolvedHover, resolvedNormal);
      });

      testWidgets('resolveLinkMouseCursor uses DefaultStyles.urlMouseCursor', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        expect(resolver.resolveLinkMouseCursor(), DefaultStyles.urlMouseCursor);
      });

      testWidgets('resolveOnUrlTap returns null', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        expect(resolver.resolveOnUrlTap(), isNull);
      });

      testWidgets('resolveOnUrlHover returns null', (tester) async {
        testContext = await pumpWithContext(tester);
        resolver = TextfStyleResolver(testContext);
        expect(resolver.resolveOnUrlHover(), isNull);
      });
    });

    group('With TextfOptions (Single Level)', () {
      const optionBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Colors.red);
      const optionItalicStyle = TextStyle(fontStyle: FontStyle.normal, color: Colors.green);
      // CORRECTED: optionStrikeStyle now includes the decoration itself
      const optionStrikeStyle = TextStyle(
        decoration: TextDecoration.lineThrough, // Added this
        decorationColor: Colors.purple,
        decorationThickness: 3,
      );
      const optionStrikeThickness = 2.5;
      const optionCodeStyle = TextStyle(backgroundColor: Colors.grey, fontFamily: 'Courier');
      const optionUrlStyle = TextStyle(color: Colors.orange, decoration: TextDecoration.overline);
      const optionUrlHoverStyle = TextStyle(color: Colors.pink, letterSpacing: 2);
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
        urlStyle: optionUrlStyle,
        urlHoverStyle: optionUrlHoverStyle,
        urlMouseCursor: optionCursor,
        onUrlTap: testOnTap,
        onUrlHover: testOnHover,
        child: const SizedBox.shrink(),
      );

      testWidgets('resolveStyle for boldMarker uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveStyle(TokenType.boldMarker, baseStyle);
        expect(resolved.fontWeight, optionBoldStyle.fontWeight);
        expect(resolved.color, optionBoldStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for italicMarker uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveStyle(TokenType.italicMarker, baseStyle);
        expect(resolved.fontStyle, optionItalicStyle.fontStyle);
        expect(resolved.color, optionItalicStyle.color);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveStyle for strikeMarker uses TextfOptions.strikethroughStyle', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveStyle(TokenType.strikeMarker, baseStyle);
        // Now it should have the decoration from optionStrikeStyle
        expect(resolved.decoration, optionStrikeStyle.decoration); // CORRECTED EXPECTATION
        expect(resolved.decorationColor, optionStrikeStyle.decorationColor);
        expect(resolved.decorationThickness, optionStrikeStyle.decorationThickness);
      });

      testWidgets('resolveStyle for strikeMarker uses TextfOptions.strikethroughThickness if style is null',
          (tester) async {
        const optionsWithThickness = TextfOptions(
          strikethroughThickness: optionStrikeThickness,
          child: SizedBox.shrink(),
        );
        final context = await pumpWithContext(tester, options: optionsWithThickness);
        final resolver = TextfStyleResolver(context);

        final resolved = resolver.resolveStyle(TokenType.strikeMarker, baseStyle);
        expect(resolved.decoration, TextDecoration.lineThrough);
        expect(resolved.decorationThickness, optionStrikeThickness);
        expect(resolved.decorationColor, baseStyle.color);
      });

      testWidgets('resolveStyle for codeMarker uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveStyle(TokenType.codeMarker, baseStyle);
        expect(resolved.backgroundColor, optionCodeStyle.backgroundColor);
        expect(resolved.fontFamily, optionCodeStyle.fontFamily);
        expect(resolved.color, baseStyle.color);
      });

      testWidgets('resolveLinkStyle uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final resolved = resolverWithOptions.resolveLinkStyle(baseStyle);
        expect(resolved.color, optionUrlStyle.color);
        expect(resolved.decoration, optionUrlStyle.decoration);
        expect(resolved.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveLinkHoverStyle uses TextfOptions and merges onto normal style', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        final normalLinkStyleWithOptions = baseStyle.merge(optionUrlStyle);
        final resolvedHover = resolverWithOptions.resolveLinkHoverStyle(baseStyle);

        expect(resolvedHover.color, optionUrlHoverStyle.color);
        expect(resolvedHover.letterSpacing, optionUrlHoverStyle.letterSpacing);
        expect(resolvedHover.decoration, normalLinkStyleWithOptions.decoration);
        expect(resolvedHover.fontSize, baseStyle.fontSize);
      });

      testWidgets('resolveLinkMouseCursor uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        expect(resolverWithOptions.resolveLinkMouseCursor(), optionCursor);
      });

      testWidgets('resolveOnUrlTap uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        expect(resolverWithOptions.resolveOnUrlTap(), testOnTap);
      });

      testWidgets('resolveOnUrlHover uses TextfOptions', (tester) async {
        final testContextWithOptions = await pumpWithContext(tester, options: options);
        final resolverWithOptions = TextfStyleResolver(testContextWithOptions);
        expect(resolverWithOptions.resolveOnUrlHover(), testOnHover);
      });
    });

    group('With Nested TextfOptions', () {
      const parentBoldStyle = TextStyle(color: Colors.amber);
      // CORRECTED: parentUrlStyle now defines no color, so baseStyle or theme should provide it
      const parentUrlStyle = TextStyle(decoration: TextDecoration.none /* no color here */);
      void parentTap(String u, String d) {
        debugPrint('Parent tapped URL: $u with display text: $d');
      }

      const childBoldStyle = TextStyle(fontWeight: FontWeight.w300);
      const childItalicStyle = TextStyle(fontStyle: FontStyle.normal, color: Colors.teal);
      void childTap(String u, String d) {
        debugPrint('Child tapped URL: $u with display text: $d');
      }

      final parentOpts = TextfOptions(
        boldStyle: parentBoldStyle,
        urlStyle: parentUrlStyle,
        onUrlTap: parentTap,
        italicStyle: const TextStyle(color: Colors.cyan),
        child: const SizedBox.shrink(),
      );

      final childOptsWithOverride = TextfOptions(
        boldStyle: childBoldStyle,
        italicStyle: childItalicStyle,
        onUrlTap: childTap,
        child: const SizedBox.shrink(),
      );

      testWidgets('Nested options correctly merge with and override ancestor values', (tester) async {
        // SETUP:
        // parentOpts provides a red color for bold text.
        // childOptsWithOverride provides a light font weight for bold text.
        // The expected result is a MERGE of both.

        const parentBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Colors.red);
        const parentItalicStyle = TextStyle(fontStyle: FontStyle.italic, color: Colors.purple);
        void parentTap(String u, String d) {}

        const childBoldStyle = TextStyle(fontWeight: FontWeight.w300); // No color specified.
        const childItalicStyle = TextStyle(fontStyle: FontStyle.normal, backgroundColor: Colors.yellow);
        void childTap(String u, String d) {}

        final parentOpts = TextfOptions(
          boldStyle: parentBoldStyle,
          italicStyle: parentItalicStyle,
          onUrlTap: parentTap,
          child: const SizedBox.shrink(),
        );

        final childOptsWithOverride = TextfOptions(
          boldStyle: childBoldStyle,
          italicStyle: childItalicStyle,
          onUrlTap: childTap,
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
        final resolvedBold = resolver.resolveStyle(TokenType.boldMarker, baseStyle);
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
        final resolvedItalic = resolver.resolveStyle(TokenType.italicMarker, baseStyle);
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
        expect(
          resolver.resolveOnUrlTap(),
          childTap,
          reason: 'Callback should be taken from the nearest (child) TextfOptions.',
        );
      });

      testWidgets('Falls back to ancestor if nearest option is null for a property', (tester) async {
        final context = await pumpWithContext(
          tester,
          parentOptions: parentOpts, // Outer (provides urlStyle, italicStyle from parentOpts)
          options: const TextfOptions(child: SizedBox.shrink()), // Inner (urlStyle is implicitly null)
        );
        final resolver = TextfStyleResolver(context);

        final resolvedUrl = resolver.resolveLinkStyle(baseStyle);
        expect(resolvedUrl.decoration, parentUrlStyle.decoration); // From parent
        // CORRECTED EXPECTATION: parentUrlStyle has no color, so it should be baseStyle.color
        // *IF* the theme fallback didn't kick in.
        // However, if an option for urlStyle exists (even without color), the theme fallback for color is NOT used.
        // The color comes from merging baseStyle with the optionStyle.
        expect(
          resolvedUrl.color,
          baseStyle.color,
          reason: "Color should be from baseStyle as parentUrlStyle didn't set it.",
        );

        final resolvedItalic = resolver.resolveStyle(TokenType.italicMarker, baseStyle);
        expect(resolvedItalic.color, Colors.cyan);
      });

      testWidgets('Falls back to theme/DefaultStyles if all ancestors have null', (tester) async {
        const specificOptionItalicStyle = TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey);
        const parent = TextfOptions(boldStyle: parentBoldStyle, child: SizedBox.shrink());
        const child = TextfOptions(italicStyle: specificOptionItalicStyle, child: SizedBox.shrink());

        final context = await pumpWithContext(tester, parentOptions: parent, options: child);
        final resolver = TextfStyleResolver(context);

        final resolvedCode = resolver.resolveStyle(TokenType.codeMarker, baseStyle);
        expect(resolvedCode.fontFamily, 'monospace');
        expect(resolvedCode.backgroundColor, lightTheme.colorScheme.surfaceContainer);
        expect(resolvedCode.color, lightTheme.colorScheme.onSurfaceVariant);

        final resolvedHighlight = resolver.resolveStyle(TokenType.highlightMarker, baseStyle);
        expect(resolvedHighlight.backgroundColor, isNotNull);
      });
    });

    group('Style Merging Details', () {
      testWidgets('baseStyle properties are preserved if not overridden', (tester) async {
        const specificBaseStyle = TextStyle(
          fontSize: 20,
          fontFamily: 'Arial',
          letterSpacing: 1.5,
          color: Colors.deepPurple,
        );
        const options = TextfOptions(
          boldStyle: TextStyle(fontWeight: FontWeight.w900),
          child: SizedBox.shrink(),
        );
        final context = await pumpWithContext(tester, options: options);
        final resolver = TextfStyleResolver(context);

        final resolvedBold = resolver.resolveStyle(TokenType.boldMarker, specificBaseStyle);
        expect(resolvedBold.fontWeight, FontWeight.w900);
        expect(resolvedBold.fontSize, specificBaseStyle.fontSize);
        expect(resolvedBold.fontFamily, specificBaseStyle.fontFamily);
        expect(resolvedBold.letterSpacing, specificBaseStyle.letterSpacing);
        expect(resolvedBold.color, specificBaseStyle.color);
      });

      testWidgets('Option properties override baseStyle properties', (tester) async {
        const options = TextfOptions(
          boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.green),
          child: SizedBox.shrink(),
        );
        final context = await pumpWithContext(tester, options: options);
        final resolver = TextfStyleResolver(context);

        final resolvedBold = resolver.resolveStyle(TokenType.boldMarker, baseStyle);
        expect(resolvedBold.fontWeight, FontWeight.w900);
        expect(resolvedBold.color, Colors.green);
        expect(resolvedBold.fontSize, baseStyle.fontSize);
      });

      testWidgets('Theme-default properties override baseStyle properties for links and code', (tester) async {
        // No options, so link style and code style come from theme
        final context = await pumpWithContext(tester);
        final resolver = TextfStyleResolver(context);

        // Link
        final resolvedLink = resolver.resolveLinkStyle(baseStyle); // baseStyle is black
        expect(resolvedLink.color, lightTheme.colorScheme.primary, reason: 'Link color should be theme primary');
        expect(resolvedLink.decoration, TextDecoration.underline);
        expect(resolvedLink.fontSize, baseStyle.fontSize);

        // Code
        final resolvedCode = resolver.resolveStyle(TokenType.codeMarker, baseStyle); // baseStyle is black
        expect(
          resolvedCode.color,
          lightTheme.colorScheme.onSurfaceVariant,
          reason: 'Code color should be theme onSurfaceVariant',
        );
        expect(resolvedCode.backgroundColor, lightTheme.colorScheme.surfaceContainer);
        expect(resolvedCode.fontFamily, 'monospace');
        expect(resolvedCode.fontSize, baseStyle.fontSize);
      });

      testWidgets('Theme-default properties DO NOT override baseStyle for bold/italic if no option', (tester) async {
        // No options, so bold/italic come from DefaultStyles applied to baseStyle
        final context = await pumpWithContext(tester);
        final resolver = TextfStyleResolver(context);

        // Bold
        final resolvedBold = resolver.resolveStyle(TokenType.boldMarker, baseStyle); // baseStyle is black
        expect(resolvedBold.color, baseStyle.color, reason: 'Bold color should be from baseStyle'); // Not from theme
        expect(resolvedBold.fontWeight, FontWeight.bold);
        expect(resolvedBold.fontSize, baseStyle.fontSize);

        // Italic
        final resolvedItalic = resolver.resolveStyle(TokenType.italicMarker, baseStyle);
        expect(
          resolvedItalic.color,
          baseStyle.color,
          reason: 'Italic color should be from baseStyle',
        ); // Not from theme
        expect(resolvedItalic.fontStyle, FontStyle.italic);
        expect(resolvedItalic.fontSize, baseStyle.fontSize);
      });
    });
  });
}
