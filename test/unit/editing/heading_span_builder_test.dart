// ignore_for_file: no-magic-number, avoid-late-keyword, avoid-non-null-assertion

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/marker_render_mode.dart';
import 'package:textf/src/editing/textf_span_builder.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

import '../../widgets/pump_textf_widget.dart';

/// Test-first specification for heading rendering in the editor span builder
/// (cases A5, A6, B2, B3, B4, B7, B8).
///
/// ----------------------------------------------------------------------------
/// ASSUMED BEHAVIOUR — NOT YET IMPLEMENTED. Expected to be RED until the
/// heading feature lands.
/// ----------------------------------------------------------------------------
///
/// The span builder must, for heading lines:
///  * Keep every character present (1:1 invariant): the total cursor-slot
///    count of all spans equals `text.length` in UTF-16 code units. Heading
///    markers (`# `) are shown dimmed; content gets the heading style.
///  * Apply the heading style only WITHIN the heading line. After the line's
///    `\n` the style falls back to the base style — no bleed into following
///    paragraphs, even when an inline marker (e.g. `**`) is left open on the
///    heading line (A5, A6).
void main() {
  group('TextfSpanBuilder — headings', () {
    late TextfSpanBuilder builder;
    final resolver = TextfStyleResolver(options: null);

    // A base style with a distinct, explicit size/weight so we can detect when
    // heading styling has (incorrectly) leaked into a following paragraph.
    const baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF222222),
    );

    setUp(() {
      builder = TextfSpanBuilder();
    });

    // -- Helpers ------------------------------------------------------------

    /// Flattens the span tree into leaf text runs with their effective
    /// (ancestor-merged) style.
    List<({String text, TextStyle style})> flatten(
      List<InlineSpan> spans,
      TextStyle base,
    ) {
      final out = <({String text, TextStyle style})>[];
      void walk(InlineSpan span, TextStyle inherited) {
        if (span is TextSpan) {
          final merged = span.style == null ? inherited : inherited.merge(span.style);
          final text = span.text;
          if (text != null && text.isNotEmpty) {
            out.add((text: text, style: merged));
          }
          for (final c in span.children ?? const <InlineSpan>[]) {
            walk(c, merged);
          }
        }
      }

      void start(InlineSpan s) => walk(s, base);
      spans.forEach(start);
      return out;
    }

    /// Returns the effective style of the first run whose text contains
    /// [needle].
    TextStyle styleOf(List<InlineSpan> spans, String needle) {
      final runs = flatten(spans, baseStyle);
      return runs.firstWhere((r) => r.text.contains(needle)).style;
    }

    // ========================================================================
    // 1:1 cursor-to-character invariant
    // ========================================================================

    group('1:1 cursor-to-character invariant', () {
      test('B7 — heading with emoji content keeps slot count == text.length', () {
        const input = '# Title 🚀 with emoji';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        // 🚀 is two UTF-16 code units; the invariant counts code units.
        expect(cursorSlots(spans), input.length);
      });

      test('B2 — heading with bold and italic keeps slot count', () {
        const input = '# Title with **bold** and *italic*';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        expect(cursorSlots(spans), input.length);
      });

      test('B8 — heading with a link keeps slot count', () {
        const input = '# See [Docs](https://example.com)';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        expect(cursorSlots(spans), input.length);
      });

      test('A5 — open inline marker on a heading line keeps slot count', () {
        const input = '# Title **bold';
        // Cursor at end (simulating mid-typing).
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(input.length),
        );
        expect(cursorSlots(spans), input.length);
      });

      test('A6 — two headings with an open marker keep slot count', () {
        const input = '# One **still open\n## Two';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        expect(cursorSlots(spans), input.length);
      });

      test('all-markers-hidden mode also preserves slot count', () {
        const input = '# Title 🚀';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: MarkerRenderMode.hidden,
        );
        expect(cursorSlots(spans), input.length);
      });
    });

    // ========================================================================
    // No style bleed across the newline
    // ========================================================================

    group('no style bleed past the heading line', () {
      test('B3 — paragraph after a heading uses the base style', () {
        const input = '# Heading\nNormal text afterwards.';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final paragraph = styleOf(spans, 'Normal text afterwards');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no enlarged heading size leak');
        expect(paragraph.fontWeight, baseStyle.fontWeight, reason: 'no bold heading weight leak');
        expect(cursorSlots(spans), input.length);
      });

      test('B4 — every paragraph between headings stays at base style', () {
        const input = '# First\nParagraph one.\n## Second\nParagraph two.';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        for (final needle in <String>['Paragraph one', 'Paragraph two']) {
          final style = styleOf(spans, needle);
          expect(style.fontSize, baseStyle.fontSize, reason: '$needle keeps base size');
          expect(style.fontWeight, baseStyle.fontWeight, reason: '$needle keeps base weight');
        }
        expect(cursorSlots(spans), input.length);
      });

      test('A5/A6 — an open `**` on a heading line does not bold the next paragraph', () {
        // The `**` is left open on the heading line; the following plain
        // paragraph must NOT inherit bold nor the heading size.
        const input = '# Title **still open\nNormal paragraph here.';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final paragraph = styleOf(spans, 'Normal paragraph here');
        expect(paragraph.fontWeight, baseStyle.fontWeight, reason: 'no bold bleed from open **');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no heading size bleed');
        expect(cursorSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Heading content actually receives a heading style
    // ========================================================================

    group('heading content styling', () {
      test('heading content is larger than the base text', () {
        const input = '# Big Title';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final title = styleOf(spans, 'Big Title');
        expect(
          title.fontSize,
          greaterThanOrEqualTo(baseStyle.fontSize!),
          reason: 'H1 content should be at least as large as base',
        );
      });
    });

    // ========================================================================
    // Increment 02 — tab separator + CRLF / lone-CR line starts
    // ========================================================================

    group('Increment 02', () {
      test('tab separator is preserved verbatim in the dimmed marker span', () {
        const input = '#\tTitle';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '#\t');
        expect(cursorSlots(spans), input.length);
        expect(marker.text, '#\t');
      });

      test('CRLF heading keeps slot count and terminates style at the paragraph', () {
        const input = '# Heading\r\nNormal text afterwards.';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final paragraph = styleOf(spans, 'Normal text afterwards');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no enlarged heading size leak');
        expect(cursorSlots(spans), input.length);
      });

      test('lone-CR heading keeps slot count and terminates style at the paragraph', () {
        const input = '# Heading\rNormal text afterwards.';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final paragraph = styleOf(spans, 'Normal text afterwards');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no enlarged heading size leak');
        expect(cursorSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Increment 03 — up to three-space indentation
    // ========================================================================

    group('Increment 03 — up to three-space indentation', () {
      test('leading spaces are preserved verbatim in the dimmed marker span', () {
        const input = '   # Title';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '   # ');
        expect(marker.text, '   # ');
        expect(cursorSlots(spans), input.length);
      });

      test('4-space indent is plain text, not a dimmed heading marker', () {
        const input = '    # Title';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final title = styleOf(spans, 'Title');
        expect(title.fontSize, baseStyle.fontSize, reason: '4 spaces disqualifies the heading');
        expect(cursorSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Increment 04 — empty headings
    // ========================================================================

    group('Increment 04 — empty headings', () {
      test('lone `#` at EOF keeps its slot and shows no content', () {
        const input = '#';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '#');
        expect(marker.text, '#');
        expect(cursorSlots(spans), input.length);
      });

      test('`## ` (trailing space only) preserves the marker + trailing-space slots', () {
        const input = '## ';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '## ');
        expect(marker.text, '## ');
        expect(cursorSlots(spans), input.length);
      });

      test('empty heading followed by a paragraph does not leak heading style', () {
        const input = '#\nNormal paragraph here.';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final paragraph = styleOf(spans, 'Normal paragraph here');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no heading size bleed');
        expect(cursorSlots(spans), input.length);
      });

      test('indented lone `#` at EOF preserves indentation + hash slots', () {
        const input = '  #';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '  #');
        expect(marker.text, '  #');
        expect(cursorSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Cursor-aware heading marker (O(1) via lineEndPosition)
    // ========================================================================

    group('cursor-aware heading marker', () {
      /// The leading '# ' marker span.
      TextSpan markerSpan(List<InlineSpan> spans) =>
          spans.whereType<TextSpan>().firstWhere((s) => s.text == '# ');

      test('active (heading-sized) when the cursor is on the heading line', () {
        const input = '# Title\nbody';
        // Cursor at index 3 — inside the heading line.
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(3),
        );

        final marker = markerSpan(spans);
        // Active marker keeps the heading font size (28 for base 14)…
        expect(marker.style!.fontSize, 28);
        // …and is visible (not collapsed to the hidden style).
        expect(marker.style!.color!.a, greaterThan(0));
      });

      test('inactive/hidden when the cursor is on another line', () {
        const input = '# Title\nbody';
        // Cursor at index 10 — in "body", past the heading line's terminator.
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(10),
        );

        final marker = markerSpan(spans);
        expect(marker.style!.color!.a, 0, reason: 'marker hidden off-line');
        expect(marker.style!.fontSize, lessThan(1));
      });

      test('hide-all-markers path hides the heading marker', () {
        const input = '# Title\nbody';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: MarkerRenderMode.hidden,
        );

        final marker = markerSpan(spans);
        expect(marker.style!.color!.a, 0);
        expect(cursorSlots(spans), input.length);
      });

      test('null cursor shows the marker (dimmed but present)', () {
        const input = '# Title';
        final spans = builder.build(input, baseStyle, resolver);

        final marker = markerSpan(spans);
        expect(marker.style!.color!.a, greaterThan(0));
        expect(cursorSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Performance / scale — locks in the O(1) marker (no per-heading scan)
    // ========================================================================

    group('large heading-dense input', () {
      test('1:1 invariant holds across many long heading lines', () {
        final buffer = StringBuffer();
        for (var i = 0; i < 400; i++) {
          buffer
            ..write('## ')
            ..write('Heading $i ${'word ' * 40}')
            ..write('\n');
        }
        final input = buffer.toString();

        // A per-heading forward scan would make per-line marker resolution grow
        // with line length; with the O(1) lineEndPosition check this stays
        // comfortably fast. The generous bound only guards against a
        // super-linear (O(N²)) regression, not micro-timing.
        final stopwatch = Stopwatch()..start();
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );
        stopwatch.stop();

        expect(cursorSlots(spans), input.length);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    // ========================================================================
    // Increment 05 — closing run + content trimming
    // ========================================================================

    group('Increment 05 — closing run and content trimming', () {
      test('`## foo ##` shows the closing run dimmed and keeps every slot', () {
        const input = '## foo ##';
        // Null cursor shows all markers with the dimmed-but-present style.
        final spans = builder.build(input, baseStyle, resolver);

        expect(cursorSlots(spans), input.length);
        // Opening run and the ` ##` suffix are both present as marker spans.
        final texts = spans.whereType<TextSpan>().map((s) => s.text).toList();
        expect(texts, containsAll(<String>['## ', ' ##']));
        // Content `foo` is at H2 size.
        expect(styleOf(spans, 'foo').fontSize, 21.0);
      });

      test('closing-run suffix is dimmed when the cursor is off the line', () {
        const input = '## foo ##\nbody';
        // Cursor on the body line (index into `body`), not the heading line.
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(input.length),
        );

        final suffix = spans.whereType<TextSpan>().firstWhere((s) => s.text == ' ##');
        // Inactive/hidden marker style collapses the font size.
        expect(suffix.style!.fontSize, lessThan(baseStyle.fontSize!));
        expect(cursorSlots(spans), input.length);
      });

      test('leading + trailing whitespace slots are preserved (`#   foo   `)', () {
        const input = '#   foo   ';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        expect(cursorSlots(spans), input.length);
        final texts = spans.whereType<TextSpan>().map((s) => s.text).toList();
        // Leading `#   ` is the opening marker; the three trailing spaces are
        // the suffix region.
        expect(texts, containsAll(<String>['#   ', '   ']));
      });

      test('`### ###` keeps all seven slots with empty content', () {
        const input = '### ###';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        expect(cursorSlots(spans), input.length);
        final texts = spans.whereType<TextSpan>().map((s) => s.text).toList();
        expect(texts, containsAll(<String>['### ', '###']));
      });

      test('closing run inside a heading with a link keeps every slot', () {
        const input = '# See [Docs](https://example.com) ##';
        final spans = builder.build(
          input,
          baseStyle,
          resolver,
          renderMode: const MarkerRenderMode.active(0),
        );

        expect(cursorSlots(spans), input.length);
      });
    });
  });
}
