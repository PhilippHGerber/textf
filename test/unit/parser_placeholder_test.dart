// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';

void main() {
  group('Parser Placeholder Tests', () {
    // ignore: avoid-late-keyword
    late TextfParser parser;
    // ignore: avoid-late-keyword
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

    group('Basic Placeholder Insertion', () {
      testWidgets('inserts WidgetSpan at {0}', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        final spans = [
          const WidgetSpan(child: Icon(Icons.star)),
        ];

        final result = parser.parse(
          'Prefix {0} Suffix',
          mockContext,
          baseStyle,
          inlineSpans: spans,
        );

        // Expected: "Prefix ", WidgetSpan, " Suffix"
        expect(result.length, 3);
        expect((result.first as TextSpan).text, 'Prefix ');
        expect(result[1], isA<TextSpan>());
        // The placeholder handler wraps the user span in a TextSpan for styling consistency
        final wrapperSpan = result[1] as TextSpan;
        expect(wrapperSpan.children, isNotEmpty);
        expect(wrapperSpan.children?.first, isA<WidgetSpan>());
        expect((result[2] as TextSpan).text, ' Suffix');
      });

      testWidgets('inserts TextSpan at {0} and preserves style', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle(color: Colors.black);
        final spans = [
          const TextSpan(text: 'Inserted', style: TextStyle(color: Colors.red)),
        ];

        final result = parser.parse(
          'Hello {0}',
          mockContext,
          baseStyle,
          inlineSpans: spans,
        );

        expect(result.length, 2);
        final wrapperSpan = result[1] as TextSpan;
        final children = wrapperSpan.children;
        expect(children, isNotEmpty);
        assert(children != null, 'Children should not be null');
        if (children != null) {
          final insertedSpan = children.first as TextSpan;

          expect(insertedSpan.text, 'Inserted');
          expect(insertedSpan.style?.color, Colors.red);
        }
      });
    });

    group('Bounds Checking & Error Handling', () {
      testWidgets('renders literal {n} if inlineSpans is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final result = parser.parse(
          'Hello {0}',
          mockContext,
          const TextStyle(),
        );

        expect(result.length, 1);
        // The parser accumulates "Hello " then "{0}" into the text buffer
        expect((result.first as TextSpan).text, 'Hello {0}');
      });

      testWidgets('renders literal {n} if index is out of bounds', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = [const TextSpan(text: 'One')]; // Only index 0 valid

        final result = parser.parse(
          'Val: {1}',
          mockContext,
          const TextStyle(),
          inlineSpans: spans,
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Val: {1}');
      });

      testWidgets('renders literal if malformed inside (handled by tokenizer)', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        // Tokenizer should treat {a} as text, not placeholder token
        final result = parser.parse(
          'Val: {a}',
          mockContext,
          const TextStyle(),
          inlineSpans: [],
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Val: {a}');
      });
    });

    group('Style Inheritance', () {
      testWidgets('placeholder inherits surrounding bold style', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = [const TextSpan(text: 'World')];

        final result = parser.parse(
          '**Hello {0}**',
          mockContext,
          const TextStyle(),
          inlineSpans: spans,
        );

        // Structure:
        // 1. "Hello " (Bold)
        // 2. {0} Wrapper (Bold) -> containing "World" (inherits Bold)

        // Note: The parser flushes text before style changes.
        // It sees: ** (push bold), text "Hello ", {0}, ** (pop).
        // 1. TextSpan("Hello ", style: bold)
        // 2. TextSpan(style: bold, children: [userSpan])

        expect(result.length, 2);

        // Verify Wrapper
        final wrapperSpan = result[1] as TextSpan;
        expect(wrapperSpan.style?.fontWeight, FontWeight.bold);

        // Verify child inheritance
        final children = wrapperSpan.children;
        expect(children, isNotEmpty);
        final child = (children ?? <InlineSpan>[]).first as TextSpan;
        expect(child.text, 'World');
        // Child has no explicit style, so it inherits from wrapper
        expect(child.style, isNull);
      });
    });

    group('Link Integration', () {
      testWidgets('placeholder works inside link text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = [
          const WidgetSpan(child: Icon(Icons.link)),
        ];

        final result = parser.parse(
          'Click [{0} Here](https://url.com)',
          mockContext,
          const TextStyle(),
          inlineSpans: spans,
        );

        expect(result.length, 2); // "Click ", LinkWidget
        expect(result[1], isA<WidgetSpan>());

        final linkWidget = (result[1] as WidgetSpan).child as HoverableLinkSpan;

        // Verify link contents
        final linkChildren = linkWidget.initialChildrenSpans;
        // Expect: Wrapper({0}), Text(" Here")
        expect(linkChildren.length, 2);

        final placeholderWrapper = linkChildren.first as TextSpan;
        expect(placeholderWrapper.children, isNotNull);
        expect(placeholderWrapper.children?.first, isA<WidgetSpan>());
        expect((linkChildren[1] as TextSpan).text, ' Here');
      });
    });

    group('Escaping', () {
      testWidgets('escaped brace is treated as text', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final spans = [const TextSpan(text: 'Hidden')];

        final result = parser.parse(
          r'Value \{0\}',
          mockContext,
          const TextStyle(),
          inlineSpans: spans,
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Value {0}');
      });
    });
  });
}
