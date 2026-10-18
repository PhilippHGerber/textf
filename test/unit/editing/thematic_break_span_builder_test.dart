// ignore_for_file: no-magic-number, avoid-late-keyword, avoid-non-null-assertion

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/marker_render_mode.dart';
import 'package:textf/src/editing/textf_span_builder.dart';

import '../../widgets/pump_textf_widget.dart';

/// Editor-seam specification for thematic-break rendering in the span builder
/// (ticket 4). A thematic break (`---`/`***`/`___`) is the sole whole-line
/// construct; in the editing pipeline its raw characters show as **dimmed
/// marker text** while the line's markers are shown, and the rule is drawn in
/// their place while they are hidden.
///
/// The span builder must, for thematic-break lines:
///  * Keep every character present (1:1 invariant): the total character-slot
///    count of all spans equals `text.length` in UTF-16 code units.
///  * While the markers are shown (cursor on the rule's line, or all markers
///    visible), emit the rule's `-`/`*`/`_` (and any inner/leading/trailing
///    whitespace) as a single dimmed marker `TextSpan` and no `WidgetSpan`.
///  * While the markers are hidden, emit the rule as one `WidgetSpan` followed
///    by a zero-size `WidgetSpan` per remaining character — the markers are the
///    line's only content, so hiding them as text would make the line vanish.
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
      return neutralTestApp(
        child: Builder(
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

    /// Asserts [spans] holds a drawn rule filling [slots] character slots: one
    /// rule `WidgetSpan` plus a zero-size filler for each remaining slot, and
    /// no marker `TextSpan` carrying the raw [marker] characters.
    void expectDrawnRule(List<InlineSpan> spans, {required String marker, required int slots}) {
      final widgetSpans = spans.whereType<WidgetSpan>().toList();
      expect(widgetSpans, hasLength(slots));
      expect(widgetSpans.first.child, isNot(isA<SizedBox>()), reason: 'first slot is the rule');
      for (final filler in widgetSpans.skip(1)) {
        expect(filler.child, isA<SizedBox>());
      }
      expect(spans.whereType<TextSpan>().where((s) => s.text == marker), isEmpty);
    }

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
          final spans = builder.build(
            input,
            testContext,
            baseStyle,
            renderMode: const MarkerRenderMode.active(0),
          );
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
          renderMode: MarkerRenderMode.hidden,
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
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = markerSpan(spans, '---');
        expect(marker.text, '---');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('spaced `* * *` keeps its inner whitespace verbatim', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '* * *';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = markerSpan(spans, '* * *');
        expect(marker.text, '* * *');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('indented `   ---` keeps the leading spaces in the marker span', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '   ---';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: const MarkerRenderMode.active(0),
        );

        final marker = markerSpan(spans, '   ---');
        expect(marker.text, '   ---');
        expect(totalSlots(spans), input.length);
      });

      testWidgets('no WidgetSpan is emitted while the rule markers are shown', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = 'above\n---\nbelow';
        // Cursor at index 7 — inside the rule line.
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: const MarkerRenderMode.active(7),
        );

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
    // Cursor-aware rendering: marker text on-line, drawn rule off-line
    // ========================================================================

    group('cursor-aware rendering', () {
      testWidgets('active (visible) when the cursor is on the rule line', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---\nbody';
        // Cursor at index 1 — inside the rule line.
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: const MarkerRenderMode.active(1),
        );

        final marker = markerSpan(spans, '---');
        expect(marker.style!.color!.a, greaterThan(0), reason: 'marker visible on-line');
      });

      testWidgets('drawn as a rule when the cursor is on another line', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---\nbody';
        // Cursor at index 5 — inside "body", past the rule line's terminator.
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: const MarkerRenderMode.active(5),
        );

        expectDrawnRule(spans, marker: '---', slots: 3);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('spaced rule with trailing whitespace fills every slot', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = 'above\n- - -  \nbelow';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: const MarkerRenderMode.active(0),
        );

        expectDrawnRule(spans, marker: '- - -  ', slots: 7);
        expect(totalSlots(spans), input.length);
      });

      testWidgets('hide-all-markers path draws the rule', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        const input = '---\nbody';
        final spans = builder.build(
          input,
          testContext,
          baseStyle,
          renderMode: MarkerRenderMode.hidden,
        );

        expectDrawnRule(spans, marker: '---', slots: 3);
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
      testWidgets('slot count tracks text.length as a rule is typed one char at a time', (
        tester,
      ) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        // Simulate the keystroke sequence a-*-*-*-* (partial runs are inline
        // text; the third `*` promotes the line to a rule) and back down.
        const keystrokes = <String>['*', '**', '***', '****', '***', '**', '*', ''];
        for (final input in keystrokes) {
          final spans = builder.build(
            input,
            testContext,
            baseStyle,
            renderMode: MarkerRenderMode.active(input.length),
          );
          expect(totalSlots(spans), input.length, reason: 'slot mismatch at "$input"');
        }
      });

      testWidgets('deleting into the preceding line keeps every slot', (tester) async {
        await tester.pumpWidget(hostWidget((_) => const SizedBox()));
        // Backspacing the newline that separates a paragraph from the rule.
        const steps = <String>['a\n---', 'a---', 'a--', 'a-', 'a'];
        for (final input in steps) {
          final spans = builder.build(
            input,
            testContext,
            baseStyle,
            renderMode: MarkerRenderMode.active(input.length),
          );
          expect(totalSlots(spans), input.length, reason: 'slot mismatch at "$input"');
        }
      });
    });
  });
}
