// Integration tests verifying parser and style resolver work together.

// ignore_for_file: avoid-late-keyword, no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/src/widgets/textf_options.dart';

void main() {
  group('Parser and StyleResolver Integration', () {
    late TextfParser parser;

    setUp(() {
      parser = TextfParser();
      TextfParser.clearCache();
    });

    tearDown(TextfParser.clearCache);

    /// Pumps a neutral tree (optionally under [options]) and returns a context inside it.
    Future<BuildContext> pumpContext(
      WidgetTester tester, {
      TextfOptions Function(Widget child)? options,
    }) async {
      late BuildContext capturedContext;
      final Widget probe = Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: options == null ? probe : options(probe),
        ),
      );
      return capturedContext;
    }

    testWidgets('applies codeBackgroundColor to code spans', (tester) async {
      final context = await pumpContext(
        tester,
        options: (child) =>
            TextfOptions(codeBackgroundColor: const Color(0xFFE0E0E0), child: child),
      );

      final spans = parser.parse('`code`', context, const TextStyle());

      expect(spans.length, 1);
      final codeSpan = spans.first as TextSpan;
      expect(codeSpan.style?.fontFamily, 'monospace');
      expect(codeSpan.style?.backgroundColor, const Color(0xFFE0E0E0));
    });

    testWidgets('applies linkColor to links', (tester) async {
      final context = await pumpContext(
        tester,
        options: (child) => TextfOptions(linkColor: const Color(0xFF1976D2), child: child),
      );

      final spans = parser.parse('[link](url)', context, const TextStyle());

      expect(spans.length, 1);
      // Link creates a WidgetSpan with HoverableLinkSpan inside
      expect(spans.first, isA<WidgetSpan>());
      final link = (spans.first as WidgetSpan).child as HoverableLinkSpan;
      expect(link.normalStyle.color, const Color(0xFF1976D2));
      expect(link.normalStyle.decorationColor, const Color(0xFF1976D2));
      expect(link.normalStyle.decoration, TextDecoration.underline);
    });

    testWidgets('preserves base style properties through formatting', (tester) async {
      const baseStyle = TextStyle(
        fontSize: 20,
        fontFamily: 'CustomFont',
        letterSpacing: 1.5,
      );

      final context = await pumpContext(tester);

      final spans = parser.parse('**bold**', context, baseStyle);

      expect(spans.length, 1);
      final boldSpan = spans.first as TextSpan;
      expect(boldSpan.style?.fontSize, 20);
      expect(boldSpan.style?.fontFamily, 'CustomFont');
      expect(boldSpan.style?.letterSpacing, 1.5);
      expect(boldSpan.style?.fontWeight, FontWeight.bold);
    });
  });
}
