// ignore_for_file: cascade_invocations // cascade_invocations for readability and chaining methods.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';

void main() {
  group('TextfParser Tests', () {
    late TextfParser parser;
    late BuildContext mockContext;

    setUp(() {
      parser = TextfParser();
      // Use a real BuildContext in a widget test
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

    group('Basic Parsing', () {
      testWidgets('empty text returns empty spans list', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('', mockContext, const TextStyle());
        expect(spans, isEmpty);
      });

      testWidgets('plain text returns single TextSpan', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('plain text', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect(spans[0], isA<TextSpan>());
        expect((spans[0] as TextSpan).text, 'plain text');
      });

      testWidgets('text with no actual formatting is handled efficiently', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse(
          'text with * single asterisk',
          mockContext,
          const TextStyle(),
        );
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).text, 'text with * single asterisk');
      });
    });

    group('Style Application', () {
      testWidgets('bold text applies FontWeight.bold', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('**bold**', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[0] as TextSpan).text, 'bold');
      });

      testWidgets('italic text applies FontStyle.italic', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('*italic*', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans[0] as TextSpan).text, 'italic');
      });

      testWidgets('bold-italic text applies both styles', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('***bold-italic***', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[0] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans[0] as TextSpan).text, 'bold-italic');
      });

      testWidgets('strikethrough text applies line-through decoration', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('~~strikethrough~~', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect(
          (spans[0] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
        expect((spans[0] as TextSpan).text, 'strikethrough');
      });

      testWidgets('code text applies monospace and background', (tester) async {
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
        final parser = TextfParser();

        final spans = parser.parse('`code`', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).style?.fontFamily, 'monospace');
        expect(
          (spans[0] as TextSpan).style?.backgroundColor,
          // Expect theme surfaceContainer instead of old hardcoded grey
          lightTheme.colorScheme.surfaceContainer,
          reason: 'Code background should come from theme',
        );
        expect((spans[0] as TextSpan).text, 'code');
        expect(
          (spans[0] as TextSpan).style?.color,
          // Expect theme text color for code
          lightTheme.colorScheme.onSurfaceVariant,
          reason: 'Code text color should come from theme',
        );
      });

      testWidgets('base style is preserved and extended', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle(fontSize: 20, color: Colors.blue);
        final spans = parser.parse('**bold**', mockContext, baseStyle);
        expect((spans[0] as TextSpan).style?.fontSize, 20);
        expect((spans[0] as TextSpan).style?.color, Colors.blue);
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
      });

      testWidgets('understcore variants apply correct styles', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final boldSpans = parser.parse('__bold__', mockContext, const TextStyle());
        expect((boldSpans[0] as TextSpan).style?.fontWeight, FontWeight.bold);

        final italicSpans = parser.parse('_italic_', mockContext, const TextStyle());
        expect((italicSpans[0] as TextSpan).style?.fontStyle, FontStyle.italic);

        final boldItalicSpans = parser.parse('___both___', mockContext, const TextStyle());
        expect(
          (boldItalicSpans[0] as TextSpan).style?.fontWeight,
          FontWeight.bold,
        );
        expect(
          (boldItalicSpans[0] as TextSpan).style?.fontStyle,
          FontStyle.italic,
        );
      });
    });

    group('Nesting Tests', () {
      testWidgets('nested formatting with different markers works', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse(
          '**bold with _italic_ inside**',
          mockContext,
          const TextStyle(),
        );

        expect(spans.length, 3);
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[0] as TextSpan).text, 'bold with ');

        expect((spans[1] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[1] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans[1] as TextSpan).text, 'italic');

        expect((spans[2] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).text, ' inside');
      });

      testWidgets('nested formatting with same markers handles correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse(
          '**bold with *italic* inside**',
          mockContext,
          const TextStyle(),
        );

        // The parser should handle this specific case gracefully
        // We verify it doesn't crash and produces reasonable output
        expect(spans.isNotEmpty, true);
      });

      testWidgets('exceeding maximum nesting depth treats as text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        // 3 levels of nesting (exceeds default maxDepth of 2)
        final spans = parser.parse(
          '**bold _italic ~~strike~~ text_**',
          mockContext,
          const TextStyle(),
        );

        // Verify that the third level is not applied
        bool hasStrikethrough = false;
        for (final span in spans) {
          if (span is TextSpan && span.style?.decoration == TextDecoration.lineThrough) {
            hasStrikethrough = true;
            break;
          }
        }
        expect(hasStrikethrough, false);
      });

      testWidgets('different nesting combinations parse correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        // Bold with code
        final boldWithCode = parser.parse(
          '**bold with `code`**',
          mockContext,
          const TextStyle(),
        );
        expect(boldWithCode.length, 2);
        expect((boldWithCode[1] as TextSpan).style?.fontFamily, 'monospace');

        // Italic with strike
        final italicWithStrike = parser.parse(
          '*italic with ~~strike~~*',
          mockContext,
          const TextStyle(),
        );
        expect(italicWithStrike.length, 2);
        expect(
          (italicWithStrike[1] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
      });
    });

    group('Error Handling', () {
      testWidgets('unpaired opening marker treated as text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('**bold', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).text, '**bold');
      });

      testWidgets('unpaired closing marker treated as text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('bold**', mockContext, const TextStyle());
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).text, 'bold**');
      });

      testWidgets('improperly nested tags handled gracefully', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        // opening bold, opening italic, closing bold, closing italic
        final spans = parser.parse(
          '**bold *italic** text*',
          mockContext,
          const TextStyle(),
        );

        // The result should not crash and should make a reasonable attempt
        expect(spans.isNotEmpty, true);
      });

      testWidgets('overlapping tags handled correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse(
          '**bold *both** italic*',
          mockContext,
          const TextStyle(),
        );

        // Should not crash and handle gracefully
        expect(spans.isNotEmpty, true);
      });
    });

    group('Cache Tests', () {
      testWidgets('different styles use different cache entries', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const text = 'Cache **test**';
        const style1 = TextStyle(fontSize: 16);
        const style2 = TextStyle(fontSize: 18);

        final firstParse = parser.parse(text, mockContext, style1);
        final secondParse = parser.parse(text, mockContext, style2);

        // Verify different instances returned
        expect(identical(firstParse, secondParse), false);
      });
    });

    group('Edge Cases', () {
      testWidgets('very long text parses correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final longText = '${'A' * 1000}**bold**${'B' * 1000}';
        final spans = parser.parse(longText, mockContext, const TextStyle());
        expect(spans.length, 3);
        expect((spans[0] as TextSpan).text?.length, 1000);
        expect((spans[1] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).text?.length, 1000);
      });

      testWidgets('Unicode characters parse correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse(
          '**你好世界** *안녕하세요* ~~Привет~~',
          mockContext,
          const TextStyle(),
        );
        expect(spans.length, 5); // 3 formatted spans + 2 spaces
        expect((spans[0] as TextSpan).text, '你好世界');
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).text, '안녕하세요');
        expect((spans[2] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans[4] as TextSpan).text, 'Привет');
        expect(
          (spans[4] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
      });

      testWidgets('emoji characters parse correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse('**😀** *🌍* ~~🚫~~', mockContext, const TextStyle());
        expect(spans.length, 5); // 3 formatted spans + 2 spaces
        expect((spans[0] as TextSpan).text, '😀');
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
      });

      testWidgets('escaped characters parse correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse(
          r'This is \*not italic\*',
          mockContext,
          const TextStyle(),
        );
        expect(spans.length, 1);
        expect((spans[0] as TextSpan).text, 'This is *not italic*');
      });
    });

    group('Mixed Formatting', () {
      testWidgets('mixed formatting applies correct styles', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = parser.parse(
          '**Bold** and *italic* and ~~strike~~ and `code`',
          mockContext,
          const TextStyle(),
        );

        expect(
          spans.length,
          7,
        ); // 4 formatted segments + 3 plain "and " segments

        // Verify styles
        expect((spans[0] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect(
          (spans[4] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
        expect((spans[6] as TextSpan).style?.fontFamily, 'monospace');
      });

      testWidgets('complex formatting combinations work', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const complex = 'Normal **bold _italic bold_ back to bold** normal *italic* end';
        final spans = parser.parse(complex, mockContext, const TextStyle());

        // Manually verify a few key spans
        bool hasBoldItalic = false;
        bool hasRegularItalic = false;

        for (final span in spans) {
          if (span is TextSpan) {
            // Check for bold+italic
            if (span.style?.fontWeight == FontWeight.bold && span.style?.fontStyle == FontStyle.italic) {
              hasBoldItalic = true;
            }

            // Check for just italic (not bold)
            if (span.style?.fontStyle == FontStyle.italic && span.style?.fontWeight != FontWeight.bold) {
              hasRegularItalic = true;
            }
          }
        }

        expect(hasBoldItalic, true);
        expect(hasRegularItalic, true);
      });
    });
  });
}
