// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

void main() {
  group('TextfParser Tests', () {
    // ignore: avoid-late-keyword
    late TextfParser parser;
    final resolver = TextfStyleResolver(options: null);

    setUp(() {
      parser = TextfParser();
    });

    group('Basic Parsing', () {
      test('empty text returns empty spans list', () {
        final spans = parser.parse('', const TextStyle(), resolver);
        expect(spans, isEmpty);
      });

      test('plain text returns single TextSpan', () {
        final spans = parser.parse('plain text', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect(spans.first, isA<TextSpan>());
        expect((spans.first as TextSpan).text, 'plain text');
      });

      test('text with no actual formatting is handled efficiently', () {
        final spans = parser.parse('text with * single asterisk', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).text, 'text with * single asterisk');
      });
    });

    group('Style Application', () {
      test('bold text applies FontWeight.bold', () {
        final spans = parser.parse('**bold**', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans.first as TextSpan).text, 'bold');
      });

      test('italic text applies FontStyle.italic', () {
        final spans = parser.parse('*italic*', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans.first as TextSpan).text, 'italic');
      });

      test('bold-italic text applies both styles', () {
        final spans = parser.parse('***bold-italic***', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans.first as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans.first as TextSpan).text, 'bold-italic');
      });

      test('strikethrough text applies line-through decoration', () {
        final spans = parser.parse('~~strikethrough~~', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect(
          (spans.first as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
        expect((spans.first as TextSpan).text, 'strikethrough');
      });

      test('code text applies monospace and background', () {
        final parser = TextfParser();

        final spans = parser.parse('`code`', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).style?.fontFamily, 'monospace');
        expect(
          (spans.first as TextSpan).style?.backgroundColor,
          // No text color set: the palette assumes black on a light surface.
          const Color(0xFF000000).withValues(alpha: 0.05),
          reason: 'Code background should be the neutral foreground tint',
        );
        expect((spans.first as TextSpan).text, 'code');
        expect(
          (spans.first as TextSpan).style?.color,
          isNull,
          reason: 'Code text keeps the (unset) segment color',
        );
      });

      test('base style is preserved and extended', () {
        const baseStyle = TextStyle(fontSize: 20, color: Color(0xFF2196F3));
        final spans = parser.parse('**bold**', baseStyle, resolver);
        expect((spans.first as TextSpan).style?.fontSize, 20);
        expect((spans.first as TextSpan).style?.color, const Color(0xFF2196F3));
        expect((spans.first as TextSpan).style?.fontWeight, FontWeight.bold);
      });

      test('superscript text applies WidgetSpan with bottom padding (visually up)', () {
        // Provide a font size so offset calculation is non-zero
        final spans = parser.parse('^super^', const TextStyle(fontSize: 20), resolver);

        expect(spans.length, 1);
        expect(spans.first, isA<WidgetSpan>());

        final widgetSpan = spans.first as WidgetSpan;
        // Verify alignment - Middle is required for correct selection sorting
        expect(widgetSpan.alignment, PlaceholderAlignment.middle);

        // Verify Padding (Superscript uses Bottom padding to push text UP relative to center)
        expect(widgetSpan.child, isA<Padding>());
        final paddingWidget = widgetSpan.child as Padding;
        final padding = paddingWidget.padding as EdgeInsets;

        expect(padding.bottom, greaterThan(0), reason: 'Superscript should have bottom padding');
        expect(padding.top, 0.0);

        // Verify inner text content
        final innerText = (paddingWidget.child! as Text).textSpan! as TextSpan;
        expect(innerText.text, 'super');
      });

      test('subscript text applies WidgetSpan with top padding (visually down)', () {
        // Provide a font size so offset calculation is non-zero
        final spans = parser.parse('~sub~', const TextStyle(fontSize: 20), resolver);

        expect(spans.length, 1);
        expect(spans.first, isA<WidgetSpan>());

        final widgetSpan = spans.first as WidgetSpan;
        // Verify alignment
        expect(widgetSpan.alignment, PlaceholderAlignment.middle);

        // Verify Padding (Subscript uses Top padding to push text DOWN relative to center)
        expect(widgetSpan.child, isA<Padding>());
        final paddingWidget = widgetSpan.child as Padding;
        final padding = paddingWidget.padding as EdgeInsets;

        expect(padding.top, greaterThan(0), reason: 'Subscript should have top padding');
        expect(padding.bottom, 0.0);

        // Verify inner text content
        final innerText = (paddingWidget.child! as Text).textSpan! as TextSpan;
        expect(innerText.text, 'sub');
      });

      test('understcore variants apply correct styles', () {
        final boldSpans = parser.parse('__bold__', const TextStyle(), resolver);
        expect((boldSpans.first as TextSpan).style?.fontWeight, FontWeight.bold);

        final italicSpans = parser.parse('_italic_', const TextStyle(), resolver);
        expect((italicSpans.first as TextSpan).style?.fontStyle, FontStyle.italic);

        final boldItalicSpans = parser.parse('___both___', const TextStyle(), resolver);
        expect(
          (boldItalicSpans.first as TextSpan).style?.fontWeight,
          FontWeight.bold,
        );
        expect(
          (boldItalicSpans.first as TextSpan).style?.fontStyle,
          FontStyle.italic,
        );
      });
    });

    group('Nesting Tests', () {
      test('nested formatting with different markers works', () {
        final spans = parser.parse('**bold with _italic_ inside**', const TextStyle(), resolver);

        expect(spans.length, 3);
        expect((spans.first as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans.first as TextSpan).text, 'bold with ');

        expect((spans[1] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[1] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans[1] as TextSpan).text, 'italic');

        expect((spans[2] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).text, ' inside');
      });

      test('nested formatting with same markers handles correctly', () {
        final spans = parser.parse('**bold with *italic* inside**', const TextStyle(), resolver);

        // The parser should handle this specific case gracefully
        // We verify it doesn't crash and produces reasonable output
        expect(spans.isNotEmpty, true);
      });

      test('exceeding maximum nesting depth treats as text', () {
        // 3 levels of nesting (exceeds default maxDepth of 2)
        final spans = parser.parse(
          '**bold _italic ~~strike~~ text_**',
          const TextStyle(),
          resolver,
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

      test('different nesting combinations parse correctly', () {
        // Bold with code
        final boldWithCode = parser.parse('**bold with `code`**', const TextStyle(), resolver);
        expect(boldWithCode.length, 2);
        expect((boldWithCode[1] as TextSpan).style?.fontFamily, 'monospace');

        // Italic with strike
        final italicWithStrike = parser.parse(
          '*italic with ~~strike~~*',
          const TextStyle(),
          resolver,
        );
        expect(italicWithStrike.length, 2);
        expect(
          (italicWithStrike[1] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
      });
    });

    group('Error Handling', () {
      test('unpaired opening marker treated as text', () {
        final spans = parser.parse('**bold', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).text, '**bold');
      });

      test('unpaired closing marker treated as text', () {
        final spans = parser.parse('bold**', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).text, 'bold**');
      });

      test('improperly nested tags handled gracefully', () {
        // opening bold, opening italic, closing bold, closing italic
        final spans = parser.parse('**bold *italic** text*', const TextStyle(), resolver);

        // The result should not crash and should make a reasonable attempt
        expect(spans.isNotEmpty, true);
      });

      test('overlapping tags handled correctly', () {
        final spans = parser.parse('**bold *both** italic*', const TextStyle(), resolver);

        // Should not crash and handle gracefully
        expect(spans.isNotEmpty, true);
      });
    });

    group('Cache Tests', () {
      test('different styles use different cache entries', () {
        const text = 'Cache **test**';
        const style1 = TextStyle(fontSize: 16);
        const style2 = TextStyle(fontSize: 18);

        final firstParse = parser.parse(text, style1, resolver);
        final secondParse = parser.parse(text, style2, resolver);

        // Verify different instances returned
        expect(identical(firstParse, secondParse), false);
      });
    });

    group('Edge Cases', () {
      test('very long text parses correctly', () {
        final longText = '${'A' * 1000}**bold**${'B' * 1000}';
        final spans = parser.parse(longText, const TextStyle(), resolver);
        expect(spans.length, 3);
        expect((spans.first as TextSpan).text?.length, 1000);
        expect((spans[1] as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).text?.length, 1000);
      });

      test('Unicode characters parse correctly', () {
        final spans = parser.parse('**你好世界** *안녕하세요* ~~Привет~~', const TextStyle(), resolver);
        expect(spans.length, 5); // 3 formatted spans + 2 spaces
        expect((spans.first as TextSpan).text, '你好世界');
        expect((spans.first as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).text, '안녕하세요');
        expect((spans[2] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect((spans[4] as TextSpan).text, 'Привет');
        expect(
          (spans[4] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
      });

      test('emoji characters parse correctly', () {
        final spans = parser.parse('**😀** *🌍* ~~🚫~~', const TextStyle(), resolver);
        expect(spans.length, 5); // 3 formatted spans + 2 spaces
        expect((spans.first as TextSpan).text, '😀');
        expect((spans.first as TextSpan).style?.fontWeight, FontWeight.bold);
      });

      test('escaped characters parse correctly', () {
        final spans = parser.parse(r'This is \*not italic\*', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect((spans.first as TextSpan).text, 'This is *not italic*');
      });
    });

    group('Mixed Formatting', () {
      test('mixed formatting applies correct styles', () {
        final spans = parser.parse(
          '**Bold** and *italic* and ~~strike~~ and `code`',
          const TextStyle(),
          resolver,
        );

        expect(
          spans.length,
          7,
        ); // 4 formatted segments + 3 plain "and " segments

        // Verify styles
        expect((spans.first as TextSpan).style?.fontWeight, FontWeight.bold);
        expect((spans[2] as TextSpan).style?.fontStyle, FontStyle.italic);
        expect(
          (spans[4] as TextSpan).style?.decoration,
          TextDecoration.lineThrough,
        );
        expect((spans[6] as TextSpan).style?.fontFamily, 'monospace');
      });

      test('complex formatting combinations work', () {
        const complex = 'Normal **bold _italic bold_ back to bold** normal *italic* end';
        final spans = parser.parse(complex, const TextStyle(), resolver);

        // Manually verify a few key spans
        bool hasBoldItalic = false;
        bool hasRegularItalic = false;

        for (final span in spans) {
          if (span is TextSpan) {
            // Check for bold+italic
            if (span.style?.fontWeight == FontWeight.bold &&
                span.style?.fontStyle == FontStyle.italic) {
              hasBoldItalic = true;
            }

            // Check for just italic (not bold)
            if (span.style?.fontStyle == FontStyle.italic &&
                span.style?.fontWeight != FontWeight.bold) {
              hasRegularItalic = true;
            }
          }
        }

        expect(hasBoldItalic, true);
        expect(hasRegularItalic, true);
      });
    });
    group('Link Alignment', () {
      test('linkAlignment option works', () {
        final spans = parser.parse(
          '[link](url)',
          const TextStyle(),
          TextfStyleResolver(
            options: const TextfOptionsData(linkAlignment: PlaceholderAlignment.middle),
          ),
        );

        expect(spans, hasLength(1));
        expect(spans.first, isA<WidgetSpan>());
        final widgetSpan = spans.first as WidgetSpan;
        expect(widgetSpan.alignment, PlaceholderAlignment.middle);
      });
    });
  });
}
