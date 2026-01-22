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
      testWidgets('inserts WidgetSpan at {key}', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle();
        final placeholders = {
          'icon': const WidgetSpan(child: Icon(Icons.star)),
        };

        final result = parser.parse(
          'Prefix {icon} Suffix',
          mockContext,
          baseStyle,
          placeholders: placeholders,
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

      testWidgets('inserts TextSpan at {key} and preserves style', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        const baseStyle = TextStyle(color: Colors.black);
        final placeholders = {
          'user': const TextSpan(text: 'Inserted', style: TextStyle(color: Colors.red)),
        };

        final result = parser.parse(
          'Hello {user}',
          mockContext,
          baseStyle,
          placeholders: placeholders,
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

      testWidgets('supports numeric keys via Map strings', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        // Migration case: user changes List to Map but keeps "0" as key
        final placeholders = {
          '0': const TextSpan(text: 'Zero'),
        };

        final result = parser.parse(
          'Index {0}',
          mockContext,
          const TextStyle(),
          placeholders: placeholders,
        );

        expect(result.length, 2);
        final wrapperSpan = result[1] as TextSpan;
        final children = wrapperSpan.children;
        expect(children, isNotEmpty);
        if (children != null) expect((children.first as TextSpan).text, 'Zero');
      });

      testWidgets('supports alphanumeric keys with underscores', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final placeholders = {
          'my_icon_1': const TextSpan(text: 'Complex'),
        };

        final result = parser.parse(
          'Val: {my_icon_1}',
          mockContext,
          const TextStyle(),
          placeholders: placeholders,
        );

        expect(result.length, 2);
        final wrapperSpan = result[1] as TextSpan;
        final children = wrapperSpan.children;
        expect(children, isNotEmpty);
        if (children != null) expect((children.first as TextSpan).text, 'Complex');
      });
    });

    group('Bounds Checking & Error Handling', () {
      testWidgets('renders literal {key} if placeholders map is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));

        final result = parser.parse(
          'Hello {icon}',
          mockContext,
          const TextStyle(),
        );

        expect(result.length, 1);
        // The parser accumulates "Hello " then "{icon}" into the text buffer
        expect((result.first as TextSpan).text, 'Hello {icon}');
      });

      testWidgets('renders literal {key} if key is missing from map', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final placeholders = {'other': const TextSpan(text: 'Other')};

        final result = parser.parse(
          'Missing: {missing}',
          mockContext,
          const TextStyle(),
          placeholders: placeholders,
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Missing: {missing}');
      });

      testWidgets('renders literal if malformed inside (handled by tokenizer)', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        // Tokenizer should treat {a b} (spaces) as text, not placeholder token
        final result = parser.parse(
          'Val: {a b}',
          mockContext,
          const TextStyle(),
          placeholders: {},
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Val: {a b}');
      });
    });

    group('Style Inheritance', () {
      testWidgets('placeholder inherits surrounding bold style', (tester) async {
        await tester.pumpWidget(buildTestWidget(tester, (context) => Container()));
        final placeholders = {'world': const TextSpan(text: 'World')};

        final result = parser.parse(
          '**Hello {world}**',
          mockContext,
          const TextStyle(),
          placeholders: placeholders,
        );

        // Structure:
        // 1. "Hello " (Bold)
        // 2. {world} Wrapper (Bold) -> containing "World" (inherits Bold)

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
        final placeholders = {
          'icon': const WidgetSpan(child: Icon(Icons.link)),
        };

        final result = parser.parse(
          'Click [{icon} Here](https://url.com)',
          mockContext,
          const TextStyle(),
          placeholders: placeholders,
        );

        expect(result.length, 2); // "Click ", LinkWidget
        expect(result[1], isA<WidgetSpan>());

        final linkWidget = (result[1] as WidgetSpan).child as HoverableLinkSpan;

        // Verify link contents
        final linkChildren = linkWidget.initialChildrenSpans;
        // Expect: Wrapper({icon}), Text(" Here")
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
        final placeholders = {'0': const TextSpan(text: 'Hidden')};

        final result = parser.parse(
          r'Value \{0\}',
          mockContext,
          const TextStyle(),
          placeholders: placeholders,
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Value {0}');
      });
    });
  });
}
