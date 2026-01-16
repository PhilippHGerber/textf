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
      // Placeholder is now wrapped for style inheritance
      final replacementSpan = (spans[1] as TextSpan).children![0] as TextSpan;
      expect(replacementSpan.text, 'replacement');
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
      final oneSpan = (spans[0] as TextSpan).children![0] as TextSpan;
      expect(oneSpan.text, 'one');
      expect((spans[1] as TextSpan).text, ' and ');
      final twoSpan = (spans[2] as TextSpan).children![0] as TextSpan;
      expect(twoSpan.text, 'two');
    });

    testWidgets('Nested style works and SHOULD inherit style', (tester) async {
      await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
      final inlineSpans = [const TextSpan(text: 'replacement')];
      final spans = parser.parse(
        '**{0}**',
        mockContext,
        const TextStyle(),
        inlineSpans: inlineSpans,
      );

      // We expect the result to be wrapped or have style applied.
      // Current implementation returns [TextSpan(text: 'replacement')] with NO style (null).
      // We want it to be bold.

      expect(spans.length, 1);
      final span = spans[0];

      // We can check if it's a TextSpan and has bold, OR if it's a wrapper TextSpan with bold.
      // Let's inspect the effective style.
      // Since we can't easily compute effective style without a render tree in this unit test context,
      // we check the structure.

      // Ideally, it should be: TextSpan(style: bold, children: [replacement])
      // OR replacement with style merged.

      // Let's assert that we find FontWeight.bold SOMEWHERE in the span or its parent.
      bool isBold(InlineSpan s) {
        if (s is TextSpan) {
          if (s.style?.fontWeight == FontWeight.bold) return true;
          // If it has children, checking them might be recursive but style is usually on the parent.
          if (s.children != null) return s.children!.any(isBold);
        }
        return false;
      }

      expect(isBold(span), isTrue,
          reason: 'Placeholder should inherit bold style from surrounding markdown');
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
      final spans = parser.parse(
        'Value: ${0}',
        mockContext,
        const TextStyle(),
      );

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, 'Value: 0');
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

      final iconSpan = (spans[1] as TextSpan).children![0] as TextSpan;
      expect(iconSpan.text, '[ICON]');
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
