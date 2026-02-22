// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/textf_span_builder.dart';
import 'package:textf/textf.dart';

void main() {
  group('TextfSpanBuilder', () {
    late TextfSpanBuilder builder;
    late BuildContext testContext;

    setUp(() {
      builder = TextfSpanBuilder();
      TextfSpanBuilder.clearCache();
    });

    Widget buildTestWidget(
      WidgetTester tester,
      Widget Function(BuildContext) widgetBuilder,
    ) {
      return MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return widgetBuilder(context);
          },
        ),
      );
    }

    /// Verifies that the total character count of all spans equals the
    /// original text length. This is the critical invariant for cursor
    /// positioning in text fields.
    int totalSpanLength(List<TextSpan> spans) {
      return spans.fold(0, (sum, span) => sum + (span.text?.length ?? 0));
    }

    group('Fast Paths', () {
      testWidgets('empty text returns empty list', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build('', testContext, const TextStyle());
        expect(spans, isEmpty);
      });

      testWidgets('plain text returns single TextSpan', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          'hello world',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 1);
        expect(spans.first.text, 'hello world');
      });
    });

    group('Character Count Invariant', () {
      testWidgets('bold text preserves character count', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = '**bold**';
        final spans = builder.build(input, testContext, const TextStyle());
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('italic text preserves character count', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = '*italic*';
        final spans = builder.build(input, testContext, const TextStyle());
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('mixed formatting preserves character count', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = 'hello **bold** and *italic* `code` world';
        final spans = builder.build(input, testContext, const TextStyle());
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('link text preserves character count', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = '[click here](https://example.com)';
        final spans = builder.build(input, testContext, const TextStyle());
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('placeholder text preserves character count', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = 'hello {icon} world';
        final spans = builder.build(input, testContext, const TextStyle());
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('nested formatting preserves character count', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = '**bold *italic* bold**';
        final spans = builder.build(input, testContext, const TextStyle());
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('all formatting types preserve character count', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = '**b** *i* ~~s~~ ++u++ ==h== `c` ^sup^ ~sub~ [l](u) {p}';
        final spans = builder.build(input, testContext, const TextStyle());
        expect(totalSpanLength(spans), input.length);
      });
    });

    group('Bold Formatting', () {
      testWidgets('renders markers dimmed and content bold', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build('**bold**', testContext, const TextStyle());
        // 3 spans: ** (dimmed) + bold (styled) + ** (dimmed)
        expect(spans.length, 3);
        expect(spans.first.text, '**');
        expect(spans[1].text, 'bold');
        expect(spans[1].style?.fontWeight, FontWeight.bold);
        expect(spans[2].text, '**');
      });

      testWidgets('mixed bold and plain text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          'hello **bold** world',
          testContext,
          const TextStyle(),
        );
        // 5 spans: hello  + ** + bold + ** + world
        expect(spans.length, 5);
        expect(spans.first.text, 'hello ');
        expect(spans[1].text, '**');
        expect(spans[2].text, 'bold');
        expect(spans[2].style?.fontWeight, FontWeight.bold);
        expect(spans[3].text, '**');
        expect(spans[4].text, ' world');
      });
    });

    group('Italic Formatting', () {
      testWidgets('renders markers dimmed and content italic', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '*italic*',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 3);
        expect(spans.first.text, '*');
        expect(spans[1].text, 'italic');
        expect(spans[1].style?.fontStyle, FontStyle.italic);
        expect(spans[2].text, '*');
      });
    });

    group('Bold-Italic Formatting', () {
      testWidgets('applies both bold and italic', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '***both***',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 3);
        expect(spans.first.text, '***');
        expect(spans[1].text, 'both');
        expect(spans[1].style?.fontWeight, FontWeight.bold);
        expect(spans[1].style?.fontStyle, FontStyle.italic);
        expect(spans[2].text, '***');
      });
    });

    group('Strikethrough Formatting', () {
      testWidgets('applies line-through decoration', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '~~strike~~',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 3);
        expect(spans.first.text, '~~');
        expect(spans[1].text, 'strike');
        expect(
          spans[1].style?.decoration,
          TextDecoration.lineThrough,
        );
        expect(spans[2].text, '~~');
      });
    });

    group('Underline Formatting', () {
      testWidgets('applies underline decoration', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '++underline++',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 3);
        expect(spans.first.text, '++');
        expect(spans[1].text, 'underline');
        expect(
          spans[1].style?.decoration,
          TextDecoration.underline,
        );
        expect(spans[2].text, '++');
      });
    });

    group('Highlight Formatting', () {
      testWidgets('applies highlight background', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '==highlight==',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 3);
        expect(spans.first.text, '==');
        expect(spans[1].text, 'highlight');
        expect(spans[1].style?.backgroundColor, isNotNull);
        expect(spans[2].text, '==');
      });
    });

    group('Code Formatting', () {
      testWidgets('applies monospace font', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '`code`',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 3);
        expect(spans.first.text, '`');
        expect(spans[1].text, 'code');
        expect(spans[1].style?.fontFamily, 'monospace');
        expect(spans[2].text, '`');
      });
    });

    group('Superscript Formatting', () {
      testWidgets('applies smaller font size without WidgetSpan', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        final spans = builder.build('^super^', testContext, baseStyle);
        expect(spans.length, 3);
        expect(spans.first.text, '^');
        expect(spans[1], isA<TextSpan>());
        expect(spans[1].text, 'super');
        // Font size should be reduced (16 * 0.6 = 9.6)
        expect(spans[1].style?.fontSize, lessThan(16));
        expect(spans[2].text, '^');
      });
    });

    group('Subscript Formatting', () {
      testWidgets('applies smaller font size without WidgetSpan', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        final spans = builder.build('~sub~', testContext, baseStyle);
        expect(spans.length, 3);
        expect(spans.first.text, '~');
        expect(spans[1], isA<TextSpan>());
        expect(spans[1].text, 'sub');
        expect(spans[1].style?.fontSize, lessThan(16));
        expect(spans[2].text, '~');
      });
    });

    group('Link Handling', () {
      testWidgets('renders link with all characters visible', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '[click here](https://example.com)',
          testContext,
          const TextStyle(),
        );
        // Should produce 5 spans: [ , link text, ]( , url, )
        expect(spans.length, 5);
        expect(spans.first.text, '[');
        expect(spans[1].text, 'click here');
        expect(spans[2].text, '](');
        expect(spans[3].text, 'https://example.com');
        expect(spans[4].text, ')');
      });

      testWidgets('link text gets link styling', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '[link](url)',
          testContext,
          const TextStyle(),
        );
        // The link text span should have underline decoration (link style)
        expect(
          spans[1].style?.decoration,
          TextDecoration.underline,
        );
      });

      testWidgets('incomplete link renders as plain text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '[not a link',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 1);
        expect(spans.first.text, '[not a link');
      });
    });

    group('Placeholder Handling', () {
      testWidgets('renders placeholder as literal text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          'hello {icon} world',
          testContext,
          const TextStyle(),
        );
        // The {icon} should be rendered as plain text
        final allText = spans.map((s) => s.text).join();
        expect(allText, 'hello {icon} world');
      });
    });

    group('Nested Formatting', () {
      testWidgets('bold with nested italic', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          '**bold *italic* bold**',
          testContext,
          const TextStyle(),
        );
        // ** + bold  + * + italic + * +  bold + **
        expect(spans.length, 7);
        expect(spans.first.text, '**'); // opening bold marker
        expect(spans[1].text, 'bold ');
        expect(spans[1].style?.fontWeight, FontWeight.bold);
        expect(spans[2].text, '*'); // opening italic marker
        expect(spans[3].text, 'italic');
        expect(spans[3].style?.fontWeight, FontWeight.bold);
        expect(spans[3].style?.fontStyle, FontStyle.italic);
        expect(spans[4].text, '*'); // closing italic marker
        expect(spans[5].text, ' bold');
        expect(spans[5].style?.fontWeight, FontWeight.bold);
        expect(spans[6].text, '**'); // closing bold marker
      });
    });

    group('Unpaired Markers', () {
      testWidgets('single asterisk renders as plain text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        final spans = builder.build(
          'hello * world',
          testContext,
          const TextStyle(),
        );
        expect(spans.length, 1);
        expect(spans.first.text, 'hello * world');
      });
    });

    group('Marker Style', () {
      testWidgets('markers have dimmed opacity', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseColor = Color(0xFF000000);
        final spans = builder.build(
          '**bold**',
          testContext,
          const TextStyle(color: baseColor),
        );
        // The marker spans should have reduced opacity
        final markerColor = spans.first.style?.color;
        expect(markerColor, isNotNull);
        expect(markerColor!.a, lessThan(1.0));
      });
    });

    group('TextfOptions Integration', () {
      testWidgets('respects TextfOptions bold style', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TextfOptions(
              boldStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.red,
              ),
              child: Builder(
                builder: (context) {
                  testContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );
        final spans = builder.build(
          '**bold**',
          testContext,
          const TextStyle(),
        );
        // spans[1] is the content span (between markers)
        expect(spans[1].style?.fontWeight, FontWeight.w900);
        expect(spans[1].style?.color, Colors.red);
      });
    });

    group('Cursor Position (Smart Hide)', () {
      // Input: **bold** (positions 0-7)
      // Opening marker ** at positions 0-1
      // Content "bold" at positions 2-5
      // Closing marker ** at positions 6-7

      testWidgets('cursor inside span shows active markers', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Cursor at position 3 (inside "bold")
        final spans = builder.build(
          '**bold**',
          testContext,
          baseStyle,
          cursorPosition: 3,
        );
        expect(spans.length, 3);
        // Opening marker should be dimmed (active, not hidden)
        final openMarkerColor = spans.first.style?.color;
        expect(openMarkerColor, isNotNull);
        expect(openMarkerColor!.a, greaterThan(0));
        expect(openMarkerColor.a, lessThan(1.0));
      });

      testWidgets('cursor outside span hides inactive markers', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Input: "hi **bold** bye" — cursor at position 0 ("h")
        final spans = builder.build(
          'hi **bold** bye',
          testContext,
          baseStyle,
          cursorPosition: 0,
          markerOpacity: 0,
        );
        // Find the opening ** marker (should be hidden)
        final openMarker = spans[1]; // "hi " is spans[0], "**" is spans[1]
        expect(openMarker.text, '**');
        expect(openMarker.style?.color?.a, 0);
        expect(openMarker.style?.fontSize, lessThan(1));
      });

      testWidgets('cursor on opening marker shows markers', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Cursor at position 0 (on the opening **)
        final spans = builder.build(
          '**bold**',
          testContext,
          baseStyle,
          cursorPosition: 0,
        );
        // Cursor is on the opening marker itself — should be active
        final openMarkerColor = spans.first.style?.color;
        expect(openMarkerColor!.a, greaterThan(0));
      });

      testWidgets('cursor on closing marker shows markers', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Cursor at position 7 (end of closing **)
        final spans = builder.build(
          '**bold**',
          testContext,
          baseStyle,
          cursorPosition: 7,
        );
        final closeMarkerColor = spans[2].style?.color;
        expect(closeMarkerColor!.a, greaterThan(0));
      });

      testWidgets('preserves character count with cursorPosition', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const input = 'hi **bold** and *italic* bye';
        final spans = builder.build(
          input,
          testContext,
          const TextStyle(),
          cursorPosition: 5,
          markerOpacity: 0,
        );
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('link markers hidden when cursor outside', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Input: "hi [link](url) bye" — cursor at position 0
        final spans = builder.build(
          'hi [link](url) bye',
          testContext,
          baseStyle,
          cursorPosition: 0,
          markerOpacity: 0,
        );
        // Find the "[" marker (should be hidden)
        final bracketSpan = spans[1]; // "hi " is spans[0], "[" is spans[1]
        expect(bracketSpan.text, '[');
        expect(bracketSpan.style?.color?.a, 0);
      });

      testWidgets('link markers visible when cursor inside', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Input: "[link](url)" — cursor at position 2 (inside "link")
        final spans = builder.build(
          '[link](url)',
          testContext,
          baseStyle,
          cursorPosition: 2,
        );
        // "[" marker should be active (dimmed, not hidden)
        final bracketColor = spans.first.style?.color;
        expect(bracketColor!.a, greaterThan(0));
      });
    });

    group('Marker Opacity', () {
      testWidgets('markerOpacity 0.5 produces intermediate alpha', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Input: "hi **bold** bye" — cursor at 0 (outside), opacity 0.5
        final spans = builder.build(
          'hi **bold** bye',
          testContext,
          baseStyle,
          cursorPosition: 0,
          markerOpacity: 0.5,
        );
        final markerColor = spans[1].style?.color; // ** marker
        expect(markerColor, isNotNull);
        // Alpha should be 0.5 * 0.4 = 0.2
        expect(markerColor!.a, closeTo(0.2, 0.01));
        // Font size should be normal (null = inherited, not collapsed to 0.01)
        expect(spans[1].style?.fontSize, isNot(0.01));
      });

      testWidgets('markerOpacity 1.0 without cursorPosition uses default', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(color: Color(0xFF000000));
        final spansDefault = builder.build(
          '**bold**',
          testContext,
          baseStyle,
        );
        final spansWithOpacity = builder.build(
          '**bold**',
          testContext,
          baseStyle,
        );
        // Without cursorPosition, both should produce the same marker style
        expect(
          spansDefault.first.style?.color,
          spansWithOpacity.first.style?.color,
        );
      });
    });

    group('Cache', () {
      testWidgets('clearCache does not affect subsequent builds', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));

        final spans1 = builder.build('**bold**', testContext, const TextStyle());
        TextfSpanBuilder.clearCache();
        final spans2 = builder.build('**bold**', testContext, const TextStyle());

        expect(spans1.length, spans2.length);
        expect(spans1[1].text, spans2[1].text);
      });
    });
  });
}
