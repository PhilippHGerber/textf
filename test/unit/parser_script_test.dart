// ignore_for_file: avoid-late-keyword, avoid-non-null-assertion, no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/widgets/textf_options.dart';

void main() {
  group('Script (Superscript/Subscript) Parsing Tests', () {
    late TextfParser parser;
    late BuildContext mockContext;

    setUp(() {
      parser = TextfParser();
    });

    // Helper to build a context with optional TextfOptions
    Future<void> pumpTestApp(
      WidgetTester tester, {
      TextfOptions? options,
      TextStyle? defaultStyle,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              mockContext = context;
              // Capture context inside options if provided
              if (options != null) {
                return TextfOptions(
                  // Pass through all properties from the test options
                  boldStyle: options.boldStyle,
                  italicStyle: options.italicStyle,
                  superscriptStyle: options.superscriptStyle,
                  subscriptStyle: options.subscriptStyle,
                  child: Builder(
                    builder: (innerContext) {
                      mockContext = innerContext;
                      return const SizedBox();
                    },
                  ),
                );
              }
              // Capture context with specific DefaultTextStyle if provided
              if (defaultStyle != null) {
                return DefaultTextStyle(
                  style: defaultStyle,
                  child: Builder(
                    builder: (innerContext) {
                      mockContext = innerContext;
                      return const SizedBox();
                    },
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      );
    }

    group('Superscript (^text^)', () {
      testWidgets('renders using Padding (Bottom) + Alignment.middle', (tester) async {
        await pumpTestApp(tester);
        // Use a known font size to verify padding calculation exists
        const baseStyle = TextStyle(fontSize: 20, color: Colors.black);

        final spans = parser.parse('^super^', mockContext, baseStyle);

        // 1. Check structure
        expect(spans.length, 1);
        expect(spans.first, isA<WidgetSpan>());

        final widgetSpan = spans.first as WidgetSpan;

        // CRITICAL check for Selection Sort Order Fix:
        expect(
          widgetSpan.alignment,
          PlaceholderAlignment.middle,
          reason:
              'Must use Alignment.middle to keep widget anchored to line center for correct selection sorting',
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

      testWidgets('integrates with surrounding text', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('E = mc^2^', mockContext, baseStyle);

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
      testWidgets('renders using Padding (Top) + Alignment.middle', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 20, color: Colors.black);

        final spans = parser.parse('~sub~', mockContext, baseStyle);

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

      testWidgets('H~2~O example renders correctly', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('H~2~O', mockContext, baseStyle);

        // Expect 3 spans: H, 2, O
        expect(spans.length, 3);
        expect((spans.first as TextSpan).text, 'H');
        expect(spans[1], isA<WidgetSpan>()); // The '2'
        expect((spans.last as TextSpan).text, 'O');
      });
    });

    group('Complex & Nested Formatting', () {
      testWidgets('Bold inside Superscript (^**bold**^)', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('^**bold**^', mockContext, baseStyle);

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

      testWidgets('Superscript inside Bold (**^super^**)', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 16);

        // Input: **^super^**
        final spans = parser.parse('**^super^**', mockContext, baseStyle);

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

      testWidgets('Adjacent Superscript and Subscript', (tester) async {
        await pumpTestApp(tester);

        final validSpans = parser.parse('^up^~down~', mockContext, const TextStyle());
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
      testWidgets('Superscript uses custom style from options', (tester) async {
        const customStyle = TextStyle(color: Colors.red);
        await pumpTestApp(
          tester,
          options: const TextfOptions(
            superscriptStyle: customStyle,
            child: SizedBox(),
          ),
        );

        final spans = parser.parse('^super^', mockContext, const TextStyle(color: Colors.black));

        final widgetSpan = spans.first as WidgetSpan;
        final padding = widgetSpan.child as Padding;
        final innerText = (padding.child! as Text).textSpan as TextSpan?;

        expect(innerText?.style?.color, Colors.red);
      });
    });
  });
}
