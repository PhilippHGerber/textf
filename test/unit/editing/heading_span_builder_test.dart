// ignore_for_file: no-magic-number, avoid-late-keyword, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/textf_span_builder.dart';

/// Test-first specification for heading rendering in the editor span builder
/// (cases A5, A6, B2, B3, B4, B7, B8).
///
/// ----------------------------------------------------------------------------
/// ASSUMED BEHAVIOUR — NOT YET IMPLEMENTED. Expected to be RED until the
/// heading feature lands.
/// ----------------------------------------------------------------------------
///
/// The span builder must, for heading lines:
///  * Keep every character present (1:1 invariant): the total character-slot
///    count of all spans equals `text.length` in UTF-16 code units. Heading
///    markers (`# `) are shown dimmed; content gets the heading style.
///  * Apply the heading style only WITHIN the heading line. After the line's
///    `\n` the style falls back to the base style — no bleed into following
///    paragraphs, even when an inline marker (e.g. `**`) is left open on the
///    heading line (A5, A6).
void main() {
  group('TextfSpanBuilder — headings', () {
    late TextfSpanBuilder builder;
    late BuildContext testContext;

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

    Widget hostWidget(Widget Function(BuildContext) child) {
      return MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return child(context);
          },
        ),
      );
    }

    // -- Helpers ------------------------------------------------------------

    /// Total character slots: each [TextSpan] contributes `text.length`, each
    /// [WidgetSpan] contributes exactly 1. Recurses into children.
    int totalSlots(List<InlineSpan> spans) {
      var sum = 0;
      void walk(InlineSpan span) {
        if (span is TextSpan) {
          sum += span.text?.length ?? 0;
          (span.children ?? const <InlineSpan>[]).forEach(walk);
        } else if (span is WidgetSpan) {
          sum += 1;
        }
      }

      spans.forEach(walk);
      return sum;
    }

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
    // 1:1 character invariant
    // ========================================================================

    group('1:1 character invariant', () {
      testWidgets('B7 — heading with emoji content keeps slot count == text.length',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title 🚀 with emoji';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        // 🚀 is two UTF-16 code units; the invariant counts code units.
        expect(totalSlots(spans), input.length);
      });

      testWidgets('B2 — heading with bold and italic keeps slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title with **bold** and *italic*';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('B8 — heading with a link keeps slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# See [Docs](https://example.com)';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('A5 — open inline marker on a heading line keeps slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title **bold';
        // Cursor at end (simulating mid-typing).
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: input.length);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('A6 — two headings with an open marker keep slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# One **still open\n## Two';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('all-markers-hidden mode also preserves slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title 🚀';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          cursorPosition: TextfSpanBuilder.hideAllMarkers,
        );
        expect(totalSlots(spans), input.length);
      });
    });

    // ========================================================================
    // No style bleed across the newline
    // ========================================================================

    group('no style bleed past the heading line', () {
      testWidgets('B3 — paragraph after a heading uses the base style', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Heading\nNormal text afterwards.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final paragraph = styleOf(spans, 'Normal text afterwards');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no enlarged heading size leak');
        expect(paragraph.fontWeight, baseStyle.fontWeight, reason: 'no bold heading weight leak');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('B4 — every paragraph between headings stays at base style', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# First\nParagraph one.\n## Second\nParagraph two.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        for (final needle in <String>['Paragraph one', 'Paragraph two']) {
          final style = styleOf(spans, needle);
          expect(style.fontSize, baseStyle.fontSize, reason: '$needle keeps base size');
          expect(style.fontWeight, baseStyle.fontWeight, reason: '$needle keeps base weight');
        }
        expect(totalSlots(spans), input.length);
      });

      testWidgets('A5/A6 — an open `**` on a heading line does not bold the next paragraph',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        // The `**` is left open on the heading line; the following plain
        // paragraph must NOT inherit bold nor the heading size.
        const input = '# Title **still open\nNormal paragraph here.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final paragraph = styleOf(spans, 'Normal paragraph here');
        expect(paragraph.fontWeight, baseStyle.fontWeight, reason: 'no bold bleed from open **');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no heading size bleed');
        expect(totalSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Heading content actually receives a heading style
    // ========================================================================

    group('heading content styling', () {
      testWidgets('heading content is larger than the base text', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Big Title';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

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
      testWidgets('tab separator is preserved verbatim in the dimmed marker span', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '#\tTitle';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '#\t');
        expect(totalSlots(spans), input.length);
        expect(marker.text, '#\t');
      });

      testWidgets('CRLF heading keeps slot count and terminates style at the paragraph',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Heading\r\nNormal text afterwards.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final paragraph = styleOf(spans, 'Normal text afterwards');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no enlarged heading size leak');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('lone-CR heading keeps slot count and terminates style at the paragraph',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Heading\rNormal text afterwards.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final paragraph = styleOf(spans, 'Normal text afterwards');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no enlarged heading size leak');
        expect(totalSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Increment 03 — up to three-space indentation
    // ========================================================================

    group('Increment 03 — up to three-space indentation', () {
      testWidgets('leading spaces are preserved verbatim in the dimmed marker span',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '   # Title';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '   # ');
        expect(marker.text, '   # ');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('4-space indent is plain text, not a dimmed heading marker', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '    # Title';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final title = styleOf(spans, 'Title');
        expect(title.fontSize, baseStyle.fontSize, reason: '4 spaces disqualifies the heading');
        expect(totalSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Increment 04 — empty headings
    // ========================================================================

    group('Increment 04 — empty headings', () {
      testWidgets('lone `#` at EOF keeps its slot and shows no content', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '#';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '#');
        expect(marker.text, '#');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('`## ` (trailing space only) preserves the marker + trailing-space slots',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '## ';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '## ');
        expect(marker.text, '## ');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('empty heading followed by a paragraph does not leak heading style',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '#\nNormal paragraph here.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final paragraph = styleOf(spans, 'Normal paragraph here');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no heading size bleed');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('indented lone `#` at EOF preserves indentation + hash slots', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '  #';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = spans.whereType<TextSpan>().firstWhere((s) => s.text == '  #');
        expect(marker.text, '  #');
        expect(totalSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Cursor-aware heading marker (O(1) via lineEndPosition)
    // ========================================================================

    group('cursor-aware heading marker', () {
      /// The leading '# ' marker span.
      TextSpan markerSpan(List<InlineSpan> spans) =>
          spans.whereType<TextSpan>().firstWhere((s) => s.text == '# ');

      testWidgets('active (heading-sized) when the cursor is on the heading line', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title\nbody';
        // Cursor at index 3 — inside the heading line.
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 3);

        final marker = markerSpan(spans);
        // Active marker keeps the heading font size (28 for base 14)…
        expect(marker.style!.fontSize, 28);
        // …and is visible (not collapsed to the hidden style).
        expect(marker.style!.color!.a, greaterThan(0));
      });

      testWidgets('inactive/hidden when the cursor is on another line', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title\nbody';
        // Cursor at index 10 — in "body", past the heading line's terminator.
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 10);

        final marker = markerSpan(spans);
        expect(marker.style!.color!.a, 0, reason: 'marker hidden off-line');
        expect(marker.style!.fontSize, lessThan(1));
      });

      testWidgets('hide-all-markers path hides the heading marker', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title\nbody';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          cursorPosition: TextfSpanBuilder.hideAllMarkers,
        );

        final marker = markerSpan(spans);
        expect(marker.style!.color!.a, 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('null cursor shows the marker (dimmed but present)', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Title';
        final spans = builder.build(input, testContext, baseStyle);

        final marker = markerSpan(spans);
        expect(marker.style!.color!.a, greaterThan(0));
        expect(totalSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Performance / scale — locks in the O(1) marker (no per-heading scan)
    // ========================================================================

    group('large heading-dense input', () {
      testWidgets('1:1 invariant holds across many long heading lines', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));

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
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
        stopwatch.stop();

        expect(totalSlots(spans), input.length);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    // ========================================================================
    // Increment 05 — closing run + content trimming
    // ========================================================================

    group('Increment 05 — closing run and content trimming', () {
      testWidgets('`## foo ##` shows the closing run dimmed and keeps every slot',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '## foo ##';
        // Null cursor shows all markers with the dimmed-but-present style.
        final spans = builder.build(input, testContext, baseStyle);

        expect(totalSlots(spans), input.length);
        // Opening run and the ` ##` suffix are both present as marker spans.
        final texts = spans.whereType<TextSpan>().map((s) => s.text).toList();
        expect(texts, containsAll(<String>['## ', ' ##']));
        // Content `foo` is at H2 size.
        expect(styleOf(spans, 'foo').fontSize, 21.0);
      });

      testWidgets('closing-run suffix is dimmed when the cursor is off the line', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '## foo ##\nbody';
        // Cursor on the body line (index into `body`), not the heading line.
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: input.length);

        final suffix = spans.whereType<TextSpan>().firstWhere((s) => s.text == ' ##');
        // Inactive/hidden marker style collapses the font size.
        expect(suffix.style!.fontSize, lessThan(baseStyle.fontSize!));
        expect(totalSlots(spans), input.length);
      });

      testWidgets('leading + trailing whitespace slots are preserved (`#   foo   `)',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '#   foo   ';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        expect(totalSlots(spans), input.length);
        final texts = spans.whereType<TextSpan>().map((s) => s.text).toList();
        // Leading `#   ` is the opening marker; the three trailing spaces are
        // the suffix region.
        expect(texts, containsAll(<String>['#   ', '   ']));
      });

      testWidgets('`### ###` keeps all seven slots with empty content', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '### ###';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        expect(totalSlots(spans), input.length);
        final texts = spans.whereType<TextSpan>().map((s) => s.text).toList();
        expect(texts, containsAll(<String>['### ', '###']));
      });

      testWidgets('closing run inside a heading with a link keeps every slot', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# See [Docs](https://example.com) ##';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        expect(totalSlots(spans), input.length);
      });
    });
  });
}
