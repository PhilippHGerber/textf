// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';

void main() {
  group('Parser Placeholder Tests', () {
    // ignore: avoid-late-keyword
    late TextfParser parser;
    final resolver = TextfStyleResolver.withState(options: null);

    setUp(() {
      parser = TextfParser();
    });

    group('Basic Placeholder Insertion', () {
      test('inserts WidgetSpan at {key}', () {
        const baseStyle = TextStyle();
        final placeholders = {
          'icon': const WidgetSpan(child: SizedBox.square(dimension: 24)),
        };

        final result = parser.parse(
          'Prefix {icon} Suffix',
          baseStyle,
          resolver,
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

      test('inserts TextSpan at {key} and preserves style', () {
        const baseStyle = TextStyle(color: Color(0xFF000000));
        final placeholders = {
          'user': const TextSpan(
            text: 'Inserted',
            style: TextStyle(color: Color(0xFFF44336)),
          ),
        };

        final result = parser.parse(
          'Hello {user}',
          baseStyle,
          resolver,
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
          expect(insertedSpan.style?.color, const Color(0xFFF44336));
        }
      });

      test('supports numeric keys via Map strings', () {
        // Migration case: user changes List to Map but keeps "0" as key
        final placeholders = {
          '0': const TextSpan(text: 'Zero'),
        };

        final result = parser.parse(
          'Index {0}',
          const TextStyle(),
          resolver,
          placeholders: placeholders,
        );

        expect(result.length, 2);
        final wrapperSpan = result[1] as TextSpan;
        final children = wrapperSpan.children;
        expect(children, isNotEmpty);
        if (children != null) expect((children.first as TextSpan).text, 'Zero');
      });

      test('supports alphanumeric keys with underscores', () {
        final placeholders = {
          'my_icon_1': const TextSpan(text: 'Complex'),
        };

        final result = parser.parse(
          'Val: {my_icon_1}',
          const TextStyle(),
          resolver,
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
      test('renders literal {key} if placeholders map is null', () {
        final result = parser.parse('Hello {icon}', const TextStyle(), resolver);

        expect(result.length, 1);
        // The parser accumulates "Hello " then "{icon}" into the text buffer
        expect((result.first as TextSpan).text, 'Hello {icon}');
      });

      test('renders literal {key} if key is missing from map', () {
        final placeholders = {'other': const TextSpan(text: 'Other')};

        final result = parser.parse(
          'Missing: {missing}',
          const TextStyle(),
          resolver,
          placeholders: placeholders,
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Missing: {missing}');
      });

      test('renders literal if malformed inside (handled by tokenizer)', () {
        // Tokenizer should treat {a b} (spaces) as text, not placeholder token
        final result = parser.parse('Val: {a b}', const TextStyle(), resolver, placeholders: {});

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Val: {a b}');
      });
    });

    group('Style Inheritance', () {
      test('placeholder inherits surrounding bold style', () {
        final placeholders = {'world': const TextSpan(text: 'World')};

        final result = parser.parse(
          '**Hello {world}**',
          const TextStyle(),
          resolver,
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
      test('placeholder works inside link text', () {
        final placeholders = {
          'icon': const WidgetSpan(child: SizedBox.square(dimension: 24)),
        };

        final result = parser.parse(
          'Click [{icon} Here](https://url.com)',
          const TextStyle(),
          resolver,
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
      test('escaped brace is treated as text', () {
        final placeholders = {'0': const TextSpan(text: 'Hidden')};

        final result = parser.parse(
          r'Value \{0\}',
          const TextStyle(),
          resolver,
          placeholders: placeholders,
        );

        expect(result.length, 1);
        expect((result.first as TextSpan).text, 'Value {0}');
      });
    });
  });
}
