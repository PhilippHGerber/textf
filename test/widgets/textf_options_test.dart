// ignore_for_file: avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options.dart';

// ----- Helper Class and Callbacks -----
// ignore: prefer-match-file-name
class _ResolvedOptions {
  _ResolvedOptions({
    this.linkStyle,
    this.linkHoverStyle,
    this.linkMouseCursor,
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.strikethroughStyle,
    this.codeStyle,
    this.onLinkTap,
    this.onLinkHover,
  });

  // Factory to create from context
  factory _ResolvedOptions.fromContext(BuildContext context, TextStyle baseStyle) {
    final TextfOptions? nearestOptions = TextfOptions.maybeOf(context);
    final ThemeData theme = Theme.of(context); // Get theme for fallbacks

    // Helper to get theme-based link style merged with base
    TextStyle getThemeLinkStyle(TextStyle currentBase) {
      final Color themeLinkColor = theme.colorScheme.primary;
      // Default link style merged onto the current base
      return currentBase.merge(
        TextStyle(
          color: themeLinkColor,
          decoration: TextDecoration.underline,
          decorationColor: themeLinkColor,
        ),
      );
    }

    // Helper to get theme-based code style merged with base
    TextStyle getThemeCodeStyle(TextStyle currentBase) {
      final Color codeBackgroundColor = theme.colorScheme.surfaceContainer;
      final Color codeForegroundColor = theme.colorScheme.onSurfaceVariant;
      const String codeFontFamily = 'monospace';
      // FIX: Use the constant directly from DefaultStyles
      const List<String> codeFontFamilyFallback = DefaultStyles.defaultCodeFontFamilyFallback;

      return currentBase.copyWith(
        fontFamily: codeFontFamily,
        fontFamilyFallback: codeFontFamilyFallback, // Use the constant list
        backgroundColor: codeBackgroundColor,
        color: codeForegroundColor, // Theme color overrides base color
        letterSpacing: currentBase.letterSpacing ?? 0,
        // Other properties like fontSize, height are inherited from currentBase
      );
    }

    // Resolve each property individually, applying fallbacks if options are null
    final resolvedBold = nearestOptions?.getEffectiveBoldStyle(context, baseStyle) ??
        DefaultStyles.boldStyle(baseStyle); // Default fallback

    final resolvedItalic = nearestOptions?.getEffectiveItalicStyle(context, baseStyle) ??
        DefaultStyles.italicStyle(baseStyle); // Default fallback

    final resolvedBoldItalic = nearestOptions?.getEffectiveBoldItalicStyle(context, baseStyle) ??
        DefaultStyles.boldItalicStyle(baseStyle); // Default fallback

    final resolvedStrike = nearestOptions?.getEffectiveStrikethroughStyle(context, baseStyle) ??
        DefaultStyles.strikethroughStyle(baseStyle); // Default fallback

    final resolvedCode = nearestOptions?.getEffectiveCodeStyle(context, baseStyle) ??
        getThemeCodeStyle(baseStyle); // Theme fallback for code

    final resolvedLink = nearestOptions?.getEffectiveLinkStyle(context, baseStyle) ??
        getThemeLinkStyle(baseStyle); // Theme fallback for links

    // Hover style depends on the resolved *normal* style
    final resolvedLinkHover = nearestOptions?.getEffectiveLinkHoverStyle(context, baseStyle) ??
        resolvedLink; // Default hover is same as normal if no option

    final resolvedCursor = nearestOptions?.getEffectiveLinkMouseCursor(context) ??
        DefaultStyles.linkMouseCursor; // Default fallback

    final resolvedTap = nearestOptions?.getEffectiveOnLinkTap(context); // Null if not found
    final resolvedHoverCb = nearestOptions?.getEffectiveOnLinkHover(context); // Null if not found
    return _ResolvedOptions(
      linkStyle: resolvedLink,
      linkHoverStyle: resolvedLinkHover,
      linkMouseCursor: resolvedCursor,
      boldStyle: resolvedBold,
      italicStyle: resolvedItalic,
      boldItalicStyle: resolvedBoldItalic,
      strikethroughStyle: resolvedStrike,
      codeStyle: resolvedCode,
      onLinkTap: resolvedTap,
      onLinkHover: resolvedHoverCb,
    );
  }
  final TextStyle? linkStyle;
  final TextStyle? linkHoverStyle;
  final MouseCursor? linkMouseCursor;
  final TextStyle? boldStyle;
  final TextStyle? italicStyle;
  final TextStyle? boldItalicStyle;
  final TextStyle? strikethroughStyle;
  final TextStyle? codeStyle;
  final Function? onLinkTap;
  final Function? onLinkHover;
}

