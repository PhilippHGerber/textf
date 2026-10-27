// ignore_for_file: no-magic-number, prefer-match-file-name

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/textf_span_builder.dart';

import '../../widgets/pump_textf_widget.dart';

const TextDecoration _underline = TextDecoration.underline;

List<InlineSpan> _compose(List<InlineSpan> spans, TextRange composing) {
  final result = TextfSpanBuilder.applyComposing(spans, composing);
  expect(
    cursorSlots(result),
    cursorSlots(spans),
    reason: 'composing must not change the cursor-slot count',
  );
  return result;
}

String? _textOf(InlineSpan span) => span is TextSpan ? span.text : null;

TextDecoration? _decorationOf(InlineSpan span) => span is TextSpan ? span.style?.decoration : null;

void main() {
  group('TextfSpanBuilder.applyComposing', () {
    test('a range inside one text span splits it into three parts', () {
      const style = TextStyle(fontSize: 14);
      final result = _compose(
        const [TextSpan(text: 'abcdef', style: style)],
        const TextRange(start: 2, end: 4),
      );

      expect(result.map(_textOf), ['ab', 'cd', 'ef']);
      expect(result.map(_decorationOf), [null, _underline, null]);
      expect((result[1] as TextSpan).style?.fontSize, 14);
      expect((result[0] as TextSpan).style, style);
      expect((result[2] as TextSpan).style, style);
    });

    test('a range across several spans underlines each covered part', () {
      const bold = TextStyle(fontWeight: FontWeight.bold);
      final result = _compose(
        const [
          TextSpan(text: 'abc'),
          TextSpan(text: 'def', style: bold),
          TextSpan(text: 'ghi'),
        ],
        const TextRange(start: 1, end: 8),
      );

      expect(result.map(_textOf), ['a', 'bc', 'def', 'gh', 'i']);
      expect(result.map(_decorationOf), [null, _underline, _underline, _underline, null]);
      expect((result[2] as TextSpan).style?.fontWeight, FontWeight.bold);
    });

    test('a text span without a style gets an underline-only style', () {
      final result = _compose(
        const [TextSpan(text: 'abc')],
        const TextRange(start: 0, end: 3),
      );

      expect(result, hasLength(1));
      expect((result.single as TextSpan).style, const TextStyle(decoration: _underline));
    });

    test('boundaries on span edges underline whole spans without splitting', () {
      const spans = [
        TextSpan(text: 'ab'),
        TextSpan(text: 'cd'),
        TextSpan(text: 'ef'),
      ];
      final result = _compose(spans, const TextRange(start: 2, end: 4));

      expect(result.map(_textOf), ['ab', 'cd', 'ef']);
      expect(result.map(_decorationOf), [null, _underline, null]);
      expect(result[0], same(spans[0]));
      expect(result[2], same(spans[2]));
    });

    test('a range over a decorated span combines both decorations', () {
      const struck = TextStyle(decoration: TextDecoration.lineThrough);
      final result = _compose(
        const [TextSpan(text: 'abc', style: struck)],
        const TextRange(start: 0, end: 3),
      );

      final decoration = _decorationOf(result.single);
      expect(decoration, isNotNull);
      expect(decoration?.contains(TextDecoration.lineThrough) ?? false, isTrue);
      expect(decoration?.contains(_underline) ?? false, isTrue);
    });

    test('a range over widget slots passes the widgets through without underline', () {
      const x = WidgetSpan(child: SizedBox());
      const y = WidgetSpan(child: SizedBox());
      // Slots: 'ab' = 0..1, x = 2, y = 3, 'cd' = 4..5.
      final result = _compose(
        const [TextSpan(text: 'ab'), x, y, TextSpan(text: 'cd')],
        const TextRange(start: 1, end: 5),
      );

      expect(result.map(_textOf), ['a', 'b', null, null, 'c', 'd']);
      expect(result.map(_decorationOf), [null, _underline, null, null, _underline, null]);
      expect(result[2], same(x));
      expect(result[3], same(y));
    });

    group('no-op ranges return the spans unchanged', () {
      const spans = <InlineSpan>[
        TextSpan(text: 'abc'),
        WidgetSpan(child: SizedBox()),
        TextSpan(text: 'def'),
      ];

      for (final (name, range) in [
        ('empty (collapsed)', const TextRange.collapsed(2)),
        ('invalid (TextRange.empty)', TextRange.empty),
        ('reversed (start after end)', const TextRange(start: 2, end: 1)),
      ]) {
        test(name, () {
          final result = _compose(spans, range);
          expect(result, hasLength(spans.length));
          for (var i = 0; i < spans.length; i++) {
            expect(result[i], same(spans[i]));
          }
        });
      }
    });
  });
}
