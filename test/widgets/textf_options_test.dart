import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/widgets/textf_options.dart';

// ----- Helper Class and Callbacks -----
class ResolvedOptions {
  final TextStyle? urlStyle;
  final TextStyle? urlHoverStyle;
  final MouseCursor? urlMouseCursor;
  final TextStyle? boldStyle;
  final TextStyle? italicStyle;
  final TextStyle? boldItalicStyle;
  final TextStyle? strikethroughStyle;
  final TextStyle? codeStyle;
  final Function? onUrlTap;
  final Function? onUrlHover;

  ResolvedOptions({
    this.urlStyle,
    this.urlHoverStyle,
    this.urlMouseCursor,
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.strikethroughStyle,
    this.codeStyle,
    this.onUrlTap,
    this.onUrlHover,
  });

  // Factory to create from context
  factory ResolvedOptions.fromContext(BuildContext context, TextStyle baseStyle) {
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
      final List<String> codeFontFamilyFallback =
          DefaultStyles.codeStyle(currentBase).fontFamilyFallback ?? ['RobotoMono', 'Menlo', 'Courier New'];

      return currentBase.copyWith(
        fontFamily: codeFontFamily,
        fontFamilyFallback: codeFontFamilyFallback,
        backgroundColor: codeBackgroundColor,
        color: codeForegroundColor,
        letterSpacing: currentBase.letterSpacing ?? 0,
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

    final resolvedUrl = nearestOptions?.getEffectiveUrlStyle(context, baseStyle) ??
        getThemeLinkStyle(baseStyle); // Theme fallback for links

    // Hover style depends on the resolved *normal* style
    final resolvedUrlHover = nearestOptions?.getEffectiveUrlHoverStyle(context, baseStyle) ??
        resolvedUrl; // Default hover is same as normal if no option

    final resolvedCursor =
        nearestOptions?.getEffectiveUrlMouseCursor(context) ?? DefaultStyles.urlMouseCursor; // Default fallback

    final resolvedTap = nearestOptions?.getEffectiveOnUrlTap(context); // Null if not found
    final resolvedHoverCb = nearestOptions?.getEffectiveOnUrlHover(context); // Null if not found

    return ResolvedOptions(
      urlStyle: resolvedUrl,
      urlHoverStyle: resolvedUrlHover,
      urlMouseCursor: resolvedCursor,
      boldStyle: resolvedBold,
      italicStyle: resolvedItalic,
      boldItalicStyle: resolvedBoldItalic,
      strikethroughStyle: resolvedStrike,
      codeStyle: resolvedCode,
      onUrlTap: resolvedTap,
      onUrlHover: resolvedHoverCb,
    );
  }
}

// Dummy callbacks
void dummyTap1(String u, String d) {}
void dummyTap2(String u, String d) {}
void dummyHover1(String u, String d, bool h) {}
void dummyHover2(String u, String d, bool h) {}
// ----------------------------------------------------------

void main() {
  // --- Test Styles & Callbacks (Keep as before) ---
  // Note: baseStyle here is only used when *no* DefaultTextStyle is in context,
  // which isn't the case in these tests due to MaterialApp.
  const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
  const rootBoldStyle = TextStyle(fontWeight: FontWeight.w900, color: Colors.red);
  const rootUrlStyle = TextStyle(color: Colors.blue, decoration: TextDecoration.none);
  const rootCursor = SystemMouseCursors.text;
  final rootOnTap = dummyTap1;

  const childUrlStyle = TextStyle(color: Colors.green, fontSize: 18);
  const childItalicStyle = TextStyle(fontStyle: FontStyle.normal, backgroundColor: Colors.yellow);

  final childOnTap = dummyTap2;
  // ----------------------------------------------------

  group('TextfOptions Inheritance Tests', () {
    testWidgets('Falls back to defaults when no TextfOptions is present', (tester) async {
      ResolvedOptions? resolved;
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
              expect(capturedDefaultStyle, isNotNull, reason: "Failed to capture DefaultTextStyle");
              expect(
                capturedDefaultStyle!.fontSize,
                isNotNull,
                reason: "Captured DefaultTextStyle must have a fontSize",
              );
              // Pass the captured style explicitly as the base style
              resolved = ResolvedOptions.fromContext(context, capturedDefaultStyle!);
              return const SizedBox();
            },
          ),
        ),
      );

      // Ensure resolution happened
      expect(resolved, isNotNull, reason: "ResolvedOptions should not be null after pump");

      // Ensure the captured style is still valid before using it in expectations
      expect(capturedDefaultStyle, isNotNull, reason: "DefaultTextStyle should be available after pump");
      expect(capturedDefaultStyle!.fontSize, isNotNull, reason: "DefaultTextStyle must have a fontSize after pump");

      // Verify resolved options match defaults merged with the capturedDefaultStyle

      // --- Check URL Style ---
      // Check inherited properties first
      expect(
        resolved!.urlStyle?.fontSize,
        capturedDefaultStyle!.fontSize, // Compare against the captured default size
        reason: "URL style font size should match the DefaultTextStyle font size",
      );
      expect(
        resolved!.urlStyle?.fontFamily,
        capturedDefaultStyle!.fontFamily,
        reason: "URL style font family should match the DefaultTextStyle font family",
      );
      // Check properties overridden by theme link style
      expect(
        resolved!.urlStyle?.color,
        theme.colorScheme.primary,
        reason: "URL style color should be theme primary color",
      );
      expect(
        resolved!.urlStyle?.decoration,
        TextDecoration.underline,
        reason: "URL style decoration should be underline",
      );
      expect(
        resolved!.urlStyle?.decorationColor,
        theme.colorScheme.primary,
        reason: "URL style decoration color should be theme primary color",
      );

      // --- Check other styles (ensure they also use the correct base) ---
      expect(
        resolved!.boldStyle?.fontSize,
        capturedDefaultStyle!.fontSize,
        reason: "Bold style font size should match default",
      );
      expect(resolved!.boldStyle?.fontWeight, DefaultStyles.boldStyle(capturedDefaultStyle!).fontWeight);

      expect(
        resolved!.italicStyle?.fontSize,
        capturedDefaultStyle!.fontSize,
        reason: "Italic style font size should match default",
      );
      expect(resolved!.italicStyle?.fontStyle, DefaultStyles.italicStyle(capturedDefaultStyle!).fontStyle);

      // Code Style: Check against theme defaults merged with base
      expect(
        resolved!.codeStyle?.fontSize,
        capturedDefaultStyle!.fontSize,
        reason: "Code style font size should match default",
      );
      expect(resolved!.codeStyle?.fontFamily, 'monospace');
      expect(resolved!.codeStyle?.color, theme.colorScheme.onSurfaceVariant);
      expect(resolved!.codeStyle?.backgroundColor, theme.colorScheme.surfaceContainer);

      // --- Check non-style properties ---
      expect(resolved!.urlMouseCursor, DefaultStyles.urlMouseCursor);
      expect(resolved!.onUrlTap, isNull);
      expect(resolved!.onUrlHover, isNull);
    });

    testWidgets('Uses values from single ancestor', (tester) async {
      ResolvedOptions? resolved;
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            boldStyle: rootBoldStyle,
            urlStyle: rootUrlStyle, // blue, no decoration
            urlMouseCursor: rootCursor,
            onUrlTap: rootOnTap,
            // italicStyle left null
            child: Builder(
              builder: (context) {
                resolved = ResolvedOptions.fromContext(context, baseStyle);
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
      expect(resolved!.urlStyle?.color, rootUrlStyle.color); // Should be root blue
      expect(resolved!.urlStyle?.decoration, rootUrlStyle.decoration); // none from root
      expect(resolved!.urlStyle?.fontSize, baseStyle.fontSize); // Merged from base
      expect(resolved!.urlMouseCursor, rootCursor);
      expect(resolved!.onUrlTap, same(rootOnTap));
      // Check unspecified (falls back to default effect on base)
      expect(resolved!.italicStyle?.fontStyle, DefaultStyles.italicStyle(baseStyle).fontStyle); // Default italic
      expect(resolved!.italicStyle?.color, baseStyle.color); // Base color
      // Check unspecified callback
      expect(resolved!.onUrlHover, isNull);
    });

    testWidgets('Nested options override ancestor values', (tester) async {
      ResolvedOptions? resolved;
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            // Root
            urlStyle: rootUrlStyle, // blue, no decoration
            onUrlTap: rootOnTap,
            italicStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.purple), // purple italic
            child: TextfOptions(
              // Child override
              urlStyle: childUrlStyle, // green, size 18 (no decoration specified)
              onUrlTap: childOnTap, // dummyTap2
              // Italic style NOT specified here
              child: Builder(
                builder: (context) {
                  resolved = ResolvedOptions.fromContext(context, baseStyle); // black, size 16
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
      // Check overridden values (come from child, merged with base)
      expect(resolved!.urlStyle?.color, childUrlStyle.color); // green from child
      expect(resolved!.urlStyle?.fontSize, childUrlStyle.fontSize); // 18 from child
      expect(
        resolved!.urlStyle?.decoration,
        isNull, // Expect no decoration
        reason: "Decoration should be null as child option didn't specify it",
      );
      expect(resolved!.onUrlTap, same(childOnTap)); // dummyTap2 from child

      // Check non-overridden value (comes from root)
      expect(resolved!.italicStyle?.fontStyle, FontStyle.italic); // from root
      expect(resolved!.italicStyle?.color, Colors.purple); // from root
      expect(resolved!.italicStyle?.fontSize, baseStyle.fontSize); // from base
    });

    testWidgets('Nested options inherit unspecified values from ancestor', (tester) async {
      ResolvedOptions? resolved;
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            // Root (provides bold, tap, rootUrl)
            boldStyle: rootBoldStyle, // w900, red
            onUrlTap: rootOnTap,
            urlStyle: rootUrlStyle, // blue, no decoration
            child: TextfOptions(
              // Child (provides childUrl, italic, hover)
              urlStyle: childUrlStyle, // green, 18 (no decoration)
              italicStyle: childItalicStyle, // normal, yellow bg
              onUrlHover: dummyHover2,
              // boldStyle is null here
              // onUrlTap is null here
              child: Builder(
                builder: (context) {
                  resolved = ResolvedOptions.fromContext(context, baseStyle); // black, 16
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
      // Value specified only in Child
      expect(resolved!.italicStyle?.fontStyle, childItalicStyle.fontStyle); // normal
      expect(resolved!.italicStyle?.backgroundColor, childItalicStyle.backgroundColor); // yellow bg
      expect(resolved!.italicStyle?.fontSize, baseStyle.fontSize); // base size
      expect(resolved!.onUrlHover, same(dummyHover2));

      // Value specified in Child (overriding Root for url)
      expect(resolved!.urlStyle?.color, childUrlStyle.color); // green
      expect(resolved!.urlStyle?.fontSize, childUrlStyle.fontSize); // 18
      expect(
        resolved!.urlStyle?.decoration,
        isNull, // Expect no decoration
        reason: "Decoration should be null as child option didn't specify it",
      );

      // Value NOT specified in Child (inherited from Root)
      expect(resolved!.boldStyle?.fontWeight, rootBoldStyle.fontWeight); // w900
      expect(resolved!.boldStyle?.color, rootBoldStyle.color); // red
      expect(resolved!.boldStyle?.fontSize, baseStyle.fontSize); // base size
      expect(resolved!.onUrlTap, same(rootOnTap));
    });

    testWidgets('Inheritance works across multiple levels', (tester) async {
      ResolvedOptions? resolved;
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            // Level 1 (Root: bold, tap)
            boldStyle: rootBoldStyle, // w900, red
            onUrlTap: rootOnTap,
            child: TextfOptions(
              // Level 2 (Mid: italic)
              italicStyle: childItalicStyle, // normal, yellow bg
              child: TextfOptions(
                // Level 3 (Leaf: url, hover)
                urlStyle: childUrlStyle, // green, 18
                onUrlHover: dummyHover2,
                // codeStyle not specified anywhere
                child: Builder(
                  builder: (context) {
                    resolved = ResolvedOptions.fromContext(context, baseStyle); // black, 16
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
      expect(resolved!.urlStyle?.color, childUrlStyle.color); // green
      expect(resolved!.urlStyle?.fontSize, childUrlStyle.fontSize); // 18
      expect(resolved!.onUrlHover, same(dummyHover2));
      // Comes from Mid (Level 2)
      expect(resolved!.italicStyle?.backgroundColor, childItalicStyle.backgroundColor); // yellow bg
      expect(resolved!.italicStyle?.fontStyle, childItalicStyle.fontStyle); // normal
      // Comes from Root (Level 1)
      expect(resolved!.boldStyle?.fontWeight, rootBoldStyle.fontWeight); // w900
      expect(resolved!.boldStyle?.color, rootBoldStyle.color); // red
      expect(resolved!.onUrlTap, same(rootOnTap));
      // Comes from Default (Not specified anywhere) - Check Code style default
      expect(
        resolved!.codeStyle?.fontFamily,
        'monospace', // Expect default monospace
        reason: "Code style fallback should use monospace font",
      );
      expect(resolved!.codeStyle?.color, theme.colorScheme.onSurfaceVariant); // Theme color
      expect(resolved!.urlMouseCursor, DefaultStyles.urlMouseCursor); // Default cursor
    });

    testWidgets('Correctly merges styles with baseStyle', (tester) async {
      ResolvedOptions? resolved;
      final theme = ThemeData.light();
      // Use a distinct base style
      const specificBaseStyle = TextStyle(fontSize: 10, fontFamily: 'Arial', color: Colors.grey);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red), // Override weight and color
            italicStyle: const TextStyle(fontStyle: FontStyle.italic), // Only specify italic effect
            urlStyle: const TextStyle(
              // Specify only decoration properties
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.orange,
            ),
            child: Builder(
              builder: (context) {
                resolved = ResolvedOptions.fromContext(context, specificBaseStyle); // grey, 10, Arial
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

      // URL: Should have base props + override props. Color comes from base as option didn't specify it.
      expect(resolved!.urlStyle?.decoration, TextDecoration.lineThrough); // from override
      expect(resolved!.urlStyle?.decorationColor, Colors.orange); // from override
      expect(
        resolved!.urlStyle?.color,
        specificBaseStyle.color, // Should be grey from base
        reason: "URL color should be from baseStyle as option didn't specify it",
      );
      expect(resolved!.urlStyle?.fontSize, specificBaseStyle.fontSize); // from base
      expect(resolved!.urlStyle?.fontFamily, specificBaseStyle.fontFamily); // from base
    });
  });
}
