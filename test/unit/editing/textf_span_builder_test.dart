// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword
// ignore_for_file: prefer-match-file-name

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/textf_span_builder.dart';
import 'package:textf/textf.dart';

/// Extension to access [TextSpan.text] on [InlineSpan] for test assertions.
/// Returns `null` for non-[TextSpan] spans (e.g. [WidgetSpan]).
extension _TestTextAccess on InlineSpan {
  String? get text => this is TextSpan ? (this as TextSpan).text : null;
}

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

    /// Verifies that the total character-slot count of all spans equals the
    /// original text length. This is the critical invariant for cursor
    /// positioning in text fields.
    ///
    /// Each [TextSpan] contributes its `text.length` slots; each [WidgetSpan]
    /// contributes exactly 1 slot.
    int totalSpanLength(List<InlineSpan> spans) {
      var sum = 0;
      for (final span in spans) {
        if (span is TextSpan) {
          sum += span.text?.length ?? 0;
        } else if (span is WidgetSpan) {
          sum += 1;
        }
      }
      return sum;
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
      testWidgets('always emits per-character WidgetSpan with vertical offset', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // No cursorPosition → always-visible mode; content still uses WidgetSpan
        // for vertical displacement. "super" = 5 chars → 5 WidgetSpans.
        final spans = builder.build('^super^', testContext, baseStyle);
        // ^ (TextSpan) + 5 × WidgetSpan + ^ (TextSpan) = 7 spans
        expect(spans.length, 7);
        expect(spans.first, isA<TextSpan>());
        expect(spans.first.text, '^'); // visible opening marker
        // Content spans are WidgetSpan with Padding + Text
        final contentSpans = spans.sublist(1, 6).cast<WidgetSpan>();
        for (final ws in contentSpans) {
          expect(ws.child, isA<Padding>());
          final padding = ws.child as Padding;
          expect(padding.child, isA<Text>());
          // Superscript: bottom padding pushes text up
          final edgeInsets = padding.padding as EdgeInsets;
          expect(edgeInsets.bottom, greaterThan(0));
        }
        expect(spans.last, isA<TextSpan>());
        expect(spans.last.text, '^'); // visible closing marker
      });
    });

    group('Subscript Formatting', () {
      testWidgets('always emits per-character WidgetSpan with vertical offset', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // "sub" = 3 chars → ^ + 3 WidgetSpans + ~ = 5 spans
        final spans = builder.build('~sub~', testContext, baseStyle);
        expect(spans.length, 5);
        expect(spans.first, isA<TextSpan>());
        expect(spans.first.text, '~');
        final contentSpans = spans.sublist(1, 4).cast<WidgetSpan>();
        for (final ws in contentSpans) {
          final edgeInsets = (ws.child as Padding).padding as EdgeInsets;
          // Subscript: top padding pushes text down
          expect(edgeInsets.top, greaterThan(0));
          expect(edgeInsets.bottom, 0);
        }
        expect(spans.last, isA<TextSpan>());
        expect(spans.last.text, '~');
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
        final allText = spans.whereType<TextSpan>().map((s) => s.text ?? '').join();
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

    // -----------------------------------------------------------------
    // Superscript/Subscript Preview Mode
    //
    // When cursorPosition is set, markerOpacity is 0, and the cursor is
    // outside the script span, the builder emits per-character WidgetSpans
    // with vertical displacement instead of TextSpans.
    // -----------------------------------------------------------------
    group('Superscript/Subscript Preview Mode', () {
      testWidgets('superscript emits per-character WidgetSpans when cursor outside',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "E=mc^2^" — cursor at 0 (outside the ^2^ span)
        final spans = builder.build(
          'E=mc^2^',
          testContext,
          baseStyle,
          cursorPosition: 0,
        );
        // "E=mc" (TextSpan) + ^ (WidgetSpan shrink) + 2 (WidgetSpan with padding)
        //   + ^ (WidgetSpan shrink)
        // Find the WidgetSpans for "2"
        final widgetSpans = spans.whereType<WidgetSpan>().toList();
        // 2 hidden markers (^ ^) + 1 content char (2) = 3 WidgetSpans
        expect(widgetSpans.length, 3);

        // The content WidgetSpan should have Padding > Text
        final contentWidget = widgetSpans[1]; // the "2" char
        expect(contentWidget.child, isA<Padding>());
        final padding = contentWidget.child as Padding;
        final textWidget = padding.child! as Text;
        expect(textWidget.data, '2');
        expect(textWidget.textScaler, TextScaler.noScaling);

        // Alignment should be middle for proper vertical centering
        expect(contentWidget.alignment, PlaceholderAlignment.middle);
      });

      testWidgets('subscript emits per-character WidgetSpans when cursor outside', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "H~2~O" — cursor at 0 (outside the ~2~ span)
        final spans = builder.build(
          'H~2~O',
          testContext,
          baseStyle,
          cursorPosition: 0,
        );
        final widgetSpans = spans.whereType<WidgetSpan>().toList();
        // 2 hidden markers (~ ~) + 1 content char (2) = 3 WidgetSpans
        expect(widgetSpans.length, 3);

        // The content WidgetSpan should use top padding (pushes down)
        final contentWidget = widgetSpans[1];
        final padding = contentWidget.child as Padding;
        final edgeInsets = padding.padding as EdgeInsets;
        expect(edgeInsets.top, greaterThan(0));
        expect(edgeInsets.bottom, 0);
      });

      testWidgets('superscript uses bottom padding (pushes up)', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        final spans = builder.build(
          'E=mc^2^',
          testContext,
          baseStyle,
          cursorPosition: 0,
        );
        final widgetSpans = spans.whereType<WidgetSpan>().toList();
        final contentWidget = widgetSpans[1]; // the "2" char
        final padding = contentWidget.child as Padding;
        final edgeInsets = padding.padding as EdgeInsets;
        expect(edgeInsets.bottom, greaterThan(0));
        expect(edgeInsets.top, 0);
      });

      testWidgets('character count invariant preserved in preview mode', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        const input = 'E=mc^2^';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          cursorPosition: 0,
        );
        expect(totalSpanLength(spans), input.length);
      });

      testWidgets('cursor inside span: markers TextSpan (visible), content WidgetSpan',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // "^super^" — cursor at 3 (inside). Markers are active (visible TextSpan),
        // content is always WidgetSpan for vertical displacement.
        final spans = builder.build(
          '^super^',
          testContext,
          baseStyle,
          cursorPosition: 3,
        );
        // ^ (TextSpan) + 5 WidgetSpan content + ^ (TextSpan) = 7
        expect(spans.length, 7);
        expect(spans.first, isA<TextSpan>()); // visible opening marker
        expect(spans.first.text, '^');
        for (final span in spans.sublist(1, 6)) {
          expect(span, isA<WidgetSpan>()); // content always WidgetSpan
        }
        expect(spans.last, isA<TextSpan>()); // visible closing marker
        expect(spans.last.text, '^');
      });

      testWidgets('cursor outside: markers instantly hidden WidgetSpan, content WidgetSpan',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // Cursor outside: markers become hidden SizedBox.shrink WidgetSpans.
        final spans = builder.build(
          '^super^',
          testContext,
          baseStyle,
          cursorPosition: 100,
        );
        // ^ (shrink WS) + 5 content WS + ^ (shrink WS) = 7 WidgetSpans
        expect(spans.length, 7);
        for (final span in spans) {
          expect(span, isA<WidgetSpan>());
        }
      });

      testWidgets('nested ^**bold**^ in preview mode uses all WidgetSpans', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "^**b**^" — cursor at 100 (outside [0,7]), opacity 0 → preview mode
        final spans = builder.build(
          '^**b**^',
          testContext,
          baseStyle,
          cursorPosition: 100,
        );
        // ^ (shrink) + ** (shrink×2) + b (WidgetSpan content) + ** (shrink×2) + ^ (shrink)
        // = 7 WidgetSpans total (1 + 2 + 1 + 2 + 1)
        expect(spans.length, 7);
        for (final span in spans) {
          expect(span, isA<WidgetSpan>());
        }
        // Character count must still match
        expect(totalSpanLength(spans), '^**b**^'.length);
      });

      testWidgets('multi-char superscript content emits one WidgetSpan per char', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "x^abc^y" — 3 content chars → 3 content WidgetSpans
        final spans = builder.build(
          'x^abc^y',
          testContext,
          baseStyle,
          cursorPosition: 0,
        );
        // x (TextSpan) + ^ (shrink) + a (WS) + b (WS) + c (WS) + ^ (shrink) + y (TextSpan)
        expect(spans.length, 7);
        expect(spans.first, isA<TextSpan>()); // "x"
        expect(spans[1], isA<WidgetSpan>()); // ^ (shrink)
        expect(spans[2], isA<WidgetSpan>()); // a
        expect(spans[3], isA<WidgetSpan>()); // b
        expect(spans[4], isA<WidgetSpan>()); // c
        expect(spans[5], isA<WidgetSpan>()); // ^ (shrink)
        expect(spans[6], isA<TextSpan>()); // "y"

        // Verify each content WidgetSpan has the correct character
        for (var idx = 2; idx <= 4; idx++) {
          final ws = spans[idx] as WidgetSpan;
          final padding = ws.child as Padding;
          final text = padding.child! as Text;
          expect(text.data, 'abc'[idx - 2]);
        }

        expect(totalSpanLength(spans), 'x^abc^y'.length);
      });

      testWidgets('hidden marker WidgetSpans use SizedBox.shrink', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        final spans = builder.build(
          '^x^',
          testContext,
          baseStyle,
          cursorPosition: 100,
        );
        // ^ (shrink) + x (content WS) + ^ (shrink) = 3 WidgetSpans
        expect(spans.length, 3);
        // Opening marker: SizedBox.shrink
        final openMarker = spans.first as WidgetSpan;
        expect(openMarker.child, isA<SizedBox>());
        final sizedBox = openMarker.child as SizedBox;
        expect(sizedBox.width, 0);
        expect(sizedBox.height, 0);
      });

      testWidgets('no cursorPosition: markers TextSpan, content WidgetSpan', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (_) => Container()));
        const baseStyle = TextStyle(fontSize: 16);
        // No cursorPosition → always-visible mode; content still uses WidgetSpan
        // for vertical displacement; markers are visible TextSpan.
        final spans = builder.build(
          '^super^',
          testContext,
          baseStyle,
        );
        // ^ (TextSpan) + 5 WidgetSpan + ^ (TextSpan) = 7
        expect(spans.length, 7);
        expect(spans.first, isA<TextSpan>());
        for (final span in spans.sublist(1, 6)) {
          expect(span, isA<WidgetSpan>());
        }
        expect(spans.last, isA<TextSpan>());
      });
    });
  });
}
