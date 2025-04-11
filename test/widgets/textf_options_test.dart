import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart'; // Adjust path
import 'package:textf/src/widgets/textf_options.dart'; // Adjust path

// ----- Helper Class and Callbacks (Keep as before) -----
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
  factory ResolvedOptions.fromContext(
      BuildContext context, TextStyle baseStyle) {
    final TextfOptions? nearestOptions = TextfOptions.maybeOf(context);

    if (nearestOptions == null) {
      // ---- CASE 1: No TextfOptions ancestor ----
      // Resolve using DefaultStyles directly, applying the correct precedence

      // Start with base style properties (size, family, etc.)
      TextStyle calculatedUrlStyle = baseStyle;
      // Merge the default URL appearance (color, decoration) ON TOP of the base.
      // This ensures default link color/deco override base color/deco.
      calculatedUrlStyle = calculatedUrlStyle.merge(DefaultStyles.urlStyle);

      // Start with the calculated normal URL style.
      TextStyle calculatedUrlHoverStyle = calculatedUrlStyle;
      // Merge the default HOVER effect ON TOP.
      calculatedUrlHoverStyle =
          calculatedUrlHoverStyle.merge(DefaultStyles.urlHoverStyle);

      return ResolvedOptions(
        // Use the correctly calculated styles
        urlStyle: calculatedUrlStyle,
        urlHoverStyle: calculatedUrlHoverStyle,
        urlMouseCursor: DefaultStyles.urlMouseCursor,
        // Other styles are calculated by applying the default *effect* to the base style
        boldStyle: DefaultStyles.boldStyle(baseStyle),
        italicStyle: DefaultStyles.italicStyle(baseStyle),
        boldItalicStyle: DefaultStyles.boldItalicStyle(baseStyle),
        strikethroughStyle: DefaultStyles.strikethroughStyle(baseStyle),
        codeStyle: DefaultStyles.codeStyle(baseStyle),
        onUrlTap: null,
        onUrlHover: null,
      );
    } else {
      // ---- CASE 2: Found a TextfOptions ancestor ----
      // LET THE NEAREST OPTIONS' GETTERS HANDLE THE INHERITANCE LOGIC.
      // This part should now be correct because the getters in TextfOptions were fixed.
      return ResolvedOptions(
        urlStyle: nearestOptions.getEffectiveUrlStyle(context, baseStyle),
        urlHoverStyle:
            nearestOptions.getEffectiveUrlHoverStyle(context, baseStyle),
        urlMouseCursor: nearestOptions.getEffectiveUrlMouseCursor(context),
        boldStyle: nearestOptions.getEffectiveBoldStyle(context, baseStyle),
        italicStyle: nearestOptions.getEffectiveItalicStyle(context, baseStyle),
        boldItalicStyle:
            nearestOptions.getEffectiveBoldItalicStyle(context, baseStyle),
        strikethroughStyle:
            nearestOptions.getEffectiveStrikethroughStyle(context, baseStyle),
        codeStyle: nearestOptions.getEffectiveCodeStyle(context, baseStyle),
        onUrlTap: nearestOptions.getEffectiveOnUrlTap(context),
        onUrlHover: nearestOptions.getEffectiveOnUrlHover(context),
      );
    }
  }
}

void dummyTap1(String u, String d) {}
void dummyTap2(String u, String d) {}
void dummyHover1(String u, String d, bool h) {}
void dummyHover2(String u, String d, bool h) {}
// ----------------------------------------------------------

