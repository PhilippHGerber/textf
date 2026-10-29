// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

// Read-path behavior observed through `TextfParser.parse()`: the palette, link
// handling and placeholder handling of a parse run.

const Color _black = Color(0xFF000000);
const Color _white = Color(0xFFFFFFFF);
const Color _red = Color(0xFFFF0000);

void main() {
  List<InlineSpan> parse(
    String text, {
    TextStyle baseStyle = const TextStyle(color: _black),
    Map<String, InlineSpan>? placeholders,
    TextfOptionsData? options,
  }) {
    return TextfParser().parse(
      text,
      baseStyle,
      TextfStyleResolver(options: options),
      placeholders: placeholders,
    );
  }

  HoverableLinkSpan linkOf(InlineSpan span) {
    expect(span, isA<WidgetSpan>());
    final Widget child = (span as WidgetSpan).child;
    expect(child, isA<HoverableLinkSpan>());
    return child as HoverableLinkSpan;
  }

  group('palette', () {
    test('derives from the effective root style (light text: dark surface)', () {
      final spans = parse('`c`', baseStyle: const TextStyle(color: _white));

      final code = spans.single as TextSpan;
      expect(code.style?.backgroundColor, _white.withValues(alpha: 0.15));
    });

    test('derives from the effective root style (dark text: light surface)', () {
      final spans = parse('`c`');

      final code = spans.single as TextSpan;
      expect(code.style?.backgroundColor, _black.withValues(alpha: 0.05));
    });

    test('link text inherits the enclosing palette, not the link color', () {
      final spans = parse(
        '[`c`](example.com)',
        options: const TextfOptionsData(linkStyle: TextStyle(color: _white)),
      );

      final link = linkOf(spans.single);
      final code = link.initialChildrenSpans.single as TextSpan;
      expect(code.style?.color, _white, reason: 'the code text keeps the link color');
      expect(
        code.style?.backgroundColor,
        _black.withValues(alpha: 0.05),
        reason: 'the tint derives from the root (black, light surface), not the white link',
      );
    });
  });

  group('links', () {
    test('nested formatting in a link resolves with the enclosing options', () {
      final link = linkOf(
        parse(
          '[**bold** ==mark==](example.com)',
          options: const TextfOptionsData(
            linkStyle: TextStyle(color: _white),
            boldStyle: TextStyle(color: _red),
          ),
        ).single,
      );

      final bold = link.initialChildrenSpans.first as TextSpan;
      final mark = link.initialChildrenSpans.last as TextSpan;
      expect(bold.style?.color, _red, reason: 'the bold style option applies inside the link');
      final rootMark = parse('==mark==').single as TextSpan;
      expect(mark.style?.backgroundColor, isNotNull);
      expect(
        mark.style?.backgroundColor,
        rootMark.style?.backgroundColor,
        reason: 'the highlight tint derives from the black root, not the white link color',
      );
    });

    test('an invalid link leaves the surrounding text in one span', () {
      for (final text in ['before [text] after', 'before [text]( after', 'a [b](c d']) {
        final spans = parse(text);

        expect(spans, hasLength(1), reason: text);
        expect((spans.single as TextSpan).text, text);
      }
    });

    test('a valid link flushes the preceding text first and emits one widget span', () {
      final spans = parse('before [link](example.com) after');

      expect(spans, hasLength(3));
      expect((spans.first as TextSpan).text, 'before ');
      final link = linkOf(spans[1]);
      expect(link.url, 'https://example.com');
      expect(link.rawDisplayText, 'link');
      expect(link.initialPlainText, 'link');
      expect(link.initialChildrenSpans, isEmpty);
      expect((spans.last as TextSpan).text, ' after');
    });

    test('a formatted label renders as child spans', () {
      final link = linkOf(parse('[**bold** label](example.com)').single);

      expect(link.initialPlainText, isNull);
      expect(link.initialChildrenSpans.map((s) => (s as TextSpan).text), ['bold', ' label']);
      expect(
        (link.initialChildrenSpans.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );
    });

    test('escapes are stripped from a plain link label', () {
      final link = linkOf(parse(r'[a\*b\_c](example.com)').single);

      expect(link.initialPlainText, 'a*b_c');
      expect(link.initialChildrenSpans, isEmpty);
      expect(link.rawDisplayText, r'a\*b\_c');
    });
  });

  group('placeholders', () {
    const icon = WidgetSpan(child: SizedBox(width: 10));

    test('a placeholder inside link text is substituted', () {
      final link = linkOf(parse('[{icon} Docs](example.com)', placeholders: {'icon': icon}).single);

      expect(link.initialPlainText, isNull);
      expect(link.initialChildrenSpans, hasLength(2));
      expect((link.initialChildrenSpans.first as TextSpan).children, [icon]);
      expect((link.initialChildrenSpans.last as TextSpan).text, ' Docs');
    });

    test('a valid placeholder flushes, takes the current style and keeps its order', () {
      final spans = parse('**a {icon} b**', placeholders: {'icon': icon});

      expect(spans, hasLength(3));
      final before = spans.first as TextSpan;
      final wrapper = spans[1] as TextSpan;
      final after = spans.last as TextSpan;
      expect(before.text, 'a ');
      expect(wrapper.children, [icon]);
      expect(wrapper.style?.fontWeight, FontWeight.bold);
      expect(wrapper.style, before.style, reason: 'wrapped in the current style');
      expect(after.text, ' b');
    });

    test('an unknown placeholder renders as literal text without flushing', () {
      final spans = parse('Hello {missing} world', placeholders: {'icon': icon});

      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).text, 'Hello {missing} world');
    });
  });
}
