// ignore_for_file: avoid-late-keyword, no-magic-number

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/src/widgets/textf_options.dart';

import '../widgets/pump_textf_widget.dart';

void main() {
  group('Link Parsing Tests', () {
    late TextfParser parser;
    late BuildContext mockContext;

    setUp(() {
      parser = TextfParser();
      // We'll set mockContext in the test widget
    });

    // Helper to create a test BuildContext
    Widget buildTestWidget(
      WidgetTester tester,
      Widget Function(BuildContext) builder,
    ) {
      return MaterialApp(
        home: Builder(
          builder: (context) {
            mockContext = context;
            return builder(context);
          },
        ),
      );
    }

    group('Basic Link Parsing', () {
      testWidgets('simple link without formatting', (tester) async {
        late BuildContext mockContext; // Capture context
        final lightTheme = ThemeData.light(); // Use a specific theme

        // Setup context with the light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                mockContext = context;
                return Container();
              },
            ),
          ),
        );
        const baseStyle = TextStyle();
        final parser = TextfParser();

        // Parse
        final spans = parser.parse(
          'Visit [Flutter website](https://flutter.dev)',
          mockContext,
          baseStyle,
        );

        // Verify overall structure (remains the same)
        expect(spans.length, 2);
        expect(spans.first, isA<TextSpan>());
        expect((spans.first as TextSpan).text, 'Visit ');
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;
        // --- Verify properties on the HoverableLinkSpan ---
        expect(hoverableWidget.url, 'https://flutter.dev');
        expect(
          hoverableWidget.rawDisplayText,
          'Flutter website',
          reason: 'Raw display text should be stored',
        );

        // For simple text without internal formatting, initialPlainText should be set,
        // and initialChildrenSpans should be empty.
        expect(hoverableWidget.initialPlainText, 'Flutter website');
        expect(hoverableWidget.initialChildrenSpans, isEmpty);

        // --- Verify the style passed to HoverableLinkSpan ---
        // The 'normalStyle' should now reflect the theme's primary color.
        // Calculate expected style by merging base with theme default link style
        final expectedNormalStyle = baseStyle.merge(
          TextStyle(
            color: lightTheme.colorScheme.primary, // Expect theme primary color
            decoration: TextDecoration.underline,
            decorationColor: lightTheme.colorScheme.primary,
          ),
        );

        expect(
          hoverableWidget.normalStyle.color,
          // Expect theme primary color instead of old hardcoded blue
          lightTheme.colorScheme.primary,
          reason: 'Normal style color should match theme primary color', // Updated reason
        );
        expect(
          hoverableWidget.normalStyle.decoration,
          TextDecoration.underline, // Default decoration still expected
          reason: 'Normal style decoration should be underline',
        );
        expect(
          hoverableWidget.normalStyle.decorationColor,
          // Expect theme primary color for decoration
          lightTheme.colorScheme.primary,
          reason:
              'Normal style decoration color should match theme primary color', // Updated reason
        );

        // Hover style check (assuming default hover = normal style when no options)
        final expectedHoverStyle = expectedNormalStyle; // In theme fallback, hover == normal
        expect(
          hoverableWidget.hoverStyle.color,
          expectedHoverStyle.color,
          reason: 'Hover style color should match normal theme style',
        );
        expect(
          hoverableWidget.hoverStyle.decorationColor,
          expectedHoverStyle.decorationColor,
          reason: 'Hover style decoration color should match normal theme style',
        );

        // --- Verify other interaction properties (optional but good) ---
        expect(hoverableWidget.mouseCursor, DefaultStyles.linkMouseCursor);
        // Check recognizer existence if tap callback is expected (add TextfOptions for that)
        // expect(hoverableWidget.tapRecognizer, isNotNull);
      });

      testWidgets('link with URL normalization', (tester) async {
        // Setup context
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();

        // Parse
        final spans = parser.parse(
          'Visit [Google](google.com)', // Input text with non-normalized URL
          mockContext,
          baseStyle,
        );

        // Verify overall structure
        expect(spans.length, 2, reason: "Should have 2 spans: 'Visit ' and the link");
        expect(spans.first, isA<TextSpan>());
        expect((spans.first as TextSpan).text, 'Visit ');

        // --- Verify the WidgetSpan for the link ---
        expect(spans[1], isA<WidgetSpan>(), reason: 'Link span should be a WidgetSpan');
        final widgetSpan = spans[1] as WidgetSpan;

        // --- Verify the child widget inside the WidgetSpan ---
        expect(
          widgetSpan.child,
          isA<HoverableLinkSpan>(),
          reason: 'WidgetSpan should contain HoverableLinkSpan',
        );
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // --- Check URL normalization on the HoverableLinkSpan ---
        // This is the core assertion for this test case.
        expect(
          hoverableWidget.url,
          'http://google.com',
          reason: 'URL should be normalized with http:// prefix',
        );

        // --- Also check other properties (optional but good practice) ---
        expect(hoverableWidget.rawDisplayText, 'Google'); // The original text between []
        expect(
          hoverableWidget.initialPlainText,
          'Google',
        ); // The plain text content (no internal format)
        expect(hoverableWidget.initialChildrenSpans, isEmpty); // No nested formatting
      });

      testWidgets('multiple links in text', (tester) async {
        // Setup context
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();

        // Parse
        final spans = parser.parse(
          'Visit [Flutter](https://flutter.dev) or [Dart](https://dart.dev)',
          mockContext,
          baseStyle,
        );

        // Expect 4 spans: "Visit ", first link (WidgetSpan), " or ", second link (WidgetSpan)
        expect(spans.length, 4, reason: 'Should have 4 spans total');

        // --- Check text spans  ---
        expect(spans.first, isA<TextSpan>());
        expect((spans.first as TextSpan).text, 'Visit ');
        expect(spans[2], isA<TextSpan>());
        expect((spans[2] as TextSpan).text, ' or ');

        // --- Check first link span (spans[1]) ---
        expect(spans[1], isA<WidgetSpan>(), reason: 'First link should be a WidgetSpan');
        final widgetSpan1 = spans[1] as WidgetSpan;
        expect(
          widgetSpan1.child,
          isA<HoverableLinkSpan>(),
          reason: 'WidgetSpan 1 should contain HoverableLinkSpan',
        );
        final hoverableWidget1 = widgetSpan1.child as HoverableLinkSpan;

        // Verify properties of the first HoverableLinkSpan
        expect(hoverableWidget1.url, 'https://flutter.dev');
        expect(hoverableWidget1.rawDisplayText, 'Flutter');
        expect(hoverableWidget1.initialPlainText, 'Flutter'); // Since no internal formatting
        expect(hoverableWidget1.initialChildrenSpans, isEmpty);

        // --- Check second link span (spans[3]) ---
        expect(spans[3], isA<WidgetSpan>(), reason: 'Second link should be a WidgetSpan');
        final widgetSpan2 = spans[3] as WidgetSpan;
        expect(
          widgetSpan2.child,
          isA<HoverableLinkSpan>(),
          reason: 'WidgetSpan 2 should contain HoverableLinkSpan',
        );
        final hoverableWidget2 = widgetSpan2.child as HoverableLinkSpan;

        // Verify properties of the second HoverableLinkSpan
        expect(hoverableWidget2.url, 'https://dart.dev');
        expect(hoverableWidget2.rawDisplayText, 'Dart');
        expect(hoverableWidget2.initialPlainText, 'Dart'); // Since no internal formatting
        expect(hoverableWidget2.initialChildrenSpans, isEmpty);
      });
    });

    group('Formatted Link Text', () {
      testWidgets('bold text in link', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [**Bold Link**](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans.first, isA<TextSpan>()); // "Visit "
        expect(spans[1], isA<WidgetSpan>()); // Link WidgetSpan
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '**Bold Link**');
        expect(
          hoverableWidget.initialPlainText,
          isNull,
          reason: 'Should have children spans, not plain text',
        );
        expect(hoverableWidget.initialChildrenSpans, isNotEmpty);
        expect(
          hoverableWidget.initialChildrenSpans.length,
          1,
          reason: 'Link text itself has one formatted part',
        );

        // --- Verify the *inner* span's style ---
        final innerSpan = hoverableWidget.initialChildrenSpans.first;
        expect(innerSpan, isA<TextSpan>());
        final innerTextSpan = innerSpan as TextSpan;

        // Check formatting applied *within* the link text
        expect(innerTextSpan.text, 'Bold Link');
        expect(
          innerTextSpan.style?.fontWeight,
          FontWeight.bold,
          reason: 'Inner span should be bold',
        );

        // Check that the inner span *also* inherits the link's base style
        // (which comes from hoverableWidget.normalStyle)
        expect(
          innerTextSpan.style?.color,
          hoverableWidget.normalStyle.color,
          reason: 'Inner span should inherit link color',
        );
        expect(
          innerTextSpan.style?.decoration,
          hoverableWidget.normalStyle.decoration,
          reason: 'Inner span should inherit link decoration',
        );
      });

      testWidgets('italic text in link', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [*Italic Link*](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '*Italic Link*');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(hoverableWidget.initialChildrenSpans.length, 1);

        // Verify the inner span's style
        final innerSpan = hoverableWidget.initialChildrenSpans.first as TextSpan;
        expect(innerSpan.text, 'Italic Link');
        expect(innerSpan.style?.fontStyle, FontStyle.italic, reason: 'Inner span should be italic');

        // Verify inheritance of base link style
        expect(innerSpan.style?.color, hoverableWidget.normalStyle.color);
        expect(innerSpan.style?.decoration, hoverableWidget.normalStyle.decoration);
      });

      testWidgets('strikethrough text in link', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [~~Strikethrough Link~~](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '~~Strikethrough Link~~');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(hoverableWidget.initialChildrenSpans.length, 1);

        // Verify the inner span's style
        final innerSpan = hoverableWidget.initialChildrenSpans.first as TextSpan;
        expect(innerSpan.text, 'Strikethrough Link');
        expect(
          innerSpan.style?.decoration,
          TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]),
          reason: "Inner span should combine link's underline with strikethrough",
        ); // Check decoration color is inherited from base link style's color
        expect(innerSpan.style?.decorationColor, hoverableWidget.normalStyle.color);

        // Verify inheritance of base link style color
        expect(innerSpan.style?.color, hoverableWidget.normalStyle.color);
      });

      testWidgets('code text in link', (tester) async {
        late BuildContext mockContext;
        final lightTheme = ThemeData.light();

        // Setup context
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                mockContext = context;
                return Container();
              },
            ),
          ),
        );
        const baseStyle = TextStyle();
        final parser = TextfParser();
        const text = 'Visit [`Code Link`](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '`Code Link`');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(hoverableWidget.initialChildrenSpans.length, 1);

        // Verify the inner span's style
        final innerSpan = hoverableWidget.initialChildrenSpans.first as TextSpan;

        // Calculate expected code style merged with the *link's normal style*
        // The link's normal style gets the theme primary color.
        final linkNormalStyle = baseStyle.merge(TextStyle(color: lightTheme.colorScheme.primary));
        final expectedInnerCodeStyle = linkNormalStyle.copyWith(
          // Apply code style onto link style
          fontFamily: 'monospace',
          fontFamilyFallback: ['RobotoMono', 'Menlo', 'Courier New'],
          // Expect theme background color
          backgroundColor: lightTheme.colorScheme.surfaceContainer,
          // Code text color should come from theme, overriding link color
          color: lightTheme.colorScheme.onSurfaceVariant,
          letterSpacing: 0,
        );

        expect(innerSpan.text, 'Code Link');
        expect(
          innerSpan.style?.fontFamily,
          expectedInnerCodeStyle.fontFamily,
          reason: 'Inner span should have monospace font',
        );
        expect(
          innerSpan.style?.backgroundColor,
          // Expect theme surfaceContainer color
          lightTheme.colorScheme.surfaceContainer,
          reason: 'Inner span should have theme code background',
        );
        expect(
          innerSpan.style?.color,
          // Expect theme code text color
          lightTheme.colorScheme.onSurfaceVariant,
          reason: 'Inner span should have theme code text color',
        );
      });
    });

    group('Mixed Formatting in Link Text', () {
      testWidgets('multiple formatting styles in link', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [**Bold** and *italic* text](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '**Bold** and *italic* text');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(
          hoverableWidget.initialChildrenSpans.length,
          4,
          reason: "Expected 4 inner spans: bold, ' and ', italic, ' text'",
        );

        // --- Verify the *inner* spans ---
        final innerSpans = hoverableWidget.initialChildrenSpans;

        // Child 0: Bold
        final boldSpan = innerSpans.first as TextSpan;
        expect(boldSpan.text, 'Bold');
        expect(boldSpan.style?.fontWeight, FontWeight.bold);
        expect(boldSpan.style?.color, hoverableWidget.normalStyle.color); // Inherited link color

        // Child 1: Plain
        final plainSpan1 = innerSpans[1] as TextSpan;
        expect(plainSpan1.text, ' and ');
        expect(plainSpan1.style?.fontWeight, isNot(FontWeight.bold)); // Not bold
        expect(plainSpan1.style?.fontStyle, isNot(FontStyle.italic)); // Not italic
        expect(plainSpan1.style?.color, hoverableWidget.normalStyle.color); // Inherited link color

        // Child 2: Italic
        final italicSpan = innerSpans[2] as TextSpan;
        expect(italicSpan.text, 'italic');
        expect(italicSpan.style?.fontStyle, FontStyle.italic);
        expect(italicSpan.style?.color, hoverableWidget.normalStyle.color); // Inherited link color

        // Child 3: Plain
        final plainSpan2 = innerSpans[3] as TextSpan;
        expect(plainSpan2.text, ' text');
        expect(plainSpan2.style?.fontWeight, isNot(FontWeight.bold));
        expect(plainSpan2.style?.fontStyle, isNot(FontStyle.italic));
        expect(plainSpan2.style?.color, hoverableWidget.normalStyle.color); // Inherited link color
      });

      testWidgets('nested formatting in link text', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [**Bold _and italic_**](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '**Bold _and italic_**');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(
          hoverableWidget.initialChildrenSpans.length,
          2,
          reason: "Expected 2 inner spans: 'Bold ', 'and italic'",
        );

        // --- Verify the *inner* spans ---
        final innerSpans = hoverableWidget.initialChildrenSpans;

        // Child 0: Bold only
        final boldSpan = innerSpans.first as TextSpan;
        expect(boldSpan.text, 'Bold ');
        expect(boldSpan.style?.fontWeight, FontWeight.bold);
        expect(boldSpan.style?.fontStyle, isNot(FontStyle.italic)); // Not italic
        expect(boldSpan.style?.color, hoverableWidget.normalStyle.color); // Inherited link color

        // Child 1: Bold and Italic
        final boldItalicSpan = innerSpans[1] as TextSpan;
        expect(boldItalicSpan.text, 'and italic');
        expect(boldItalicSpan.style?.fontWeight, FontWeight.bold); // Bold
        expect(boldItalicSpan.style?.fontStyle, FontStyle.italic); // Italic
        expect(
          boldItalicSpan.style?.color,
          hoverableWidget.normalStyle.color,
        ); // Inherited link color
      });
    });

    group('Style Inheritance', () {
      testWidgets('link style is properly applied to formatted text from TextfOptions',
          (tester) async {
        // Define styles and options
        const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
        const optionsLinkStyle =
            TextStyle(color: Colors.red, fontSize: 18, decoration: TextDecoration.none);
        const optionsBoldStyle = TextStyle(
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.underline,
        ); // Add another prop to bold

        // Setup widget tree with TextfOptions
        late BuildContext testContext;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Provide base style via DefaultTextStyle for context resolution
                return DefaultTextStyle(
                  style: baseStyle,
                  child: TextfOptions(
                    linkStyle: optionsLinkStyle,
                    boldStyle: optionsBoldStyle,
                    child: Builder(
                      builder: (innerContext) {
                        testContext = innerContext; // Capture context with options
                        return Container();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Parse using the captured context
        final spans = parser.parse(
          'Visit [**Bold Link**](https://example.com)',
          testContext,
          baseStyle, // Pass base style explicitly to parser
        );

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify the style passed *to* HoverableLinkSpan (should reflect options)
        // Expected normal style = baseStyle merged with optionsLinkStyle
        expect(
          hoverableWidget.normalStyle.color,
          optionsLinkStyle.color,
          reason: 'Normal link style should have options color',
        );
        expect(
          hoverableWidget.normalStyle.fontSize,
          optionsLinkStyle.fontSize,
          reason: 'Normal link style should have options font size',
        );
        expect(
          hoverableWidget.normalStyle.decoration,
          optionsLinkStyle.decoration,
          reason: 'Normal link style should have options decoration',
        );

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.rawDisplayText, '**Bold Link**');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(hoverableWidget.initialChildrenSpans.length, 1);

        // Verify the *inner* span's style (should inherit final link style + have its own format)
        final innerSpan = hoverableWidget.initialChildrenSpans.first as TextSpan;
        expect(innerSpan.text, 'Bold Link');

        // Check inheritance of the final normal link style
        expect(innerSpan.style?.color, optionsLinkStyle.color); // Inherited from link
        expect(innerSpan.style?.fontSize, optionsLinkStyle.fontSize); // Inherited from link

        // Check applied bold style (from TextfOptions, overriding default bold)
        expect(innerSpan.style?.fontWeight, optionsBoldStyle.fontWeight); // From options bold
        expect(
          innerSpan.style?.decoration,
          optionsBoldStyle.decoration,
        ); // From options bold (overrides link's decoration:none)
      });

      testWidgets('base style is properly inherited by links and nested formats', (tester) async {
        late BuildContext mockContext;
        final lightTheme = ThemeData.light();

        // Setup context
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                mockContext = context;
                return Container();
              },
            ),
          ),
        );
        const baseStyle = TextStyle(
          // Base style is purple
          fontFamily: 'Roboto',
          fontSize: 20,
          height: 1.5,
          color: Colors.purple,
        );
        final parser = TextfParser();

        // Parse with the specific base style
        final spans = parser.parse(
          'Visit [**Bold Link**](https://example.com)',
          mockContext,
          baseStyle,
        );

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify the normal style passed to HoverableLinkSpan (Base + Theme Link)
        expect(hoverableWidget.normalStyle.fontFamily, baseStyle.fontFamily);
        expect(hoverableWidget.normalStyle.fontSize, baseStyle.fontSize);
        expect(hoverableWidget.normalStyle.height, baseStyle.height);
        expect(
          hoverableWidget.normalStyle.color,
          // Expect theme primary color, overriding base purple
          lightTheme.colorScheme.primary,
          reason: 'Theme link color should override base color',
        );
        expect(hoverableWidget.normalStyle.decoration, TextDecoration.underline);

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.rawDisplayText, '**Bold Link**');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(hoverableWidget.initialChildrenSpans.length, 1);
        final innerSpan = hoverableWidget.initialChildrenSpans.first as TextSpan;
        expect(innerSpan.text, 'Bold Link');

        // Check inheritance of final link style properties
        expect(innerSpan.style?.fontFamily, baseStyle.fontFamily);
        expect(innerSpan.style?.fontSize, baseStyle.fontSize);
        expect(innerSpan.style?.height, baseStyle.height);
        expect(
          innerSpan.style?.color,
          // Expect theme primary color
          lightTheme.colorScheme.primary,
          reason: 'Inner span should inherit theme link color',
        );
        expect(innerSpan.style?.decoration, TextDecoration.underline);

        // Check bold formatting was applied
        expect(innerSpan.style?.fontWeight, FontWeight.bold);
      });
    });

    group('Edge Cases', () {
      testWidgets('escaped formatting characters in link text', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = r'Visit [This is \*not formatted\*](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, r'This is \*not formatted\*');

        // Escaped characters should result in plain text treatment
        expect(
          hoverableWidget.initialPlainText,
          'This is *not formatted*',
          reason: 'Escaped text should be in initialPlainText',
        );
        expect(
          hoverableWidget.initialChildrenSpans,
          isEmpty,
          reason: 'Should have no children spans for escaped text',
        );
      });

      testWidgets('Unicode characters in link text', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [**你好世界**](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '**你好世界**');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(hoverableWidget.initialChildrenSpans.length, 1);

        // Verify inner span
        final innerSpan = hoverableWidget.initialChildrenSpans.first as TextSpan;
        expect(innerSpan.text, '你好世界');
        expect(innerSpan.style?.fontWeight, FontWeight.bold);
        expect(innerSpan.style?.color, hoverableWidget.normalStyle.color); // Inherited link color
      });

      testWidgets('empty link text', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties for empty text
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, ''); // Empty raw text
        expect(hoverableWidget.initialPlainText, ''); // Empty plain text
        expect(hoverableWidget.initialChildrenSpans, isEmpty); // No children
      });

      testWidgets('very long link text with formatting', (tester) async {
        // Added 'with formatting'
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        final longText = 'A' * 1000;
        final text = 'Visit [**$longText**](https://example.com)'; // Make it bold

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '**$longText**');
        expect(hoverableWidget.initialPlainText, isNull); // Has children spans
        expect(hoverableWidget.initialChildrenSpans.length, 1);

        // Verify inner span
        final innerSpan = hoverableWidget.initialChildrenSpans.first as TextSpan;
        expect(innerSpan.text, longText); // Contains the long text
        expect(innerSpan.text?.length, 1000);
        expect(innerSpan.style?.fontWeight, FontWeight.bold); // Is bold
        expect(innerSpan.style?.color, hoverableWidget.normalStyle.color); // Inherits link color
      });
    });

    group('Complex Scenarios', () {
      testWidgets('multiple links with different formatting', (tester) async {
        // Setup
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        const text = 'Visit [**Bold**](https://bold.com) or [*Italic*](https://italic.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 4, reason: 'Should have 4 spans total');
        expect(spans.first, isA<TextSpan>(), reason: 'First span is plain text');
        expect(spans[2], isA<TextSpan>(), reason: 'Third span is plain text');

        // --- Verify First Link (Bold) ---
        expect(
          spans[1],
          isA<WidgetSpan>(),
          reason: 'Span at index 1 should be a WidgetSpan for the bold link',
        );
        final widgetSpan1 = spans[1] as WidgetSpan;
        expect(
          widgetSpan1.child,
          isA<HoverableLinkSpan>(),
          reason: 'WidgetSpan 1 should contain a HoverableLinkSpan',
        );
        final hoverableWidget1 = widgetSpan1.child as HoverableLinkSpan;

        // Verify properties of the first HoverableLinkSpan
        expect(hoverableWidget1.url, 'https://bold.com');
        expect(hoverableWidget1.rawDisplayText, '**Bold**');
        expect(
          hoverableWidget1.initialPlainText,
          isNull,
          reason: 'Link text has internal formatting, so plain text should be null',
        );
        // Debug output showed length is 1
        expect(
          hoverableWidget1.initialChildrenSpans.length,
          1,
          reason: "Inner parse returns one direct TextSpan for '**Bold**'",
        );

        // --- ADJUSTMENT: Access the *direct* inner span ---
        // Since children is null, the first element IS the actual formatted span
        final innerSpan1 = hoverableWidget1.initialChildrenSpans.first;
        expect(innerSpan1, isA<TextSpan>(), reason: 'The single child span should be a TextSpan');
        // --- END ADJUSTMENT ---

        // Check style of the actual inner span
        expect((innerSpan1 as TextSpan).text, 'Bold');
        expect(innerSpan1.style?.fontWeight, FontWeight.bold, reason: 'Inner span should be bold');
        expect(
          innerSpan1.style?.color,
          hoverableWidget1.normalStyle.color,
          reason: "Inner span should inherit the link's normal text color",
        );
        // Verify it does NOT have children itself
        expect(
          innerSpan1.children,
          isNull,
          reason: "Directly returned span shouldn't have nested children here",
        );

        // --- Verify Second Link (Italic) ---
        expect(
          spans[3],
          isA<WidgetSpan>(),
          reason: 'Span at index 3 should be a WidgetSpan for the italic link',
        );
        final widgetSpan2 = spans[3] as WidgetSpan;
        expect(
          widgetSpan2.child,
          isA<HoverableLinkSpan>(),
          reason: 'WidgetSpan 2 should contain a HoverableLinkSpan',
        );
        final hoverableWidget2 = widgetSpan2.child as HoverableLinkSpan;

        // Verify properties of the second HoverableLinkSpan
        expect(hoverableWidget2.url, 'https://italic.com');
        expect(hoverableWidget2.rawDisplayText, '*Italic*');
        expect(hoverableWidget2.initialPlainText, isNull);
        // Debug output showed length is 1
        expect(
          hoverableWidget2.initialChildrenSpans.length,
          1,
          reason: "Inner parse returns one direct TextSpan for '*Italic*'",
        );

        // --- ADJUSTMENT: Access the *direct* inner span ---
        final innerSpan2 = hoverableWidget2.initialChildrenSpans.first;
        expect(innerSpan2, isA<TextSpan>(), reason: 'The single child span should be a TextSpan');
        // --- END ADJUSTMENT ---

        // Check style of the actual inner span
        expect((innerSpan2 as TextSpan).text, 'Italic');
        expect(
          innerSpan2.style?.fontStyle,
          FontStyle.italic,
          reason: 'Inner span should be italic',
        );
        expect(
          innerSpan2.style?.color,
          hoverableWidget2.normalStyle.color,
          reason: "Inner span should inherit the link's normal text color",
        );
        // Verify it does NOT have children itself
        expect(
          innerSpan2.children,
          isNull,
          reason: "Directly returned span shouldn't have nested children here",
        );
      });

      testWidgets('links within formatted text', (tester) async {
        late BuildContext mockContext;
        final lightTheme = ThemeData.light();

        // Setup context
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                mockContext = context;
                return Container();
              },
            ),
          ),
        );
        const baseStyle = TextStyle(color: Colors.black); // Base style is black
        final parser = TextfParser();
        const text = '**Bold text with [a link](https://example.com) inside**';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 3);

        // Verify Bold Start
        expect(spans.first, isA<TextSpan>(), reason: 'First span should be bold text');
        final boldStartSpan = spans.first as TextSpan;
        expect(boldStartSpan.text, 'Bold text with ');
        expect(boldStartSpan.style?.fontWeight, FontWeight.bold);
        expect(boldStartSpan.style?.color, baseStyle.color, reason: 'Should inherit base color');

        // Verify Link Span
        expect(spans[1], isA<WidgetSpan>(), reason: 'Second span should be the link WidgetSpan');
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, 'a link');
        // Check plain text handling because inner link text has no formatting
        expect(
          hoverableWidget.initialPlainText,
          'a link',
          reason: 'Link text is plain, should be in initialPlainText',
        );
        expect(
          hoverableWidget.initialChildrenSpans,
          isEmpty,
          reason: 'Plain link text should have no children spans',
        );

        expect(
          hoverableWidget.normalStyle.fontWeight,
          FontWeight.bold, // Inherited bold from surroundings
          reason: "Link's normal style should inherit surrounding bold",
        );
        expect(
          hoverableWidget.normalStyle.color,
          // Expect theme primary color, overriding base/bold color
          lightTheme.colorScheme.primary,
          reason: "Link's normal style should have theme link color (over base/bold color)",
        );
        expect(
          hoverableWidget.normalStyle.decoration,
          TextDecoration.underline, // Default decoration
          reason: "Link's normal style should have default link decoration",
        );
      });

      testWidgets('link text with mixed and nested formatting', (tester) async {
        late BuildContext mockContext;
        final lightTheme = ThemeData.light();

        // Setup context
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                mockContext = context;
                return Container();
              },
            ),
          ),
        );
        const baseStyle = TextStyle();
        final parser = TextfParser();
        const text = 'Visit [**Bold** *Italic* ~~Strike~~ `Code` **_Both_**](https://example.com)';

        // Parse
        final spans = parser.parse(text, mockContext, baseStyle);

        // Verify structure
        expect(spans.length, 2);
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());
        final hoverableWidget = widgetSpan.child as HoverableLinkSpan;

        // Verify HoverableLinkSpan properties
        expect(hoverableWidget.url, 'https://example.com');
        expect(hoverableWidget.rawDisplayText, '**Bold** *Italic* ~~Strike~~ `Code` **_Both_**');
        expect(hoverableWidget.initialPlainText, isNull);
        expect(hoverableWidget.initialChildrenSpans.length, 9);
        final innerSpans = hoverableWidget.initialChildrenSpans;

        // --- Verify *inner* spans ---
        final linkNormalColor = lightTheme.colorScheme.primary; // Use theme color
        expect(innerSpans.first, isA<TextSpan>());
        expect((innerSpans.first as TextSpan).text, 'Bold');
        expect((innerSpans.first as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((innerSpans.first as TextSpan).style?.color, linkNormalColor);

        expect(innerSpans[1], isA<TextSpan>());
        expect((innerSpans[1] as TextSpan).text, ' '); // Space

        expect(innerSpans[2], isA<TextSpan>());
        expect((innerSpans[2] as TextSpan).text, 'Italic');
        expect((innerSpans[2] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((innerSpans[2] as TextSpan).style?.color, linkNormalColor);

        expect(innerSpans[3], isA<TextSpan>());
        expect((innerSpans[3] as TextSpan).text, ' '); // Space

        expect(innerSpans[4], isA<TextSpan>());
        expect((innerSpans[4] as TextSpan).text, 'Strike');
        expect(
          (innerSpans[4] as TextSpan).style?.decoration,
          TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]),
        );
        expect((innerSpans[4] as TextSpan).style?.color, linkNormalColor);

        expect(innerSpans[5], isA<TextSpan>());
        expect((innerSpans[5] as TextSpan).text, ' '); // Space

        // Check Code span (index 6)
        final codeSpan = innerSpans[6] as TextSpan;
        final linkNormalStyle =
            baseStyle.merge(TextStyle(color: linkNormalColor)); // Base style for code inside link
        final expectedInnerCodeStyle = linkNormalStyle.copyWith(
          // Apply code style onto link style
          fontFamily: 'monospace',
          fontFamilyFallback: ['RobotoMono', 'Menlo', 'Courier New'],
          backgroundColor: lightTheme.colorScheme.surfaceContainer, // Expect theme background
          color: lightTheme.colorScheme.onSurfaceVariant, // Expect theme text color
          letterSpacing: 0,
        );

        expect(codeSpan.text, 'Code');
        expect(codeSpan.style?.fontFamily, expectedInnerCodeStyle.fontFamily);
        expect(
          codeSpan.style?.backgroundColor,
          // Expect theme background color
          lightTheme.colorScheme.surfaceContainer,
          reason: 'Code segment inside link should use theme background',
        );
        expect(codeSpan.style?.color, expectedInnerCodeStyle.color);

        expect((innerSpans[8] as TextSpan).text, 'Both');
        expect((innerSpans[8] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((innerSpans[8] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((innerSpans[8] as TextSpan).style?.color, linkNormalColor);
      });
    });

    group('Interaction Behavior', () {
      testWidgets('onLinkTap callback is triggered on tap', (tester) async {
        // --- Setup Callback Tracking ---
        bool tapCalled = false;
        String? tappedUrl;
        String? tappedText;
        const inputText = 'Visit [**Flutter**](https://flutter.dev)';
        const expectedUrl = 'https://flutter.dev';
        const expectedRawText = '**Flutter**'; // TextfOptions callback gets raw text

        // --- Pump Widget with TextfOptions ---
        await pumpTextfWidget(
          tester,
          data: inputText,
          textfOptions: TextfOptions(
            // Provide a dummy child for the constructor if needed, but it's replaced by Textf above
            child: const SizedBox.shrink(),
            onLinkTap: (url, displayText) {
              tapCalled = true;
              tappedUrl = url;
              tappedText = displayText;
            },
          ),
        );

        // --- Find the Interactive Widget ---
        // We need to find the HoverableLinkSpan widget rendered on screen.
        // Since there's only one link, finding by type should be sufficient.
        final linkFinder = find.byType(HoverableLinkSpan);
        expect(linkFinder, findsOneWidget, reason: 'Should find the HoverableLinkSpan widget');

        // --- Simulate Tap ---
        await tester.tap(linkFinder);
        // Allow callbacks to process
        await tester.pumpAndSettle();

        // --- Verify Callback Invocation and Parameters ---
        expect(tapCalled, isTrue, reason: 'onLinkTap callback should have been triggered');
        expect(tappedUrl, expectedUrl, reason: 'Callback should receive the correct URL');
        expect(tappedText, expectedRawText, reason: 'Callback should receive the raw display text');
      });

      testWidgets('onLinkHover callback is triggered on hover', (tester) async {
        // --- Setup Callback Tracking ---
        bool hoverCalled = false;
        bool isHover = false;
        String? hoveredUrl;
        String? hoveredText;
        const inputText = 'Visit [Flutter](https://flutter.dev)';
        const expectedUrl = 'https://flutter.dev';
        const expectedRawText = 'Flutter'; // TextfOptions callback gets raw text

        // --- Pump Widget with TextfOptions ---
        await pumpTextfWidget(
          tester,
          data: inputText,
          textfOptions: TextfOptions(
            child: const SizedBox.shrink(), // Dummy child
            onLinkHover: (url, displayText, {required bool isHovering}) {
              hoverCalled = true;
              hoveredUrl = url;
              hoveredText = displayText;
              isHover = isHovering;
            },
          ),
        );

        // --- Find the Interactive Widget ---
        final linkFinder = find.byType(HoverableLinkSpan);
        expect(linkFinder, findsOneWidget);

        // --- Simulate Hover Enter ---
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(); // Add a mouse pointer
        await gesture.moveTo(tester.getCenter(linkFinder)); // Move pointer over the link
        await tester.pump(); // Allow hover event processing

        // --- Verify Hover Enter Callback ---
        expect(hoverCalled, isTrue, reason: 'onLinkHover should be called on enter');
        expect(isHover, isTrue, reason: 'isHovering should be true on enter');
        expect(hoveredUrl, expectedUrl);
        expect(hoveredText, expectedRawText);

        // --- Simulate Hover Exit ---
        hoverCalled = false; // Reset flag for exit check
        await gesture.moveTo(Offset.zero); // Move pointer away from the link
        await tester.pump(); // Allow hover event processing

        // --- Verify Hover Exit Callback ---
        expect(hoverCalled, isTrue, reason: 'onLinkHover should be called again on exit');
        expect(isHover, isFalse, reason: 'isHovering should be false on exit');
        // URL and text should remain the same from the last call
        expect(hoveredUrl, expectedUrl);
        expect(hoveredText, expectedRawText);

        // Clean up the gesture
        await gesture.removePointer();
      });
    });
  });
}
