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
      testWidgets('renders as WidgetSpan with negative vertical translation', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 20, color: Colors.black);

        final spans = parser.parse('^super^', mockContext, baseStyle);

        // 1. Check structure
        expect(spans.length, 1);
        expect(spans.first, isA<WidgetSpan>());

        final widgetSpan = spans.first as WidgetSpan;
        expect(widgetSpan.alignment, PlaceholderAlignment.baseline);
        expect(widgetSpan.baseline, TextBaseline.alphabetic);

        // 2. Check Transform (Translation)
        expect(widgetSpan.child, isA<Transform>());
        final transform = widgetSpan.child as Transform;
        final translation = transform.transform.getTranslation();

        // Y translation should be negative (move up)
        expect(translation.y, lessThan(0), reason: 'Superscript should move text up (negative Y)');
        expect(translation.x, 0);

        // 3. Check Inner Text Style (Font Size)
        expect(transform.child, isA<Text>());
        final richText = transform.child! as Text;
        final textSpan = richText.textSpan as TextSpan?;

        // Should be scaled down
        const expectedFontSize = DefaultStyles.scriptFontSizeFactor * 20;
        expect(textSpan?.style?.fontSize, closeTo(expectedFontSize, 0.01));
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
        final transform = widgetSpan.child as Transform;
        final innerText = (transform.child! as Text).textSpan! as TextSpan;
        expect(innerText.text, '2');
      });
    });

    group('Subscript (~text~)', () {
      testWidgets('renders as WidgetSpan with positive vertical translation', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 20, color: Colors.black);

        final spans = parser.parse('~sub~', mockContext, baseStyle);

        expect(spans.first, isA<WidgetSpan>());
        final widgetSpan = spans.first as WidgetSpan;

        expect(widgetSpan.child, isA<Transform>());
        final transform = widgetSpan.child as Transform;
        final translation = transform.transform.getTranslation();

        // Y translation should be positive (move down)
        expect(
          translation.y,
          greaterThan(0),
          reason: 'Subscript should move text down (positive Y)',
        );

        // Check Font Size
        final textSpan = (transform.child! as Text).textSpan! as TextSpan;
        const expectedFontSize = DefaultStyles.scriptFontSizeFactor * 20;
        expect(textSpan.style?.fontSize, closeTo(expectedFontSize, 0.01));
      });

      testWidgets('H~2~O example renders correctly', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('H~2~O', mockContext, baseStyle);

        expect(spans.length, 3);
        expect((spans.first as TextSpan).text, 'H');
        expect(spans[1], isA<WidgetSpan>()); // The '2'
        expect((spans[2] as TextSpan).text, 'O');
      });
    });

    group('Complex & Nested Formatting', () {
      testWidgets('Bold inside Superscript (^**bold**^)', (tester) async {
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 16);

        final spans = parser.parse('^**bold**^', mockContext, baseStyle);

        expect(spans.first, isA<WidgetSpan>());
        final widgetSpan = spans.first as WidgetSpan;
        final transform = widgetSpan.child as Transform;
        final innerText = (transform.child! as Text).textSpan! as TextSpan;

        expect(innerText.text, 'bold');
        expect(
          innerText.style?.fontWeight,
          FontWeight.bold,
          reason: 'Inner text should retain bold formatting',
        );
        // Size should still be scaled
        expect(innerText.style?.fontSize, closeTo(DefaultStyles.scriptFontSizeFactor * 16, 0.01));
      });

      testWidgets('Superscript inside Bold (**^super^**)', (tester) async {
        // This tests "Formatting outside Script".
        // The parser logic flushes text when styles change.
        // Since WidgetSpan breaks the text run, the bold style must be passed into the script's base style.
        await pumpTestApp(tester);
        const baseStyle = TextStyle(fontSize: 16);

        // Input: **Text ^Super^**
        final spans = parser.parse('**^super^**', mockContext, baseStyle);

        expect(spans.first, isA<WidgetSpan>());
        final widgetSpan = spans.first as WidgetSpan;
        final transform = widgetSpan.child as Transform;
        final innerText = (transform.child! as Text).textSpan! as TextSpan;

        expect(innerText.text, 'super');
        expect(
          innerText.style?.fontWeight,
          FontWeight.bold,
          reason: 'Script should inherit surrounding bold style',
        );
      });

      testWidgets('Adjacent Superscript and Subscript', (tester) async {
        await pumpTestApp(tester);

        final validSpans = parser.parse('^up^~down~', mockContext, const TextStyle());
        expect(validSpans.length, 2);

        // 1. Up
        final upSpan = validSpans.first as WidgetSpan;
        final upTrans = (upSpan.child as Transform).transform.getTranslation();
        expect(upTrans.y, lessThan(0));

        // 2. Down
        final downSpan = validSpans[1] as WidgetSpan;
        final downTrans = (downSpan.child as Transform).transform.getTranslation();
        expect(downTrans.y, greaterThan(0));
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
        final transform = widgetSpan.child as Transform;
        final innerText = (transform.child! as Text).textSpan! as TextSpan;

        expect(innerText.style?.color, Colors.red);
      });
    });
  });
}
