// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword
// ignore_for_file: prefer-match-file-name

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/marker_render_mode.dart';
import 'package:textf/src/editing/textf_span_builder.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/textf.dart';

/// Extension to access [TextSpan.text] on [InlineSpan] for test assertions.
/// Returns `null` for non-[TextSpan] spans (e.g. [WidgetSpan]).
extension _TestTextAccess on InlineSpan {
  String? get text => this is TextSpan ? (this as TextSpan).text : null;
}

void main() {
  group('TextfSpanBuilder', () {
    late TextfSpanBuilder builder;
    final resolver = TextfStyleResolver.withState(options: null);

    setUp(() {
      builder = TextfSpanBuilder();
    });

    /// Verifies that the total cursor-slot count of all spans equals the
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
      test('empty text returns empty list', () {
        final spans = builder.build('', const TextStyle(), resolver);
        expect(spans, isEmpty);
      });

      test('plain text returns single TextSpan', () {
        final spans = builder.build('hello world', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect(spans.first.text, 'hello world');
      });
    });

    test('nested formatting keeps heading style', () {
      final spans = builder.build('# **Title**', const TextStyle(fontSize: 14), resolver);

      final titleSpan = spans.whereType<TextSpan>().firstWhere((s) => s.text!.contains('Title'));
      expect(titleSpan.style!.fontSize, 28.0);
      expect(titleSpan.style!.fontWeight, FontWeight.bold);
    });

    test('heading marker uses heading size', () {
      final spans = builder.build('# Title', const TextStyle(fontSize: 14), resolver);

      final markerSpan = spans.whereType<TextSpan>().first;
      expect(markerSpan.text, '# ');
      expect(markerSpan.style!.fontSize, 28.0);
    });

    group('Cursor-Slot Count Invariant', () {
      test('bold text preserves cursor-slot count', () {
        const input = '**bold**';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('italic text preserves cursor-slot count', () {
        const input = '*italic*';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('mixed formatting preserves cursor-slot count', () {
        const input = 'hello **bold** and *italic* `code` world';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('link text preserves cursor-slot count', () {
        const input = '[click here](https://example.com)';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('placeholder text preserves cursor-slot count', () {
        const input = 'hello {icon} world';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('nested formatting preserves cursor-slot count', () {
        const input = '**bold *italic* bold**';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('all formatting types preserve cursor-slot count', () {
        const input = '**b** *i* ~~s~~ ++u++ ==h== `c` ^sup^ ~sub~ [l](u) {p}';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });
    });

    group('Bold Formatting', () {
      test('renders markers dimmed and content bold', () {
        final spans = builder.build('**bold**', const TextStyle(), resolver);
        // 3 spans: ** (dimmed) + bold (styled) + ** (dimmed)
        expect(spans.length, 3);
        expect(spans.first.text, '**');
        expect(spans[1].text, 'bold');
        expect(spans[1].style?.fontWeight, FontWeight.bold);
        expect(spans[2].text, '**');
      });

      test('mixed bold and plain text', () {
        final spans = builder.build('hello **bold** world', const TextStyle(), resolver);
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
      test('renders markers dimmed and content italic', () {
        final spans = builder.build('*italic*', const TextStyle(), resolver);
        expect(spans.length, 3);
        expect(spans.first.text, '*');
        expect(spans[1].text, 'italic');
        expect(spans[1].style?.fontStyle, FontStyle.italic);
        expect(spans[2].text, '*');
      });
    });

    group('Bold-Italic Formatting', () {
      test('applies both bold and italic', () {
        final spans = builder.build('***both***', const TextStyle(), resolver);
        expect(spans.length, 3);
        expect(spans.first.text, '***');
        expect(spans[1].text, 'both');
        expect(spans[1].style?.fontWeight, FontWeight.bold);
        expect(spans[1].style?.fontStyle, FontStyle.italic);
        expect(spans[2].text, '***');
      });
    });

    group('Strikethrough Formatting', () {
      test('applies line-through decoration', () {
        final spans = builder.build('~~strike~~', const TextStyle(), resolver);
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
      test('applies underline decoration', () {
        final spans = builder.build('++underline++', const TextStyle(), resolver);
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
      test('applies highlight background', () {
        final spans = builder.build('==highlight==', const TextStyle(), resolver);
        expect(spans.length, 3);
        expect(spans.first.text, '==');
        expect(spans[1].text, 'highlight');
        expect(spans[1].style?.backgroundColor, isNotNull);
        expect(spans[2].text, '==');
      });
    });

    group('Code Formatting', () {
      test('applies monospace font', () {
        final spans = builder.build('`code`', const TextStyle(), resolver);
        expect(spans.length, 3);
        expect(spans.first.text, '`');
        expect(spans[1].text, 'code');
        expect(spans[1].style?.fontFamily, 'monospace');
        expect(spans[2].text, '`');
      });
    });

    group('Superscript Formatting', () {
      test('always emits per-character WidgetSpan with vertical offset', () {
        const baseStyle = TextStyle(fontSize: 16);
        // Default always mode; content still uses WidgetSpan
        // for vertical displacement. "super" = 5 chars → 5 WidgetSpans.
        final spans = builder.build('^super^', baseStyle, resolver);
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
      test('always emits per-character WidgetSpan with vertical offset', () {
        const baseStyle = TextStyle(fontSize: 16);
        // "sub" = 3 chars → ^ + 3 WidgetSpans + ~ = 5 spans
        final spans = builder.build('~sub~', baseStyle, resolver);
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
      test('renders link with all characters visible', () {
        final spans = builder.build(
          '[click here](https://example.com)',
          const TextStyle(),
          resolver,
        );
        // Should produce 5 spans: [ , link text, ]( , url, )
        expect(spans.length, 5);
        expect(spans.first.text, '[');
        expect(spans[1].text, 'click here');
        expect(spans[2].text, '](');
        expect(spans[3].text, 'https://example.com');
        expect(spans[4].text, ')');
      });

      test('link text gets link styling', () {
        final spans = builder.build('[link](url)', const TextStyle(), resolver);
        // The link text span should have underline decoration (link style)
        expect(
          spans[1].style?.decoration,
          TextDecoration.underline,
        );
      });

      test('incomplete link renders as plain text', () {
        final spans = builder.build('[not a link', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect(spans.first.text, '[not a link');
      });

      test('plain text link still renders as single content span', () {
        final spans = builder.build('[click here](url)', const TextStyle(), resolver);
        // Simple link: [ + text + ]( + url + ) — 5 spans
        expect(spans.length, 5);
        expect(spans[1].text, 'click here');
      });

      group('Nested formatting in link text', () {
        test('nested bold renders correctly with link+bold style', () {
          // [**bold**](url) = 15 chars
          // Spans: [ | ** | bold | ** | ]( | url | )
          final spans = builder.build('[**bold**](url)', const TextStyle(), resolver);

          final totalChars = spans.whereType<TextSpan>().fold(
            0,
            (n, s) => n + (s.text?.length ?? 0),
          );
          expect(totalChars, 15);

          // spans[0] = '[', spans[1] = '**', spans[2] = 'bold', spans[3] = '**',
          // spans[4] = '](', spans[5] = 'url', spans[6] = ')'
          expect(spans.length, 7);
          final boldSpan = spans[2] as TextSpan;
          expect(boldSpan.text, 'bold');
          expect(boldSpan.style?.fontWeight, FontWeight.bold);
          expect(boldSpan.style?.decoration, TextDecoration.underline);
        });

        test('nested italic renders correctly with link+italic style', () {
          // [_italic_](url) = 15 chars
          final spans = builder.build('[_italic_](url)', const TextStyle(), resolver);

          final totalChars = spans.whereType<TextSpan>().fold(
            0,
            (n, s) => n + (s.text?.length ?? 0),
          );
          expect(totalChars, 15);

          expect(spans.length, 7);
          final italicSpan = spans[2] as TextSpan;
          expect(italicSpan.text, 'italic');
          expect(italicSpan.style?.fontStyle, FontStyle.italic);
          expect(italicSpan.style?.decoration, TextDecoration.underline);
        });

        test('mixed nested formatting maintains cursor-slot invariant', () {
          const input = '[**bold** plain](url)';
          final spans = builder.build(input, const TextStyle(), resolver);

          final totalChars = spans.whereType<TextSpan>().fold(
            0,
            (n, s) => n + (s.text?.length ?? 0),
          );
          expect(totalChars, input.length);

          // Bold content span should have bold + underline
          final boldContentSpan = spans[2] as TextSpan;
          expect(boldContentSpan.text, 'bold');
          expect(boldContentSpan.style?.fontWeight, FontWeight.bold);
          expect(boldContentSpan.style?.decoration, TextDecoration.underline);

          // Plain content after closing ** should have link style only
          final plainSpan = spans[4] as TextSpan;
          expect(plainSpan.text, ' plain');
          expect(plainSpan.style?.fontWeight, isNot(FontWeight.bold));
          expect(plainSpan.style?.decoration, TextDecoration.underline);
        });

        test('unpaired markers in link text render as literal text', () {
          // [**unpaired](url) — ** is not closed inside link text
          const input = '[**unpaired](url)';
          final spans = builder.build(input, const TextStyle(), resolver);

          final totalChars = spans.whereType<TextSpan>().fold(
            0,
            (n, s) => n + (s.text?.length ?? 0),
          );
          expect(totalChars, input.length);

          // Link text span should contain literal ** (not styled as bold marker)
          final linkTextSpan = spans[1] as TextSpan;
          expect(linkTextSpan.text, contains('**'));
        });
      });
    });

    group('Placeholder Handling', () {
      test('renders placeholder as literal text', () {
        final spans = builder.build('hello {icon} world', const TextStyle(), resolver);
        // The {icon} should be rendered as plain text
        final allText = spans.whereType<TextSpan>().map((s) => s.text ?? '').join();
        expect(allText, 'hello {icon} world');
      });
    });

    group('Nested Formatting', () {
      test('bold with nested italic', () {
        final spans = builder.build('**bold *italic* bold**', const TextStyle(), resolver);
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

      test('italic outer with nested bold — outer style persists after inner closes', () {
        // Stack trace: push italic → push bold → removeLast (bold) → removeLast (italic).
        // After ** closes, only italic remains on the stack so ' italic' is italic-only.
        final spans = builder.build('_italic **bold** italic_', const TextStyle(), resolver);
        // _ + 'italic ' + ** + 'bold' + ** + ' italic' + _
        expect(spans.length, 7);

        expect(spans.first.text, '_'); // opening italic marker
        expect(spans[1].text, 'italic ');
        expect(spans[1].style?.fontStyle, FontStyle.italic);
        expect(spans[1].style?.fontWeight, isNot(FontWeight.bold));

        expect(spans[2].text, '**'); // opening bold marker
        expect(spans[3].text, 'bold');
        expect(spans[3].style?.fontStyle, FontStyle.italic);
        expect(spans[3].style?.fontWeight, FontWeight.bold);

        expect(spans[4].text, '**'); // closing bold marker
        expect(spans[5].text, ' italic');
        expect(spans[5].style?.fontStyle, FontStyle.italic); // italic still active
        expect(spans[5].style?.fontWeight, isNot(FontWeight.bold)); // bold is gone

        expect(spans[6].text, '_'); // closing italic marker
      });

      test('overlapping markers (cross-nesting) render as unpaired plain text', () {
        // **_text**_ — ** wants to pair at [0,3], _ wants to pair at [1,4].
        // These overlap; pair validation rejects both pairs.
        // All markers are unpaired → rendered as literal characters.
        const input = '**_text**_';
        final spans = builder.build(input, const TextStyle(), resolver);

        final allText = spans.whereType<TextSpan>().map((s) => s.text ?? '').join();
        expect(allText, input);
        expect(totalSpanLength(spans), input.length);
        for (final span in spans.whereType<TextSpan>()) {
          expect(span.style?.fontWeight, isNot(FontWeight.bold));
          expect(span.style?.fontStyle, isNot(FontStyle.italic));
        }
      });

      test('nested bold+italic inside link text — stack pop order correct', () {
        // [**bold** plain](url): the link re-tokenizer sees ** as a valid pair.
        // Stack inside _processNestedLinkText: push bold → removeLast (bold).
        // 'plain' after ** closes should have link style only (no bold).
        const input = '[**bold** plain](url)';
        final spans = builder.build(input, const TextStyle(), resolver);

        expect(totalSpanLength(spans), input.length);

        // Find 'bold' span — must have bold + underline (link inherits underline).
        final boldSpan = spans.whereType<TextSpan>().firstWhere((s) => s.text == 'bold');
        expect(boldSpan.style?.fontWeight, FontWeight.bold);
        expect(boldSpan.style?.decoration, TextDecoration.underline);

        // Find ' plain' span — bold must be gone after the closing ** popped the stack.
        final plainSpan = spans.whereType<TextSpan>().firstWhere((s) => s.text == ' plain');
        expect(plainSpan.style?.fontWeight, isNot(FontWeight.bold));
        expect(plainSpan.style?.decoration, TextDecoration.underline); // still a link
      });
    });

    group('Cursor slots in link text', () {
      const baseStyle = TextStyle(fontSize: 14, color: Color(0xFF000000));

      /// Returns the style of the [TextSpan] that supplies the cursor slot at
      /// source [offset], or `null` when a [WidgetSpan] supplies it.
      TextStyle? styleAt(List<InlineSpan> spans, int offset) {
        var slot = 0;
        for (final span in spans) {
          final int width = span is TextSpan ? span.text?.length ?? 0 : 1;
          if (offset < slot + width) return span is TextSpan ? span.style : null;
          slot += width;
        }
        throw RangeError.index(offset, spans, 'offset');
      }

      /// Link style and marker style of a plain `[x](u)` link: the reference
      /// the link-text characters below are compared against.
      ({TextStyle link, TextStyle marker}) referenceStyles() {
        final spans = builder.build('[x](u)', baseStyle, resolver);
        return (link: styleAt(spans, 1)!, marker: styleAt(spans, 0)!);
      }

      void expectLinkStyledLiterals(String input, List<int> offsets) {
        final spans = builder.build(input, baseStyle, resolver);
        final styles = referenceStyles();

        expect(totalSpanLength(spans), input.length);
        expect(spans.map((s) => s.text ?? '').join(), input);
        expect(spans.whereType<WidgetSpan>(), isEmpty, reason: 'no rule or script widget');
        for (final span in spans.whereType<TextSpan>()) {
          expect(span.style?.fontSize, 14.0, reason: 'no heading-sized span in "$input"');
        }
        for (final offset in offsets) {
          expect(
            styleAt(spans, offset),
            styles.link,
            reason: '"${input[offset]}" at $offset in "$input" must carry the link style',
          );
          expect(styleAt(spans, offset), isNot(styles.marker));
        }
      }

      test('heading opening run in link text is link-styled text', () {
        // [# a](u): `#`, ` ` and `a` are link text.
        expectLinkStyledLiterals('[# a](u)', [1, 2, 3]);
      });

      test('thematic-break run in link text is link-styled text', () {
        expectLinkStyledLiterals('[---](u)', [1, 2, 3]);
      });

      test('nested link syntax in link text is link-styled text', () {
        // [foo [bar](/uri)](/uri): the inner `[`, `](`, `)` sit at 5, 9-10, 15.
        expectLinkStyledLiterals('[foo [bar](/uri)](/uri)', [5, 9, 10, 15]);
      });

      test('paired markers and escapes stay dimmed; text, unpaired markers and '
          'placeholders stay link-styled', () {
        // Offsets: [0 **1-2 b3 **4-5 \6 *7 {k}8-10 *11 ]12
        const input = r'[**b**\*{k}*](u)';
        final spans = builder.build(input, baseStyle, resolver);
        final styles = referenceStyles();

        expect(totalSpanLength(spans), input.length);
        for (final offset in [1, 2, 4, 5, 6]) {
          expect(styleAt(spans, offset), styles.marker, reason: 'offset $offset dimmed');
        }
        for (final offset in [7, 8, 9, 10, 11]) {
          expect(styleAt(spans, offset), styles.link, reason: 'offset $offset link-styled');
        }
        expect(styleAt(spans, 3)?.fontWeight, FontWeight.bold);
        expect(styleAt(spans, 3)?.decoration, TextDecoration.underline);
      });
    });

    group('Escape Characters (editing mode)', () {
      test('escaped marker preserves cursor-slot invariant', () {
        // Raw text: \*not italic* (13 chars)
        // The \ must occupy a slot so total equals 13.
        const input = r'\*not italic*';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('escaped bold marker preserves cursor-slot invariant', () {
        // Raw: a\**b** — escape stops the ** from being a bold marker opener.
        const input = r'a\**b**';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('escaped backslash preserves cursor-slot invariant', () {
        // Raw: \\ (2 chars) → editing mode emits \\ as a 2-char token.
        const input = r'\\';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });

      test('escaped marker in link text preserves cursor-slot invariant', () {
        // [a\*b](url) — the link-text portion is 4 chars (a \ * b).
        const input = r'[a\*b](url)';
        final spans = builder.build(input, const TextStyle(), resolver);
        expect(totalSpanLength(spans), input.length);
      });
    });

    group('Unpaired Markers', () {
      test('single asterisk renders as plain text', () {
        final spans = builder.build('hello * world', const TextStyle(), resolver);
        expect(spans.length, 1);
        expect(spans.first.text, 'hello * world');
      });
    });

    group('Marker Style', () {
      test('markers have dimmed opacity', () {
        const baseColor = Color(0xFF000000);
        final spans = builder.build('**bold**', const TextStyle(color: baseColor), resolver);
        // The marker spans should have reduced opacity
        final markerColor = spans.first.style?.color;
        expect(markerColor, isNotNull);
        expect(markerColor!.a, lessThan(1.0));
      });
    });

    group('TextfOptions Integration', () {
      test('respects TextfOptions bold style', () {
        final optionsResolver = TextfStyleResolver.withState(
          options: const TextfOptionsData(
            boldStyle: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFFF44336),
            ),
          ),
        );
        final spans = builder.build('**bold**', const TextStyle(), optionsResolver);
        // spans[1] is the content span (between markers)
        expect(spans[1].style?.fontWeight, FontWeight.w900);
        expect(spans[1].style?.color, const Color(0xFFF44336));
      });
    });

    group('Cursor Position (Smart Hide)', () {
      // Input: **bold** (positions 0-7)
      // Opening marker ** at positions 0-1
      // Content "bold" at positions 2-5
      // Closing marker ** at positions 6-7

      test('cursor inside span shows active markers', () {
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Cursor at position 3 (inside "bold")
        final spans = builder.build(
          '**bold**',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(3),
        );
        expect(spans.length, 3);
        // Opening marker should be dimmed (active, not hidden)
        final openMarkerColor = spans.first.style?.color;
        expect(openMarkerColor, isNotNull);
        expect(openMarkerColor!.a, greaterThan(0));
        expect(openMarkerColor.a, lessThan(1.0));
      });

      test('cursor outside span hides inactive markers', () {
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Input: "hi **bold** bye" — cursor at position 0 ("h")
        final spans = builder.build(
          'hi **bold** bye',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        // Find the opening ** marker (should be hidden)
        final openMarker = spans[1]; // "hi " is spans[0], "**" is spans[1]
        expect(openMarker.text, '**');
        expect(openMarker.style?.color?.a, 0);
        expect(openMarker.style?.fontSize, lessThan(1));
      });

      test('cursor on opening marker shows markers', () {
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Cursor at position 0 (on the opening **)
        final spans = builder.build(
          '**bold**',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        // Cursor is on the opening marker itself — should be active
        final openMarkerColor = spans.first.style?.color;
        expect(openMarkerColor!.a, greaterThan(0));
      });

      test('cursor on closing marker shows markers', () {
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Cursor at position 7 (end of closing **)
        final spans = builder.build(
          '**bold**',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(7),
        );
        final closeMarkerColor = spans[2].style?.color;
        expect(closeMarkerColor!.a, greaterThan(0));
      });

      test('preserves cursor-slot count with MarkerRenderMode.active', () {
        const input = 'hi **bold** and *italic* bye';
        final spans = builder.build(
          input,
          const TextStyle(),
          resolver,
          renderMode: const MarkerRenderMode.active(5),
        );
        expect(totalSpanLength(spans), input.length);
      });

      test('link markers hidden when cursor outside', () {
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Input: "hi [link](url) bye" — cursor at position 0
        final spans = builder.build(
          'hi [link](url) bye',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        // Find the "[" marker (should be hidden)
        final bracketSpan = spans[1]; // "hi " is spans[0], "[" is spans[1]
        expect(bracketSpan.text, '[');
        expect(bracketSpan.style?.color?.a, 0);
      });

      test('link markers visible when cursor inside', () {
        const baseStyle = TextStyle(color: Color(0xFF000000));
        // Input: "[link](url)" — cursor at position 2 (inside "link")
        final spans = builder.build(
          '[link](url)',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(2),
        );
        // "[" marker should be active (dimmed, not hidden)
        final bracketColor = spans.first.style?.color;
        expect(bracketColor!.a, greaterThan(0));
      });

      test('heading marker hidden when cursor outside heading line', () {
        const baseStyle = TextStyle(color: Color(0xFF000000), fontSize: 14);
        final spans = builder.build(
          '# Title\nbody',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(10),
        );

        // Cursor at index 10 is in "body" (line 2), outside the heading line,
        // so the marker is fully hidden via the O(1) lineEndPosition check.
        final markerSpan = spans.whereType<TextSpan>().first;
        expect(markerSpan.text, '# ');
        expect(markerSpan.style!.color!.a, 0);
        expect(markerSpan.style!.fontSize, lessThan(1));
      });
    });

    // -----------------------------------------------------------------
    // Superscript/Subscript Preview Mode
    //
    // When renderMode is active and the cursor is outside the script span,
    // the builder emits per-character WidgetSpans with vertical displacement
    // instead of TextSpans.
    // -----------------------------------------------------------------
    group('Superscript/Subscript Preview Mode', () {
      test('superscript emits per-character WidgetSpans when cursor outside', () {
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "E=mc^2^" — cursor at 0 (outside the ^2^ span)
        final spans = builder.build(
          'E=mc^2^',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
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

      test('subscript emits per-character WidgetSpans when cursor outside', () {
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "H~2~O" — cursor at 0 (outside the ~2~ span)
        final spans = builder.build(
          'H~2~O',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
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

      test('superscript uses bottom padding (pushes up)', () {
        const baseStyle = TextStyle(fontSize: 16);
        final spans = builder.build(
          'E=mc^2^',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        final widgetSpans = spans.whereType<WidgetSpan>().toList();
        final contentWidget = widgetSpans[1]; // the "2" char
        final padding = contentWidget.child as Padding;
        final edgeInsets = padding.padding as EdgeInsets;
        expect(edgeInsets.bottom, greaterThan(0));
        expect(edgeInsets.top, 0);
      });

      test('cursor-slot count invariant preserved in preview mode', () {
        const baseStyle = TextStyle(fontSize: 16);
        const input = 'E=mc^2^';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        expect(totalSpanLength(spans), input.length);
      });

      test('cursor inside span: markers TextSpan (visible), content WidgetSpan', () {
        const baseStyle = TextStyle(fontSize: 16);
        // "^super^" — cursor at 3 (inside). Markers are active (visible TextSpan),
        // content is always WidgetSpan for vertical displacement.
        final spans = builder.build(
          '^super^',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(3),
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

      test('cursor outside: markers instantly hidden WidgetSpan, content WidgetSpan', () {
        const baseStyle = TextStyle(fontSize: 16);
        // Cursor outside: markers become hidden SizedBox.shrink WidgetSpans.
        final spans = builder.build(
          '^super^',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(100),
        );
        // ^ (shrink WS) + 5 content WS + ^ (shrink WS) = 7 WidgetSpans
        expect(spans.length, 7);
        for (final span in spans) {
          expect(span, isA<WidgetSpan>());
        }
      });

      test('nested ^**bold**^ in preview mode uses all WidgetSpans', () {
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "^**b**^" — cursor at 100 (outside [0,7]), opacity 0 → preview mode
        final spans = builder.build(
          '^**b**^',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(100),
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

      test('multi-char superscript content emits one WidgetSpan per char', () {
        const baseStyle = TextStyle(fontSize: 16);
        // Input: "x^abc^y" — 3 content chars → 3 content WidgetSpans
        final spans = builder.build(
          'x^abc^y',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
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

      test('hidden marker WidgetSpans use SizedBox.shrink', () {
        const baseStyle = TextStyle(fontSize: 16);
        final spans = builder.build(
          '^x^',
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(100),
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

      test('no renderMode: markers TextSpan, content WidgetSpan', () {
        const baseStyle = TextStyle(fontSize: 16);
        // No renderMode → always-visible mode; content still uses WidgetSpan
        // for vertical displacement; markers are visible TextSpan.
        final spans = builder.build('^super^', baseStyle, resolver);
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