void main() {
  // --- Test Styles & Callbacks (Keep as before) ---
  const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
  const rootBoldStyle =
      TextStyle(fontWeight: FontWeight.w900, color: Colors.red);
  const rootUrlStyle = TextStyle(
      color: Colors.blue, decoration: TextDecoration.none); // Default blue
  const rootCursor = SystemMouseCursors.text;
  final rootOnTap = dummyTap1;
  final rootOnHover = dummyHover1;

  const childUrlStyle = TextStyle(
      color: Colors.green, fontSize: 18); // Overrides color, adds size
  const childItalicStyle = TextStyle(
      fontStyle: FontStyle.normal,
      backgroundColor: Colors.yellow); // Override italic!
  const childCursor = SystemMouseCursors.click; // Override cursor
  final childOnTap = dummyTap2; // Override tap
  // ----------------------------------------------------

  group('TextfOptions Inheritance Tests', () {
    testWidgets('Falls back to defaults when no TextfOptions is present',
        (tester) async {
      ResolvedOptions? resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = ResolvedOptions.fromContext(context, baseStyle);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved, isNotNull);
      // Verify resolved options match defaults merged with baseStyle
      expect(resolved!.boldStyle?.fontWeight,
          DefaultStyles.boldStyle(baseStyle).fontWeight);
      expect(resolved!.italicStyle?.fontStyle,
          DefaultStyles.italicStyle(baseStyle).fontStyle);
      // URL Style: Check final merged properties
      expect(resolved!.urlStyle?.color,
          DefaultStyles.urlStyle.color); // Should be default blue
      expect(resolved!.urlStyle?.decoration,
          DefaultStyles.urlStyle.decoration); // Should have underline
      expect(resolved!.urlStyle?.fontSize,
          baseStyle.fontSize); // Should have base font size
      expect(resolved!.urlMouseCursor, DefaultStyles.urlMouseCursor);
      expect(resolved!.onUrlTap, isNull);
      expect(resolved!.onUrlHover, isNull);
    });

    testWidgets('Uses values from single ancestor', (tester) async {
      ResolvedOptions? resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: rootBoldStyle,
            urlStyle: rootUrlStyle, // Default blue, no decoration
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
      expect(resolved!.boldStyle?.fontSize, baseStyle.fontSize);
      expect(
          resolved!.urlStyle?.color, rootUrlStyle.color); // Should be root blue
      expect(resolved!.urlStyle?.decoration, rootUrlStyle.decoration);
      expect(resolved!.urlStyle?.fontSize, baseStyle.fontSize);
      expect(resolved!.urlMouseCursor, rootCursor);
      expect(resolved!.onUrlTap, same(rootOnTap));
      // Check unspecified (falls back to default effect on base)
      expect(resolved!.italicStyle?.fontStyle,
          DefaultStyles.italicStyle(baseStyle).fontStyle);
      expect(resolved!.italicStyle?.color, baseStyle.color);
      // Check unspecified callback
      expect(resolved!.onUrlHover, isNull);
    });

    testWidgets('Nested options override ancestor values', (tester) async {
      ResolvedOptions? resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            // Root
            urlStyle: rootUrlStyle, // blue, no decoration
            onUrlTap: rootOnTap,
            italicStyle: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.purple), // purple italic
            child: TextfOptions(
              // Child override
              urlStyle: childUrlStyle, // green, size 18
              onUrlTap: childOnTap, // dummyTap2
              // Italic style NOT specified here
              child: Builder(
                builder: (context) {
                  resolved = ResolvedOptions.fromContext(
                      context, baseStyle); // black, size 16
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
      // Check overridden values (come from child, merged with base, merged with default for missing props)
      expect(
          resolved!.urlStyle?.color, childUrlStyle.color); // green from child
      expect(resolved!.urlStyle?.fontSize,
          childUrlStyle.fontSize); // 18 from child
      expect(
          resolved!.urlStyle?.decoration,
          DefaultStyles.urlStyle
              .decoration); // default underline (neither root nor child specified it)
      expect(resolved!.onUrlTap, same(childOnTap)); // dummyTap2 from child

      // Check non-overridden value (comes from root)
      expect(resolved!.italicStyle?.fontStyle, FontStyle.italic); // from root
      expect(resolved!.italicStyle?.color, Colors.purple); // from root
      expect(resolved!.italicStyle?.fontSize, baseStyle.fontSize); // from base
    });

    testWidgets('Nested options inherit unspecified values from ancestor',
        (tester) async {
      // Identical to the previous test case with the same name, should pass now
      ResolvedOptions? resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            // Root (provides bold, tap, rootUrl)
            boldStyle: rootBoldStyle, // w900, red
            onUrlTap: rootOnTap,
            urlStyle: rootUrlStyle, // blue, no decoration
            child: TextfOptions(
              // Child (provides childUrl, italic, hover)
              urlStyle: childUrlStyle, // green, 18
              italicStyle: childItalicStyle, // normal, yellow bg
              onUrlHover: dummyHover2,
              // boldStyle is null here
              // onUrlTap is null here
              child: Builder(
                builder: (context) {
                  resolved = ResolvedOptions.fromContext(
                      context, baseStyle); // black, 16
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
      // Value specified only in Child
      expect(resolved!.italicStyle?.fontStyle,
          childItalicStyle.fontStyle); // normal
      expect(resolved!.italicStyle?.backgroundColor,
          childItalicStyle.backgroundColor); // yellow bg
      expect(resolved!.italicStyle?.fontSize, baseStyle.fontSize); // base size
      expect(resolved!.onUrlHover, same(dummyHover2));

      // Value specified in Child (overriding Root for url)
      expect(resolved!.urlStyle?.color, childUrlStyle.color); // green
      expect(resolved!.urlStyle?.fontSize, childUrlStyle.fontSize); // 18
      expect(resolved!.urlStyle?.decoration,
          DefaultStyles.urlStyle.decoration); // default underline

      // Value NOT specified in Child (inherited from Root)
      expect(resolved!.boldStyle?.fontWeight, rootBoldStyle.fontWeight); // w900
      expect(resolved!.boldStyle?.color, rootBoldStyle.color); // red
      expect(resolved!.boldStyle?.fontSize, baseStyle.fontSize); // base size
      expect(resolved!.onUrlTap, same(rootOnTap));
    });

    testWidgets('Inheritance works across multiple levels', (tester) async {
      // Identical to the previous test case with the same name, should pass now
      ResolvedOptions? resolved;
      await tester.pumpWidget(
        MaterialApp(
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
                child: Builder(
                  builder: (context) {
                    resolved = ResolvedOptions.fromContext(
                        context, baseStyle); // black, 16
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
      expect(resolved!.italicStyle?.backgroundColor,
          childItalicStyle.backgroundColor); // yellow bg
      expect(resolved!.italicStyle?.fontStyle,
          childItalicStyle.fontStyle); // normal
      // Comes from Root (Level 1)
      expect(resolved!.boldStyle?.fontWeight, rootBoldStyle.fontWeight); // w900
      expect(resolved!.boldStyle?.color, rootBoldStyle.color); // red
      expect(resolved!.onUrlTap, same(rootOnTap));
      // Comes from Default (Not specified anywhere)
      expect(resolved!.codeStyle?.fontFamily,
          DefaultStyles.codeStyle(baseStyle).fontFamily);
      expect(resolved!.urlMouseCursor, DefaultStyles.urlMouseCursor);
    });

    testWidgets('Correctly merges styles with baseStyle', (tester) async {
      // Identical to the previous test case with the same name, should pass now
      ResolvedOptions? resolved;
      const specificBaseStyle =
          TextStyle(fontSize: 10, fontFamily: 'Arial', color: Colors.grey);

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red), // Override weight and color
            italicStyle: const TextStyle(
                fontStyle: FontStyle.italic), // Only specify italic effect
            urlStyle: const TextStyle(
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.orange), // Override decoration+color
            child: Builder(
              builder: (context) {
                resolved = ResolvedOptions.fromContext(
                    context, specificBaseStyle); // grey, 10, Arial
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
      expect(resolved!.boldStyle?.fontSize,
          specificBaseStyle.fontSize); // from base
      expect(resolved!.boldStyle?.fontFamily,
          specificBaseStyle.fontFamily); // from base

      // Italic: Should have specific base props + default italic effect
      expect(
          resolved!.italicStyle?.fontStyle, FontStyle.italic); // from override
      expect(
          resolved!.italicStyle?.color, specificBaseStyle.color); // from base
      expect(resolved!.italicStyle?.fontSize,
          specificBaseStyle.fontSize); // from base

      // URL: Should have base props + override props + default color (as override didn't specify color)
      expect(resolved!.urlStyle?.decoration,
          TextDecoration.lineThrough); // from override
      expect(
          resolved!.urlStyle?.decorationColor, Colors.orange); // from override
      expect(
          resolved!.urlStyle?.color,
          DefaultStyles
              .urlStyle.color); // default blue (override didn't specify)
      expect(resolved!.urlStyle?.fontSize,
          specificBaseStyle.fontSize); // from base
    });
  });
}
