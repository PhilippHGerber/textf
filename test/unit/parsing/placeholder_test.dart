// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';

void main() {
  group('Placeholder Tests', () {
    late TextfParser parser;
    late BuildContext mockContext;

    setUp(() {
      parser = TextfParser();
    });

    Widget buildTestWidget(
      WidgetTester tester,
      Widget Function(BuildContext) builder,
    ) {
      return MaterialApp(
        home: Builder(
          builder: (context) {
            mockContext = context;
            return builder(context);
          },
        ),
      );
    }

    testWidgets('Basic substitution {{1}} works', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: 'replacement')];
      final spans = parser.parse(
        'prefix {{1}} suffix',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      expect(spans.length, 3);
      expect((spans[0] as TextSpan).text, 'prefix ');
      expect((spans[1] as TextSpan).text, 'replacement');
      expect((spans[2] as TextSpan).text, ' suffix');
    });

    testWidgets('Multiple substitutions {{1}} and {{2}} work', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [
        const TextSpan(text: 'one'),
        const TextSpan(text: 'two'),
      ];
      final spans = parser.parse(
        '{{1}} and {{2}}',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      expect(spans.length, 3); // "one", " and ", "two"
      expect((spans[0] as TextSpan).text, 'one');
      expect((spans[1] as TextSpan).text, ' and ');
      expect((spans[2] as TextSpan).text, 'two');
    });

    testWidgets('Nested style works BUT assumes no inheritance yet', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: 'replacement')];
      final spans = parser.parse(
        '**{{1}}**',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      // Currently, it adds NO text span for bold, just the replacement.
      // because "**" -> push bold. "{{1}}" -> flush (empty). add replacement. "**" -> pop bold.
      // So result is [replacement].

      expect(spans.length, 1);
      // It should refer to the same object if passed directly
      expect(spans[0], inlineSpans[0]);

      // Since current implementation ADDS it as sibling,
      // it is NOT wrapped in bold style.
      // If we want inheritance, we need to wrap it.
      // For now, assert the current behavior (raw insertion).
    });

    testWidgets('Out of bounds index renders as text', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: 'replacement')];
      final spans = parser.parse(
        '{{2}}',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, '{{2}}');
    });

    testWidgets('Malformed placeholders renders as text', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      // {{a}} is not a valid digit placeholder
      // But our tokenizer might not tokenize it as placeholder if it's not {{digits}}.
      // Tokenizer checks for digits.
      final spans = parser.parse(
        '{{a}}',
        mockContext,
        const TextStyle(),
      );

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, '{{a}}');
    });
  });
}
