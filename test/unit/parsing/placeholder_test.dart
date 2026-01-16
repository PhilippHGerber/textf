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

    testWidgets('Basic substitution {0} works', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: 'replacement')];
      final spans = parser.parse(
        'prefix {0} suffix',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      expect(spans.length, 3);
      expect((spans[0] as TextSpan).text, 'prefix ');
      expect((spans[1] as TextSpan).text, 'replacement');
      expect((spans[2] as TextSpan).text, ' suffix');
    });

    testWidgets('Multiple substitutions {0} and {1} work', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [
        const TextSpan(text: 'one'),
        const TextSpan(text: 'two'),
      ];
      final spans = parser.parse(
        '{0} and {1}',
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
        '**{0}**',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      // Currently, it adds NO text span for bold, just the replacement.
      // because "**" -> push bold. "{0}" -> flush (empty). add replacement. "**" -> pop bold.
      // So result is [replacement].

      expect(spans.length, 1);
      // It should refer to the same object if passed directly
      expect(spans[0], inlineSpans[0]);
    });

    testWidgets('Out of bounds index renders as text', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: 'replacement')];
      final spans = parser.parse(
        '{1}',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, '{1}');
    });

    testWidgets('Malformed placeholders renders as text', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      // {a} is not a valid digit placeholder
      final spans = parser.parse(
        '{a}',
        mockContext,
        const TextStyle(),
      );

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, '{a}');
    });

    testWidgets('Simulated interpolation \${property.value} does NOT parse as placeholder',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      // Tokenizer looks for {digits}, so {property.value} or similar inside text shouldn't be touched.
      // In Dart source if using string interpolation: Textf("Val: ${123}") -> "Val: 123" -> Plain text.
      // If passing raw string with $: Textf(r"${property.value}") -> Literal "${property.value}"

      final spans = parser.parse(
        r'${property.value}',
        mockContext,
        const TextStyle(),
      );

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, r'${property.value}');
    });

    testWidgets('Interpolated value in source code works as plain text', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final val = 123;
      // "Value: 123"
      final spans = parser.parse(
        'Value: ${val}',
        mockContext,
        const TextStyle(),
      );

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, 'Value: 123');
    });

    testWidgets('Mixed usage of {N} and \${} safeguards', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: '[ICON]')];

      // "Count: 5, Icon: [ICON]"
      final count = 5;
      final spans = parser.parse(
        'Count: ${count}, Icon: {0}',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      expect(spans.length, 2);
      expect((spans[0] as TextSpan).text, 'Count: 5, Icon: ');
      expect((spans[1] as TextSpan).text, '[ICON]');
    });

    testWidgets('Escaping {0} works', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: 'replacement')];

      // If we support backslash escaping in tokenizer:
      // r'Literal \{0\}'
      final spans = parser.parse(
        r'Literal \{0\}',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      // Note: Tokenizer needs to support escaping {, which it currently handles if strictly implemented.
      // Looking at tokenizer logic:
      // if (currentChar == kEscape) ... checks nextChar
      // if nextChar is not in the specific list (kAsterisk, etc..), it treats slash as text?
      // Let's verify tokenizer logic:
      // "nextChar == kOpenBrace" IS in the list?
      // Lines 88-104 in tokenizer: kOpenBrace is checked!
      // So \{ should escape.

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, 'Literal {0}');
    });
  });
}