// Dummy callbacks
void _dummyTap1(String u, String d) {
  debugPrint('Dummy tap 1: $u, $d');
}

void _dummyHover2(String u, String d, {required bool isHovering}) {
  debugPrint('Dummy hover 2: $u, $d, hovering: $isHovering');
}
// ----------------------------------------------------------

void main() {
  // --- Test Styles & Callbacks (Keep as before) ---
  // Note: baseStyle here is only used when *no* DefaultTextStyle is in context,
  // which isn't the case in these tests due to MaterialApp.
  const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
  const rootBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Colors.red);
  const rootLinkStyle = TextStyle(color: Colors.blue, decoration: TextDecoration.none);
  const rootCursor = SystemMouseCursors.text;
  const rootOnTap = _dummyTap1;

  const childLinkStyle = TextStyle(color: Colors.green, fontSize: 18);
  const childItalicStyle = TextStyle(fontStyle: FontStyle.normal, backgroundColor: Colors.yellow);

  // ----------------------------------------------------

  group('TextfOptions Inheritance Tests', () {
    testWidgets('Falls back to defaults when no TextfOptions is present', (tester) async {
      _ResolvedOptions? resolved;
      final theme = ThemeData.light(); // Use a specific theme
      TextStyle? capturedDefaultStyle; // To capture the style from context

      await tester.pumpWidget(
        MaterialApp(
          theme: theme, // Provide theme
          home: Builder(
            builder: (context) {
              // Capture the actual DefaultTextStyle from the context where resolved is calculated
              capturedDefaultStyle = DefaultTextStyle.of(context).style;
              // Ensure we captured something sensible before proceeding
              expect(capturedDefaultStyle, isNotNull, reason: 'Failed to capture DefaultTextStyle');
              expect(
                capturedDefaultStyle!.fontSize,
                isNotNull,
                reason: 'Captured DefaultTextStyle must have a fontSize',
              );
              // Pass the captured style explicitly as the base style
              resolved = _ResolvedOptions.fromContext(context, capturedDefaultStyle!);
              return const SizedBox();
            },
          ),
        ),
      );

      // Ensure resolution happened
      expect(resolved, isNotNull, reason: 'ResolvedOptions should not be null after pump');

      // Ensure the captured style is still valid before using it in expectations
      expect(
        capturedDefaultStyle,
        isNotNull,
        reason: 'DefaultTextStyle should be available after pump',
      );
      expect(
        capturedDefaultStyle!.fontSize,
        isNotNull,
        reason: 'DefaultTextStyle must have a fontSize after pump',
      );

      // Verify resolved options match defaults merged with the capturedDefaultStyle

      // --- Check Link Style ---
      // Check inherited properties first
      expect(
        resolved!.linkStyle?.fontSize,
        capturedDefaultStyle!.fontSize, // Compare against the captured default size
        reason: 'Link style font size should match the DefaultTextStyle font size',
      );
      expect(
        resolved!.linkStyle?.fontFamily,
        capturedDefaultStyle!.fontFamily,
        reason: 'Link style font family should match the DefaultTextStyle font family',
      );
      // Check properties overridden by theme link style
      expect(
        resolved!.linkStyle?.color,
        theme.colorScheme.primary,
        reason: 'Link style color should be theme primary color',
      );
      expect(
        resolved!.linkStyle?.decoration,
        TextDecoration.underline,
        reason: 'Link style decoration should be underline',
      );
      expect(
        resolved!.linkStyle?.decorationColor,
        theme.colorScheme.primary,
        reason: 'Link style decoration color should be theme primary color',
      );

      // --- Check other styles (ensure they also use the correct base) ---
      expect(
        resolved!.boldStyle?.fontSize,
        capturedDefaultStyle!.fontSize,
        reason: 'Bold style font size should match default',
      );
      expect(
        resolved!.boldStyle?.fontWeight,
        DefaultStyles.boldStyle(capturedDefaultStyle!).fontWeight,
      );

      expect(
        resolved!.italicStyle?.fontSize,
        capturedDefaultStyle!.fontSize,
        reason: 'Italic style font size should match default',
      );
      expect(
        resolved!.italicStyle?.fontStyle,
        DefaultStyles.italicStyle(capturedDefaultStyle!).fontStyle,
      );

      // Code Style: Check against theme defaults merged with base
      expect(
        resolved!.codeStyle?.fontSize,
        capturedDefaultStyle!.fontSize,
        reason: 'Code style font size should match default',
      );
      expect(resolved!.codeStyle?.fontFamily, 'monospace');
      expect(resolved!.codeStyle?.color, theme.colorScheme.onSurfaceVariant);
      expect(resolved!.codeStyle?.backgroundColor, theme.colorScheme.surfaceContainer);

      // --- Check non-style properties ---
      expect(resolved!.linkMouseCursor, DefaultStyles.linkMouseCursor);
      expect(resolved!.onLinkTap, isNull);
      expect(resolved!.onLinkHover, isNull);
    });

    testWidgets('Uses values from single ancestor', (tester) async {
      _ResolvedOptions? resolved;
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            boldStyle: rootBoldStyle,
            linkStyle: rootLinkStyle, // blue, no decoration
            linkMouseCursor: rootCursor,
            onLinkTap: rootOnTap,
            // italicStyle left null
            child: Builder(
              builder: (context) {
                resolved = _ResolvedOptions.fromContext(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
      // Check specified values (merged with base)
      expect(resolved!.boldStyle?.fontWeight, rootBoldStyle.fontWeight);
      expect(resolved!.boldStyle?.color, rootBoldStyle.color);
      expect(resolved!.boldStyle?.fontSize, baseStyle.fontSize); // Merged from base
      expect(resolved!.linkStyle?.color, rootLinkStyle.color); // Should be root blue
      expect(resolved!.linkStyle?.decoration, rootLinkStyle.decoration); // none from root
      expect(resolved!.linkStyle?.fontSize, baseStyle.fontSize); // Merged from base
      expect(resolved!.linkMouseCursor, rootCursor);
      expect(resolved!.onLinkTap, same(rootOnTap));
      // Check unspecified (falls back to default effect on base)
      expect(
        resolved!.italicStyle?.fontStyle,
        DefaultStyles.italicStyle(baseStyle).fontStyle,
      ); // Default italic
      expect(resolved!.italicStyle?.color, baseStyle.color); // Base color
      // Check unspecified callback
      expect(resolved!.onLinkHover, isNull);
    });

    testWidgets('Child properties correctly merge with and override parent properties',
        (tester) async {
      // SETUP
      const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
      const rootLinkStyle = TextStyle(color: Colors.blue, decoration: TextDecoration.none);
      // ignore: no-empty-block
      void rootOnTap(String u, String d) {}
      const rootItalicStyle = TextStyle(fontStyle: FontStyle.italic, color: Colors.purple);

      const childLinkStyle =
          TextStyle(color: Colors.green, fontSize: 18); // No decoration specified
      // ignore: no-empty-block
      void childOnTap(String u, String d) {}

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            // Root
            linkStyle: rootLinkStyle,
            onLinkTap: rootOnTap,
            italicStyle: rootItalicStyle,
            child: TextfOptions(
              // Child override
              linkStyle: childLinkStyle,
              onLinkTap: childOnTap,
              // Italic style NOT specified here, so it should be inherited.
              child: const SizedBox(), // Dummy child for context
            ),
          ),
        ),
      );

      // ARRANGE: Get context and create the resolver
      final BuildContext context = tester.element(find.byType(SizedBox));
      final resolver = TextfStyleResolver(context);

      // --- ASSERT MERGED Link STYLE ---
      final resolvedLinkStyle = resolver.resolveLinkStyle(baseStyle);

      // Properties from child should win
      expect(
        resolvedLinkStyle.color,
        childLinkStyle.color,
        reason: 'Child color (green) should override parent color (blue).',
      );
      expect(
        resolvedLinkStyle.fontSize,
        childLinkStyle.fontSize,
        reason: 'Child font size (18) should override base style size (16).',
      );
      // Property from parent should be inherited
      expect(
        resolvedLinkStyle.decoration,
        rootLinkStyle.decoration, // TextDecoration.none
        reason: 'Parent decoration should be inherited as child did not specify one.',
      );

      // --- ASSERT INHERITED ITALIC STYLE ---
      final resolvedItalicStyle = resolver.resolveStyle(TokenType.italicMarker, baseStyle);
      expect(
        resolvedItalicStyle.color,
        rootItalicStyle.color,
        reason: 'Italic color should be inherited from parent.',
      );
      expect(
        resolvedItalicStyle.fontStyle,
        rootItalicStyle.fontStyle,
        reason: 'Italic style should be inherited from parent.',
      );

      // --- ASSERT CALLBACK (NEAREST WINS) ---
      expect(
        resolver.resolveOnLinkTap(),
        childOnTap,
        reason: 'Callback should come from the nearest (child) ancestor.',
      );
    });

    testWidgets('Unspecified child properties are correctly inherited from parent', (tester) async {
      // SETUP
      const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
      const rootBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Colors.red);
      // ignore: no-empty-block
      void rootOnTap(String u, String d) {}
      const rootLinkStyle = TextStyle(color: Colors.blue, decoration: TextDecoration.none);

      const childLinkStyle = TextStyle(color: Colors.green, fontSize: 18);
      const childItalicStyle =
          TextStyle(fontStyle: FontStyle.normal, backgroundColor: Colors.yellow);
      // ignore: no-empty-block
      void childOnHover(String u, String d, {required bool isHovering}) {}

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            // Root (provides bold, tap, rootUrl)
            boldStyle: rootBoldStyle,
            onLinkTap: rootOnTap,
            linkStyle: rootLinkStyle,
            child: TextfOptions(
              // Child (provides childUrl, italic, hover, but NOT bold or tap)
              linkStyle: childLinkStyle,
              italicStyle: childItalicStyle,
              onLinkHover: childOnHover,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      // ARRANGE
      final BuildContext context = tester.element(find.byType(SizedBox));
      final resolver = TextfStyleResolver(context);

      // --- 1. Assert properties specified ONLY in Child ---
      final resolvedItalic = resolver.resolveStyle(TokenType.italicMarker, baseStyle);
      expect(resolvedItalic.fontStyle, childItalicStyle.fontStyle);
      expect(resolvedItalic.backgroundColor, childItalicStyle.backgroundColor);
      expect(resolver.resolveOnLinkHover(), childOnHover);

      // --- 2. Assert properties MERGED between Parent and Child ---
      final resolvedLink = resolver.resolveLinkStyle(baseStyle);
      expect(
        resolvedLink.color,
        childLinkStyle.color, // Green from Child wins
        reason: 'Child URL color should override Parent.',
      );
      expect(
        resolvedLink.decoration,
        rootLinkStyle.decoration, // Decoration from Parent is inherited
        reason: "Child did not specify a decoration, so Parent's should be used.",
      );

      // --- 3. Assert properties inherited from Parent because Child did not specify them ---
      final resolvedBold = resolver.resolveStyle(TokenType.boldMarker, baseStyle);
      expect(resolvedBold.fontWeight, rootBoldStyle.fontWeight);
      expect(resolvedBold.color, rootBoldStyle.color);
      expect(resolver.resolveOnLinkTap(), rootOnTap);
    });

    testWidgets('Inheritance works across multiple levels', (tester) async {
      _ResolvedOptions? resolved;
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            // Level 1 (Root: bold, tap)
            boldStyle: rootBoldStyle, // w900, red
            onLinkTap: rootOnTap,
            child: TextfOptions(
              // Level 2 (Mid: italic)
              italicStyle: childItalicStyle, // normal, yellow bg
              child: TextfOptions(
                // Level 3 (Leaf: link, hover)
                linkStyle: childLinkStyle, // green, 18
                onLinkHover: _dummyHover2,
                // codeStyle not specified anywhere
                child: Builder(
                  builder: (context) {
                    resolved = _ResolvedOptions.fromContext(context, baseStyle); // black, 16
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
      // Comes from Leaf (Level 3)
      expect(resolved!.linkStyle?.color, childLinkStyle.color); // green
      expect(resolved!.linkStyle?.fontSize, childLinkStyle.fontSize); // 18
      expect(resolved!.onLinkHover, same(_dummyHover2));
      // Comes from Mid (Level 2)
      expect(resolved!.italicStyle?.backgroundColor, childItalicStyle.backgroundColor); // yellow bg
      expect(resolved!.italicStyle?.fontStyle, childItalicStyle.fontStyle); // normal
      // Comes from Root (Level 1)
      expect(resolved!.boldStyle?.fontWeight, rootBoldStyle.fontWeight); // w900
      expect(resolved!.boldStyle?.color, rootBoldStyle.color); // red
      expect(resolved!.onLinkTap, same(rootOnTap));
      // Comes from Default (Not specified anywhere) - Check Code style default
      expect(
        resolved!.codeStyle?.fontFamily,
        'monospace', // Expect default monospace
        reason: 'Code style fallback should use monospace font',
      );
      expect(resolved!.codeStyle?.color, theme.colorScheme.onSurfaceVariant); // Theme color
      expect(resolved!.linkMouseCursor, DefaultStyles.linkMouseCursor); // Default cursor
    });

    testWidgets('Correctly merges styles with baseStyle', (tester) async {
      _ResolvedOptions? resolved;
      final theme = ThemeData.light();
      // Use a distinct base style
      const specificBaseStyle = TextStyle(fontSize: 10, fontFamily: 'Arial', color: Colors.grey);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            boldStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ), // Override weight and color
            italicStyle: const TextStyle(fontStyle: FontStyle.italic), // Only specify italic effect
            linkStyle: const TextStyle(
              // Specify only decoration properties
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.orange,
            ),
            child: Builder(
              builder: (context) {
                resolved =
                    _ResolvedOptions.fromContext(context, specificBaseStyle); // grey, 10, Arial
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(resolved, isNotNull);

      // Bold: Should have specific base props + override props
      expect(resolved!.boldStyle?.fontWeight, FontWeight.bold); // from override
      expect(resolved!.boldStyle?.color, Colors.red); // from override
      expect(resolved!.boldStyle?.fontSize, specificBaseStyle.fontSize); // from base
      expect(resolved!.boldStyle?.fontFamily, specificBaseStyle.fontFamily); // from base

      // Italic: Should have specific base props + default italic effect
      expect(resolved!.italicStyle?.fontStyle, FontStyle.italic); // from override
      expect(resolved!.italicStyle?.color, specificBaseStyle.color); // from base
      expect(resolved!.italicStyle?.fontSize, specificBaseStyle.fontSize); // from base

      // Link: Should have base props + override props. Color comes from base as option didn't specify it.
      expect(resolved!.linkStyle?.decoration, TextDecoration.lineThrough); // from override
      expect(resolved!.linkStyle?.decorationColor, Colors.orange); // from override
      expect(
        resolved!.linkStyle?.color,
        specificBaseStyle.color, // Should be grey from base
        reason: "Link color should be from baseStyle as option didn't specify it",
      );
      expect(resolved!.linkStyle?.fontSize, specificBaseStyle.fontSize); // from base
      expect(resolved!.linkStyle?.fontFamily, specificBaseStyle.fontFamily); // from base
    });
  });
}
