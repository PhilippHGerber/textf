// test/unit/parsing/components/link_handler_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/parser_state.dart';
import 'package:textf/src/parsing/components/link_handler.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';

// By using `extends`, we inherit the concrete implementation of TextfStyleResolver
// and only need to override the methods relevant to this test. This is the correct
// way to mock a concrete class.
class MockLinkStyleResolver extends TextfStyleResolver {
  // We must call the super constructor.
  MockLinkStyleResolver(super.context);

  // Override only the methods needed to test the LinkHandler.
  // We want to control the output for link-related styles.
  @override
  TextStyle resolveLinkStyle(TextStyle baseStyle) {
    // Return a predictable, simple style for testing.
    return baseStyle.copyWith(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );
  }

  @override
  TextStyle resolveLinkHoverStyle(TextStyle baseStyle) {
    // Return a predictable hover style.
    return baseStyle.copyWith(
      color: Colors.red,
      decoration: TextDecoration.underline,
    );
  }

  @override
  MouseCursor resolveLinkMouseCursor() {
    // Return a predictable cursor.
    return SystemMouseCursors.click;
  }

  // For this test, tap and hover callbacks are not needed.
  @override
  void Function(String url, String displayText)? resolveOnUrlTap() => null;

  @override
  void Function(String url, String displayText, {required bool isHovering})? resolveOnUrlHover() => null;

  // We don't need to override `resolveStyle` because the LinkHandler
  // uses its own internal parser for nested content, but we could if needed.
}

void main() {
  group('LinkHandler Tests', () {
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    // Helper to create a valid test environment with context and a parser state.
    Future<ParserState> createParserState(
      WidgetTester tester,
      String text,
    ) async {
      late BuildContext buildContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              buildContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      return ParserState(
        tokens: tokenizer.tokenize(text),
        baseStyle: const TextStyle(),
        matchingPairs: {},
        // Use our new mock that `extends` TextfStyleResolver.
        styleResolver: MockLinkStyleResolver(buildContext),
      );
    }

    group('processLink: Valid Links', () {
      testWidgets('correctly processes a simple link', (tester) async {
        // ARRANGE
        const text = '[link text](http://example.com)';
        final state = await createParserState(tester, text);

        // ACT
        final nextIndex = LinkHandler.processLink(state.styleResolver.context, state, 0);

        // ASSERT
        expect(nextIndex, 5, reason: 'Should consume 5 tokens: [, text, ](, url, )');
        expect(state.spans.length, 1, reason: 'A WidgetSpan for the link should be created');
        expect(state.spans.first, isA<WidgetSpan>());

        final widgetSpan = state.spans.first as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());

        final hoverableSpan = widgetSpan.child as HoverableLinkSpan;
        expect(hoverableSpan.url, 'http://example.com');
        expect(hoverableSpan.rawDisplayText, 'link text');
        expect(hoverableSpan.normalStyle.color, Colors.blue, reason: 'Normal style should come from mock resolver');

        expect(state.processedIndices, {0, 1, 2, 3, 4}, reason: 'All link tokens should be marked as processed');
      });
    });

    group('processLink: Invalid Links', () {
      testWidgets('handles text that looks like a link but is not', (tester) async {
        // ARRANGE
        const text = '[unclosed bracket';
        final state = await createParserState(tester, text);

        // ACT
        final nextIndex = LinkHandler.processLink(state.styleResolver.context, state, 0);

        // ASSERT
        expect(nextIndex, isNull, reason: 'Should not process an incomplete link');
        expect(state.spans, isEmpty, reason: 'No span should be created');
        expect(state.textBuffer, '[', reason: 'The opening bracket should be treated as plain text');
        expect(state.processedIndices, {0}, reason: 'Only the opening bracket token should be marked as processed');
      });

      testWidgets('handles link text followed by non-link characters', (tester) async {
        // ARRANGE
        const text = '[link text] but not a url';
        final state = await createParserState(tester, text);

        // ACT
        final nextIndex = LinkHandler.processLink(state.styleResolver.context, state, 0);

        // ASSERT
        expect(nextIndex, isNull);
        expect(state.spans, isEmpty);
        expect(state.textBuffer, '[');
        expect(state.processedIndices, {0});
      });
    });

    group('_normalizeUrl', () {
      test('adds http:// to URLs without a scheme', () {
        expect(LinkHandler.normalizeUrl('example.com'), 'http://example.com');
      });

      test('does not modify URLs that already have a scheme', () {
        expect(LinkHandler.normalizeUrl('https://example.com'), 'https://example.com');
        expect(LinkHandler.normalizeUrl('ftp://example.com'), 'ftp://example.com');
        expect(LinkHandler.normalizeUrl('mailto:test@example.com'), 'mailto:test@example.com');
      });

      test('does not modify relative paths', () {
        expect(LinkHandler.normalizeUrl('/path/to/page'), '/path/to/page');
      });

      test('does not modify anchor links', () {
        expect(LinkHandler.normalizeUrl('#section1'), '#section1');
      });

      test('trims whitespace from URLs', () {
        expect(LinkHandler.normalizeUrl('  example.com  '), 'http://example.com');
      });
    });
  });
}
