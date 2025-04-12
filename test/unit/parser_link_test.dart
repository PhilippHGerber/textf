import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/models/url_link_span.dart';
import 'package:textf/src/parsing/parser.dart';
import 'package:textf/src/widgets/textf_options.dart';

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
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [Flutter website](https://flutter.dev)',
          mockContext,
          const TextStyle(),
        );

        // Expect 2 spans: text before link "Visit " and the link itself
        expect(spans.length, 2);

        // First span should be text
        expect(spans[0], isA<TextSpan>());
        expect((spans[0] as TextSpan).text, 'Visit ');

        // Second span should be a UrlLinkSpan
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Check link properties
        expect(linkSpan.url, 'https://flutter.dev');
        expect(linkSpan.text, 'Flutter website');

        // Link should have default URL styling
        expect(linkSpan.style?.color, DefaultStyles.urlColor);
        expect(linkSpan.style?.decoration, TextDecoration.underline);
      });

      testWidgets('link with URL normalization', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [Google](google.com)',
          mockContext,
          const TextStyle(),
        );

        // Get link span (second span)
        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Check URL normalization (should add http:// prefix)
        expect(linkSpan.url, 'http://google.com');
      });

      testWidgets('multiple links in text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [Flutter](https://flutter.dev) or [Dart](https://dart.dev)',
          mockContext,
          const TextStyle(),
        );

        // Expect 4 spans: "Visit ", first link, " or ", second link
        expect(spans.length, 4);

        // Check text spans
        expect(spans[0], isA<TextSpan>());
        expect((spans[0] as TextSpan).text, 'Visit ');

        expect(spans[2], isA<TextSpan>());
        expect((spans[2] as TextSpan).text, ' or ');

        // Check link spans
        expect(spans[1], isA<UrlLinkSpan>());
        expect(spans[3], isA<UrlLinkSpan>());

        expect((spans[1] as UrlLinkSpan).url, 'https://flutter.dev');
        expect((spans[1] as UrlLinkSpan).text, 'Flutter');

        expect((spans[3] as UrlLinkSpan).url, 'https://dart.dev');
        expect((spans[3] as UrlLinkSpan).text, 'Dart');
      });
    });

    group('Formatted Link Text', () {
      testWidgets('bold text in link', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [**Bold Link**](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[0], isA<TextSpan>());
        expect((spans[0] as TextSpan).text, 'Visit ');

        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;
        expect(linkSpan.url, 'https://example.com');

        // The link span should have children for the formatted text
        expect(linkSpan.children, isNotNull);
        expect(linkSpan.children!.length, 1);

        // The child span should be bold
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.fontWeight, FontWeight.bold);
        expect(childSpan.text, 'Bold Link');
      });

      testWidgets('italic text in link', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [*Italic Link*](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        expect(linkSpan.children!.length, 1);
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.fontStyle, FontStyle.italic);
        expect(childSpan.text, 'Italic Link');
      });

      testWidgets('strikethrough text in link', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [~~Strikethrough Link~~](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        expect(linkSpan.children!.length, 1);
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.decoration, TextDecoration.lineThrough);
        expect(childSpan.text, 'Strikethrough Link');
      });

      testWidgets('code text in link', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [`Code Link`](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        expect(linkSpan.children!.length, 1);
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.fontFamily, 'monospace');
        expect(childSpan.text, 'Code Link');
      });
    });

    group('Mixed Formatting in Link Text', () {
      testWidgets('multiple formatting styles in link', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [**Bold** and *italic* text](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Should have multiple children for different formatting styles
        expect(linkSpan.children!.length, 4);

        // First child should be bold
        final boldSpan = linkSpan.children![0] as TextSpan;
        expect(boldSpan.style?.fontWeight, FontWeight.bold);
        expect(boldSpan.text, 'Bold');

        // Second child should be plain
        final plainSpan = linkSpan.children![1] as TextSpan;
        expect(plainSpan.text, ' and ');

        // Third child should be italic
        final italicSpan = linkSpan.children![2] as TextSpan;
        expect(italicSpan.style?.fontStyle, FontStyle.italic);
        expect(italicSpan.text, 'italic');

        // Fourth child should be plain
        final plainSpan2 = linkSpan.children![3] as TextSpan;
        expect(plainSpan2.text, ' text');
      });

      testWidgets('nested formatting in link text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [**Bold _and italic_**](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Should handle nested formatting correctly
        expect(linkSpan.children!.length, 2);

        // First part: Bold only
        final boldSpan = linkSpan.children![0] as TextSpan;
        expect(boldSpan.style?.fontWeight, FontWeight.bold);
        expect(boldSpan.text, 'Bold ');

        // Second part: Bold and italic
        final boldItalicSpan = linkSpan.children![1] as TextSpan;
        expect(boldItalicSpan.style?.fontWeight, FontWeight.bold);
        expect(boldItalicSpan.style?.fontStyle, FontStyle.italic);
        expect(boldItalicSpan.text, 'and italic');
      });
    });

    group('Style Inheritance', () {
      testWidgets('link style is properly applied to formatted text', (tester) async {
        // Create a properly nested TextfOptions that will be available in the context
        late BuildContext testContext;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextfOptions(
                  urlStyle: TextStyle(color: Colors.red, fontSize: 18),
                  child: Builder(
                    builder: (innerContext) {
                      testContext = innerContext; // Capture the context with TextfOptions
                      return Container();
                    },
                  ),
                );
              },
            ),
          ),
        );

        final spans = parser.parse(
          'Visit [**Bold Link**](https://example.com)',
          testContext, // Use the context that has TextfOptions
          const TextStyle(fontSize: 16),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Check that link style is applied
        expect(linkSpan.style?.color, Colors.red);
        expect(linkSpan.style?.fontSize, 18);

        // Child formatting should inherit link style and add bold
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.color, Colors.red);
        expect(childSpan.style?.fontSize, 18);
        expect(childSpan.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('base style is properly inherited by links', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final baseStyle = TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          height: 1.5,
        );

        final spans = parser.parse(
          'Visit [**Bold Link**](https://example.com)',
          mockContext,
          baseStyle,
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Link should inherit base style properties
        expect(linkSpan.style?.fontFamily, 'Roboto');
        expect(linkSpan.style?.fontSize, 20);
        expect(linkSpan.style?.height, 1.5);

        // And child formatting should retain these properties
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.fontFamily, 'Roboto');
        expect(childSpan.style?.fontSize, 20);
        expect(childSpan.style?.height, 1.5);
      });
    });

    group('Edge Cases', () {
      testWidgets('escaped formatting characters in link text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          r'Visit [This is \*not formatted\*](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Link text should have literal asterisks, not formatting
        expect(linkSpan.text, isEmpty);
        final child = linkSpan.children![0] as TextSpan;
        expect(child.text, 'This is *not formatted*');
        expect(child.children, isNull);
      });

      testWidgets('Unicode characters in link text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [**你好世界**](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Unicode characters should be properly formatted
        expect(linkSpan.children!.length, 1);
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.fontWeight, FontWeight.bold);
        expect(childSpan.text, '你好世界');
      });

      testWidgets('empty link text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Empty link text should be handled gracefully
        expect(linkSpan.text, '');
      });

      testWidgets('very long link text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final longText = 'A' * 1000;
        final spans = parser.parse(
          'Visit [**$longText**](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Long formatted text should be handled correctly
        expect(linkSpan.children!.length, 1);
        final childSpan = linkSpan.children![0] as TextSpan;
        expect(childSpan.style?.fontWeight, FontWeight.bold);
        expect(childSpan.text?.length, 1000);
      });
    });

    group('Complex Scenarios', () {
      testWidgets('multiple links with different formatting', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [**Bold**](https://bold.com) or [*Italic*](https://italic.com)',
          mockContext,
          const TextStyle(),
        );

        // Should have: "Visit ", link 1, " or ", link 2
        expect(spans.length, 4);

        // First link should have bold formatting
        expect(spans[1], isA<UrlLinkSpan>());
        final boldLinkSpan = spans[1] as UrlLinkSpan;
        expect(boldLinkSpan.url, 'https://bold.com');
        expect(boldLinkSpan.children!.length, 1);
        expect(
          (boldLinkSpan.children![0] as TextSpan).style?.fontWeight,
          FontWeight.bold,
        );

        // Center span should be plain text
        expect(spans[2], isA<TextSpan>());
        expect((spans[2] as TextSpan).text, ' or ');

        // Second link should have italic formatting
        expect(spans[3], isA<UrlLinkSpan>());
        final italicLinkSpan = spans[3] as UrlLinkSpan;
        expect(italicLinkSpan.url, 'https://italic.com');
        expect(italicLinkSpan.children!.length, 1);
        expect(
          (italicLinkSpan.children![0] as TextSpan).style?.fontStyle,
          FontStyle.italic,
        );
      });

      testWidgets('links within formatted text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          '**Bold text with [a link](https://example.com) inside**',
          mockContext,
          const TextStyle(),
        );

        // Should have: bold start, link, bold end
        expect(spans.length, 3);

        // First span should be bold
        expect(spans[0], isA<TextSpan>());
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[0] as TextSpan).text, 'Bold text with ');

        // Middle span should be a link that inherits bold
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;
        expect(linkSpan.style?.fontWeight, FontWeight.bold);
        expect(linkSpan.text, 'a link');

        // Last span should be bold
        expect(spans[2], isA<TextSpan>());
        expect((spans[2] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).text, ' inside');
      });

      testWidgets('link text with mixed and nested formatting', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final spans = parser.parse(
          'Visit [**Bold** *Italic* ~~Strike~~ `Code` **_Both_**](https://example.com)',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Should handle complex mixed formatting correctly
        expect(linkSpan.children!.length, 9);

        // Verify each formatted section
        expect(
          (linkSpan.children![0] as TextSpan).style?.fontWeight,
          FontWeight.bold,
        );
        expect(
          (linkSpan.children![2] as TextSpan).style?.fontStyle,
          FontStyle.italic,
        );
        expect(
          (linkSpan.children![4] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
        expect(
          (linkSpan.children![6] as TextSpan).style?.fontFamily,
          'monospace',
        );

        // Verify nested formatting
        final bothSpan = linkSpan.children![8] as TextSpan;
        expect(bothSpan.style?.fontWeight, FontWeight.bold);
        expect(bothSpan.style?.fontStyle, FontStyle.italic);
      });
    });

    group('Interaction Behavior', () {
      testWidgets('tap recognizer is properly set up', (tester) async {
        // Track whether onTap was called
        bool tapCalled = false;
        String? tappedUrl;
        String? tappedText;

        // Create a properly nested TextfOptions that will be available in the context
        late BuildContext testContext;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextfOptions(
                  onUrlTap: (url, displayText) {
                    tapCalled = true;
                    tappedUrl = url;
                    tappedText = displayText;
                  },
                  child: Builder(
                    builder: (innerContext) {
                      testContext = innerContext; // Capture the context with TextfOptions
                      return Container();
                    },
                  ),
                );
              },
            ),
          ),
        );

        final spans = parser.parse(
          'Visit [**Flutter**](https://flutter.dev)',
          testContext, // Use the context that has TextfOptions
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Verify tap recognizer exists
        expect(linkSpan.recognizer, isNotNull);
        expect(linkSpan.recognizer, isA<TapGestureRecognizer>());

        // Simulate tap
        (linkSpan.recognizer as TapGestureRecognizer).onTap!();

        // Verify callback was called with correct parameters
        expect(tapCalled, true);
        expect(tappedUrl, 'https://flutter.dev');
        expect(tappedText, '**Flutter**');
      });

      testWidgets('hover callbacks are properly set up', (tester) async {
        // Track hover state
        bool hoverCalled = false;
        bool isHovering = false;
        String? hoveredUrl;
        String? hoveredText;

        // Create a properly nested TextfOptions that will be available in the context
        late BuildContext testContext;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextfOptions(
                  onUrlHover: (url, displayText, hovering) {
                    hoverCalled = true;
                    hoveredUrl = url;
                    hoveredText = displayText;
                    isHovering = hovering;
                  },
                  child: Builder(
                    builder: (innerContext) {
                      testContext = innerContext; // Capture the context with TextfOptions
                      return Container();
                    },
                  ),
                );
              },
            ),
          ),
        );

        final spans = parser.parse(
          'Visit [Flutter](https://flutter.dev)',
          testContext, // Use the context that has TextfOptions
          const TextStyle(),
        );

        expect(spans.length, 2);
        expect(spans[1], isA<UrlLinkSpan>());
        final linkSpan = spans[1] as UrlLinkSpan;

        // Verify hover callbacks exist
        expect(linkSpan.onEnter, isNotNull);
        expect(linkSpan.onExit, isNotNull);

        // Simulate hover enter
        linkSpan.onEnter!(PointerEnterEvent());

        // Verify callback was called with correct parameters
        expect(hoverCalled, true);
        expect(hoveredUrl, 'https://flutter.dev');
        expect(hoveredText, 'Flutter');
        expect(isHovering, true);

        // Reset and simulate hover exit
        hoverCalled = false;

        linkSpan.onExit!(PointerExitEvent());

        // Verify callback was called with correct parameters
        expect(hoverCalled, true);
        expect(isHovering, false);
      });
    });
  });
}
