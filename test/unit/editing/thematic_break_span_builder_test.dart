// ignore_for_file: no-magic-number, avoid-late-keyword, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/textf_span_builder.dart';

/// Editor-seam specification for thematic-break rendering in the span builder
/// (ticket 4). A thematic break (`---`/`***`/`___`) is the sole whole-line
/// construct; in the editing pipeline its raw characters stay visible as
/// **dimmed marker text**, brightening to the active marker style when the
/// cursor is on that line — exactly like ATX heading hashes.
///
/// The span builder must, for thematic-break lines:
///  * Keep every character present (1:1 invariant): the total character-slot
///    count of all spans equals `text.length` in UTF-16 code units. The rule's
///    `-`/`*`/`_` (and any inner/leading/trailing whitespace) are shown as a
///    single dimmed marker `TextSpan`.
///  * Never emit the read-only rule `WidgetSpan` — the editing pipeline only
///    ever produces `TextSpan`s for a pure rule line.
///  * Brighten the markers to the active marker style when the cursor sits on
///    the rule's line, and dim/hide them otherwise.
void main() {
  group('TextfSpanBuilder — thematic breaks', () {
    late TextfSpanBuilder builder;
    late BuildContext testContext;

    const baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF222222),
    );

    setUp(() {
      builder = TextfSpanBuilder();
    });

    /// Compact, newline-safe label for a test description.
    String jsonish(String s) => "'${s.replaceAll('\n', r'\n')}'";

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

    /// The marker span whose text is exactly [marker].
    TextSpan markerSpan(List<InlineSpan> spans, String marker) =>
        spans.whereType<TextSpan>().firstWhere((s) => s.text == marker);

    // ========================================================================
    // 1:1 character invariant across every recognized rule shape
    // ========================================================================

    group('1:1 character invariant', () {
      const cases = <String>[
        '---',
        '***',
        '___',
        '* * *',
        '- - -',
        '   ---', // 3-space indent (still a rule)
        '--- ', // trailing whitespace consumed into the line
        'above\n---\nbelow',
        '# Heading\n***\nbody',
      ];

      for (final input in cases) {
        testWidgets('slot count == text.length for ${jsonish(input)}', (tester) async {
          await tester.pumpWidget(hostWidget((_) => const SizedBox()));
          final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);
          expect(totalSlots(spans), input.length);
        });
      }

      testWidgets('null-cursor (all markers dimmed) also preserves slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = 'above\n- - -\nbelow';
        final spans = builder.build(input, testContext, baseStyle);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('hide-all-markers mode preserves slot count', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = 'above\n___\nbelow';
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
    // Raw characters rendered as a dimmed marker TextSpan (no read-only rule)
    // ========================================================================

    group('rule characters render as dimmed marker text', () {
      testWidgets('bare `---` is a single marker TextSpan with the raw chars', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = markerSpan(spans, '---');
        expect(marker.text, '---');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('spaced `* * *` keeps its inner whitespace verbatim', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '* * *';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = markerSpan(spans, '* * *');
        expect(marker.text, '* * *');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('indented `   ---` keeps the leading spaces in the marker span', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '   ---';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        final marker = markerSpan(spans, '   ---');
        expect(marker.text, '   ---');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('the editing pipeline never emits a WidgetSpan for a rule', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = 'above\n---\nbelow';
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 0);

        void assertNoWidgetSpan(InlineSpan span) {
          expect(span, isNot(isA<WidgetSpan>()));
          if (span is TextSpan) {
            (span.children ?? const <InlineSpan>[]).forEach(assertNoWidgetSpan);
          }
        }

        spans.forEach(assertNoWidgetSpan);
      });
    });

    // ========================================================================
    // Cursor-aware marker brightness
    // ========================================================================

    group('cursor-aware marker brightness', () {
      testWidgets('active (visible) when the cursor is on the rule line', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---\nbody';
        // Cursor at index 1 — inside the rule line.
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 1);

        final marker = markerSpan(spans, '---');
        expect(marker.style!.color!.a, greaterThan(0), reason: 'marker visible on-line');
      });

      testWidgets('inactive/hidden when the cursor is on another line', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---\nbody';
        // Cursor at index 5 — inside "body", past the rule line's terminator.
        final spans = builder.build(input, testContext, baseStyle, cursorPosition: 5);

        final marker = markerSpan(spans, '---');
        expect(marker.style!.color!.a, 0, reason: 'marker hidden off-line');
        expect(marker.style!.fontSize, lessThan(1));
      });

      testWidgets('hide-all-markers path hides the rule marker', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---\nbody';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          cursorPosition: TextfSpanBuilder.hideAllMarkers,
        );

        final marker = markerSpan(spans, '---');
        expect(marker.style!.color!.a, 0);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('null cursor shows the marker (dimmed but present)', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---';
        final spans = builder.build(input, testContext, baseStyle);

        final marker = markerSpan(spans, '---');
        expect(marker.style!.color!.a, greaterThan(0));
        expect(totalSlots(spans), input.length);
      });
    });

    // ========================================================================
    // Cursor stays 1:1 across typing / deleting rule characters
    // ========================================================================

    group('typing / deleting keeps the cursor 1:1', () {
      testWidgets('slot count tracks text.length as a rule is typed one char at a time',
          (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        // Simulate the keystroke sequence a-*-*-*-* (partial runs are inline
        // text; the third `*` promotes the line to a rule) and back down.
        const keystrokes = <String>['*', '**', '***', '****', '***', '**', '*', ''];
        for (final input in keystrokes) {
          final spans = builder.build(input, testContext, baseStyle, cursorPosition: input.length);
          expect(totalSlots(spans), input.length, reason: 'slot mismatch at "$input"');
        }
      });

      testWidgets('deleting into the preceding line keeps every slot', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        // Backspacing the newline that separates a paragraph from the rule.
        const steps = <String>['a\n---', 'a---', 'a--', 'a-', 'a'];
        for (final input in steps) {
          final spans = builder.build(input, testContext, baseStyle, cursorPosition: input.length);
          expect(totalSlots(spans), input.length, reason: 'slot mismatch at "$input"');
        }
      });
    });
  });
}
