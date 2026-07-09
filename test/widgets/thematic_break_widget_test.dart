// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

/// Walking-skeleton (ticket 1) end-to-end render check for thematic breaks:
/// a bare `---`/`***`/`___` line renders as a full-width rule `WidgetSpan`
/// inside the read-only `Textf` widget, with surrounding text intact.
void main() {
  group('Textf — thematic break rendering', () {
    /// Collects every [WidgetSpan] in the rendered paragraph.
    List<WidgetSpan> renderedWidgetSpans(WidgetTester tester) {
      final richText = tester.widget<RichText>(find.byType(RichText));
      final spans = <WidgetSpan>[];
      richText.text.visitChildren((span) {
        if (span is WidgetSpan) spans.add(span);
        return true;
      });
      return spans;
    }

    // The default rule paints an opaque [ColoredBox] in the theme's
    // dividerColor; Material chrome contributes a separate *transparent* one, so
    // match on a non-zero alpha to isolate the rule.
    final ruleBox = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color.a > 0,
    );

    testWidgets('a bare `---` line renders a rule WidgetSpan', (tester) async {
      await pumpTextfWidget(tester, data: '---');

      expect(tester.takeException(), isNull);
      expect(renderedWidgetSpans(tester), hasLength(1), reason: 'one rule');
      // The rule paints a ColoredBox (the divider colour).
      expect(ruleBox, findsOneWidget);
    });

    testWidgets('`***` and `___` also render a rule', (tester) async {
      for (final marker in const ['***', '___']) {
        await pumpTextfWidget(tester, data: marker);
        expect(tester.takeException(), isNull, reason: '"$marker" must not throw');
        expect(renderedWidgetSpans(tester), hasLength(1), reason: '"$marker" is a rule');
      }
    });

    testWidgets('text · rule · text renders both lines and a rule between', (tester) async {
      await pumpTextfWidget(tester, data: 'above\n---\nbelow');

      expect(tester.takeException(), isNull);
      expect(renderedWidgetSpans(tester), hasLength(1));

      // Both surrounding text lines survive in the paragraph's plain text.
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), contains('above'));
      expect(richText.text.toPlainText(), contains('below'));
    });

    testWidgets('the rule fills the paragraph width in a bounded frame', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 300, child: Textf('---')),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final box = tester.renderObject<RenderBox>(ruleBox);
      expect(box.size.width, 300, reason: 'the rule fills the bounded paragraph width');
      expect(box.size.height, 1, reason: '1px rule');
    });

    testWidgets('a short run (`--`) is plain text, not a rule', (tester) async {
      await pumpTextfWidget(tester, data: '--');

      expect(renderedWidgetSpans(tester), isEmpty);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), '--');
    });
  });
}
