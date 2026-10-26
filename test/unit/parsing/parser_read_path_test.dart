// ignore_for_file: avoid-late-keyword, no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/src/widgets/textf_options.dart';

import '../../widgets/pump_textf_widget.dart';

// Read-path behavior observed through `TextfParser.parse()`: the palette, link
// handling and placeholder handling of a parse run.

const Color _black = Color(0xFF000000);
const Color _white = Color(0xFFFFFFFF);

void main() {
  late BuildContext context;

  /// Pumps a host (optionally under [options]) and captures its context.
  Future<void> pumpHost(WidgetTester tester, {TextfOptions Function(Widget)? options}) async {
    final Widget capture = Builder(
      builder: (ctx) {
        context = ctx;
        return const SizedBox();
      },
    );
    await tester.pumpWidget(neutralTestApp(child: options?.call(capture) ?? capture));
  }

  List<InlineSpan> parse(
    String text, {
    TextStyle baseStyle = const TextStyle(color: _black),
    Map<String, InlineSpan>? placeholders,
  }) {
    return TextfParser().parse(
      text,
      context,
      baseStyle,
      placeholders: placeholders,
      styleResolver: TextfStyleResolver(context),
    );
  }

  HoverableLinkSpan linkOf(InlineSpan span) {
    expect(span, isA<WidgetSpan>());
    final Widget child = (span as WidgetSpan).child;
    expect(child, isA<HoverableLinkSpan>());
    return child as HoverableLinkSpan;
  }

  group('palette', () {
    testWidgets('derives from the effective root style (light text: dark surface)', (
      tester,
    ) async {
      await pumpHost(tester);

      final spans = parse('`c`', baseStyle: const TextStyle(color: _white));

      final code = spans.single as TextSpan;
      expect(code.style?.backgroundColor, _white.withValues(alpha: 0.15));
    });

    testWidgets('derives from the effective root style (dark text: light surface)', (
      tester,
    ) async {
      await pumpHost(tester);

      final spans = parse('`c`');

      final code = spans.single as TextSpan;
      expect(code.style?.backgroundColor, _black.withValues(alpha: 0.05));
    });

    testWidgets('link text inherits the enclosing palette, not the link color', (tester) async {
      await pumpHost(
        tester,
        options: (child) => TextfOptions(
          linkStyle: const TextStyle(color: _white),
          child: child,
        ),
      );

      final spans = parse('[`c`](example.com)');

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
    testWidgets('an invalid link leaves the surrounding text in one span', (tester) async {
      await pumpHost(tester);

      for (final text in ['before [text] after', 'before [text]( after', 'a [b](c d']) {
        final spans = parse(text);

        expect(spans, hasLength(1), reason: text);
        expect((spans.single as TextSpan).text, text);
      }
    });

    testWidgets('a valid link flushes the preceding text first and emits one widget span', (
      tester,
    ) async {
      await pumpHost(tester);

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

    testWidgets('a formatted label renders as child spans', (tester) async {
      await pumpHost(tester);

      final link = linkOf(parse('[**bold** label](example.com)').single);

      expect(link.initialPlainText, isNull);
      expect(link.initialChildrenSpans.map((s) => (s as TextSpan).text), ['bold', ' label']);
      expect(
        (link.initialChildrenSpans.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );
    });

    testWidgets('escapes are stripped from a plain link label', (tester) async {
      await pumpHost(tester);

      final link = linkOf(parse(r'[a\*b\_c](example.com)').single);

      expect(link.initialPlainText, 'a*b_c');
      expect(link.initialChildrenSpans, isEmpty);
      expect(link.rawDisplayText, r'a\*b\_c');
    });
  });

  group('placeholders', () {
    const icon = WidgetSpan(child: SizedBox(width: 10));

    testWidgets('a valid placeholder flushes, takes the current style and keeps its order', (
      tester,
    ) async {
      await pumpHost(tester);

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

    testWidgets('an unknown placeholder renders as literal text without flushing', (
      tester,
    ) async {
      await pumpHost(tester);

      final spans = parse('Hello {missing} world', placeholders: {'icon': icon});

      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).text, 'Hello {missing} world');
    });
  });
}
