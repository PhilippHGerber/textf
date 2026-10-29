// ignore_for_file: avoid-late-keyword, avoid-non-null-assertion, no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

void main() {
  group('Script (Superscript/Subscript) Parsing Tests', () {
    late TextfParser parser;
    final resolver = TextfStyleResolver(options: null);

    setUp(() {
      parser = TextfParser();
    });

    group('Superscript (^text^)', () {
      test('renders using Padding (Bottom) + Alignment.middle', () {
        // Use a known font size to verify padding calculation exists
        const baseStyle = TextStyle(fontSize: 20, color: Color(0xFF000000));

        final spans = parser.parse('^super^', baseStyle, resolver);

        // 1. Check structure
        expect(spans.length, 1);
        expect(spans.first, isA<WidgetSpan>());

        final widgetSpan = spans.first as WidgetSpan;

        // CRITICAL check for Selection Sort Order Fix:
        expect(
          widgetSpan.alignment,
          PlaceholderAlignment.middle,
          reason: 'Must use Alignment.middle to keep widget anchored to line center for correct selection sorting',
        );

        // 2. Check Padding Structure
        expect(widgetSpan.child, isA<Padding>());
        final paddingWidget = widgetSpan.child as Padding;
        final padding = paddingWidget.padding as EdgeInsets;

        // 3. Check Padding Direction (Superscript needs Bottom padding to push text UP relative to center)
        expect(
          padding.bottom,
          greaterThan(0),
          reason: 'Superscript requires bottom padding to visually rise',
        );
        expect(padding.top, 0.0);

        // 4. Check Inner Text
        expect(paddingWidget.child, isA<Text>());
        final innerText = (paddingWidget.child! as Text).textSpan as TextSpan?;
        expect(innerText?.text, 'super');

        // Verify font size is reduced
        const expectedFontSize = DefaultStyles.scriptFontSizeFactor * 20;
        expect(innerText?.style?.fontSize, closeTo(expectedFontSize, 0.01));
      });

      test('integrates with surrounding text', () {
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('E = mc^2^', baseStyle, resolver);

        expect(spans.length, 2);

        // "E = mc"
        expect(spans.first, isA<TextSpan>());
        expect((spans.first as TextSpan).text, 'E = mc');

        // "^2^"
        expect(spans[1], isA<WidgetSpan>());
        final widgetSpan = spans[1] as WidgetSpan;
        final padding = widgetSpan.child as Padding;
        final innerText = (padding.child! as Text).textSpan as TextSpan?;
        expect(innerText?.text, '2');
      });
    });

    group('Subscript (~text~)', () {
      test('renders using Padding (Top) + Alignment.middle', () {
        const baseStyle = TextStyle(fontSize: 20, color: Color(0xFF000000));

        final spans = parser.parse('~sub~', baseStyle, resolver);

        expect(spans.first, isA<WidgetSpan>());
        final widgetSpan = spans.first as WidgetSpan;

        // CRITICAL check for Selection Sort Order Fix:
        expect(widgetSpan.alignment, PlaceholderAlignment.middle);

        expect(widgetSpan.child, isA<Padding>());
        final paddingWidget = widgetSpan.child as Padding;
        final padding = paddingWidget.padding as EdgeInsets;

        // Check Padding Direction (Subscript needs Top padding to push text DOWN relative to center)
        expect(
          padding.top,
          greaterThan(0),
          reason: 'Subscript requires top padding to visually sink',
        );
        expect(padding.bottom, 0.0);

        // Check Font Size
        final textSpan = (paddingWidget.child! as Text).textSpan as TextSpan?;
        const expectedFontSize = DefaultStyles.scriptFontSizeFactor * 20;
        expect(textSpan?.style?.fontSize, closeTo(expectedFontSize, 0.01));
      });

      test('H~2~O example renders correctly', () {
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('H~2~O', baseStyle, resolver);

        // Expect 3 spans: H, 2, O
        expect(spans.length, 3);
        expect((spans.first as TextSpan).text, 'H');
        expect(spans[1], isA<WidgetSpan>()); // The '2'
        expect((spans.last as TextSpan).text, 'O');
      });
    });

    group('Complex & Nested Formatting', () {
      test('Bold inside Superscript (^**bold**^)', () {
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('^**bold**^', baseStyle, resolver);

        expect(spans.first, isA<WidgetSpan>());
        final widgetSpan = spans.first as WidgetSpan;
        final padding = widgetSpan.child as Padding;
        final innerText = (padding.child! as Text).textSpan as TextSpan?;

        expect(innerText?.text, 'bold');
        expect(
          innerText?.style?.fontWeight,
          FontWeight.bold,
          reason: 'Inner text should retain bold formatting',
        );
        // Size should still be scaled
        expect(innerText?.style?.fontSize, closeTo(DefaultStyles.scriptFontSizeFactor * 16, 0.01));
      });

      test('Superscript inside Bold (**^super^**)', () {
        const baseStyle = TextStyle(fontSize: 16);

        // Input: **^super^**
        final spans = parser.parse('**^super^**', baseStyle, resolver);

        expect(spans.first, isA<WidgetSpan>());
        final widgetSpan = spans.first as WidgetSpan;
        final padding = widgetSpan.child as Padding;
        final innerText = (padding.child! as Text).textSpan as TextSpan?;

        expect(innerText?.text, 'super');
        expect(
          innerText?.style?.fontWeight,
          FontWeight.bold,
          reason: 'Script should inherit surrounding bold style',
        );
      });

      test('Adjacent Superscript and Subscript', () {
        final validSpans = parser.parse('^up^~down~', const TextStyle(), resolver);
        expect(validSpans.length, 2);

        // 1. Up (Padding Bottom)
        final upSpan = validSpans.first as WidgetSpan;
        final upPadding = (upSpan.child as Padding).padding as EdgeInsets;
        expect(upPadding.bottom, greaterThan(0));

        // 2. Down (Padding Top)
        final downSpan = validSpans.last as WidgetSpan;
        final downPadding = (downSpan.child as Padding).padding as EdgeInsets;
        expect(downPadding.top, greaterThan(0));
      });
    });

    group('Customization via TextfOptions', () {
      test('Superscript uses custom style from options', () {
        const customStyle = TextStyle(color: Color(0xFFF44336));
        final spans = parser.parse(
          '^super^',
          const TextStyle(color: Color(0xFF000000)),
          TextfStyleResolver(
            options: const TextfOptionsData(superscriptStyle: customStyle),
          ),
        );

        final widgetSpan = spans.first as WidgetSpan;
        final padding = widgetSpan.child as Padding;
        final innerText = (padding.child! as Text).textSpan as TextSpan?;

        expect(innerText?.style?.color, const Color(0xFFF44336));
      });
    });
  });
}
