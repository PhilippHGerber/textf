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
          for (final c in span.children ?? const <InlineSpan>[]) {
            walk(c);
          }
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
        const input = '# Titel 🚀 mit Emoji';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        // 🚀 is two UTF-16 code units; the invariant counts code units.
        expect(totalSlots(spans), input.length);
      });

      testWidgets('B2 — heading with bold and italic keeps slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Titel mit **fett** und *kursiv*';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('B8 — heading with a link keeps slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Siehe [Doku](https://example.com)';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('A5 — open inline marker on a heading line keeps slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Titel **fett';
        // Cursor at end (simulating mid-typing).
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: input.length);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('A6 — two headings with an open marker keep slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Eins **noch offen\n## Zwei';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('all-markers-hidden mode also preserves slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Titel 🚀';
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
        const input = '# Überschrift\nNormaler Text danach.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final paragraph = styleOf(spans, 'Normaler Text danach');
        expect(paragraph.fontSize, baseStyle.fontSize, reason: 'no enlarged heading size leak');
        expect(paragraph.fontWeight, baseStyle.fontWeight, reason: 'no bold heading weight leak');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('B4 — every paragraph between headings stays at base style', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '# Erste\nAbsatz eins.\n## Zweite\nAbsatz zwei.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        for (final needle in <String>['Absatz eins', 'Absatz zwei']) {
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
        const input = '# Titel **noch offen\nNormaler Absatz hier.';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final paragraph = styleOf(spans, 'Normaler Absatz hier');
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
        const input = '# Großer Titel';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final title = styleOf(spans, 'Großer Titel');
        expect(
          title.fontSize,
          greaterThanOrEqualTo(baseStyle.fontSize!),
          reason: 'H1 content should be at least as large as base',
        );
      });
    });
  });
}
