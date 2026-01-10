// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/parser_state.dart';
import 'package:textf/src/parsing/components/link_handler.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';

// By using `extends`, we inherit the concrete implementation of TextfStyleResolver
// and only need to override the methods relevant to this test.
// ignore: prefer-match-file-name
class _MockLinkStyleResolver extends TextfStyleResolver {
  // We must call the super constructor.
  _MockLinkStyleResolver(super.context);

  @override
  TextStyle resolveLinkStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );
  }

  @override
  TextStyle resolveLinkHoverStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      color: Colors.red,
      decoration: TextDecoration.underline,
    );
  }

  @override
  MouseCursor resolveLinkMouseCursor() {
    return SystemMouseCursors.click;
  }

  @override
  void Function(String url, String displayText)? resolveOnLinkTap() => null;

  @override
  void Function(String url, String displayText, {required bool isHovering})? resolveOnLinkHover() =>
      null;
}

void main() {
  group('LinkHandler Tests', () {
    // ignore: avoid-late-keyword
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    // Helper to create a valid test environment with context and a parser state.
    Future<ParserState> createParserState(
      WidgetTester tester,
      String text,
    ) async {
      // ignore: avoid-late-keyword
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
        styleResolver: _MockLinkStyleResolver(buildContext),
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
        expect(nextIndex, 5, reason: 'Should return index after )');
        expect(state.spans.length, 1, reason: 'A WidgetSpan for the link should be created');
        expect(state.spans.first, isA<WidgetSpan>());

        final widgetSpan = state.spans.first as WidgetSpan;
        expect(widgetSpan.child, isA<HoverableLinkSpan>());

        final hoverableSpan = widgetSpan.child as HoverableLinkSpan;
        expect(hoverableSpan.url, 'http://example.com');
        expect(hoverableSpan.rawDisplayText, 'link text');
        expect(
          hoverableSpan.normalStyle.color,
          Colors.blue,
          reason: 'Normal style should come from mock resolver',
        );
      });
    });

    group('processLink: Invalid Links', () {
      testWidgets('returns null for unclosed bracket', (tester) async {
        // ARRANGE
        const text = '[unclosed bracket';
        final state = await createParserState(tester, text);

        // ACT
        final nextIndex = LinkHandler.processLink(state.styleResolver.context, state, 0);

        // ASSERT
        expect(nextIndex, isNull, reason: 'Should return null for invalid link');
        expect(state.spans, isEmpty, reason: 'No span should be created');
        expect(
          state.textBuffer,
          isEmpty,
          reason: 'LinkHandler should NOT modify textBuffer on failure (caller handles it)',
        );
      });

      testWidgets('returns null for text followed by non-link characters', (tester) async {
        // ARRANGE
        const text = '[link text] but not a url';
        final state = await createParserState(tester, text);

        // ACT
        final nextIndex = LinkHandler.processLink(state.styleResolver.context, state, 0);

        // ASSERT
        expect(nextIndex, isNull);
        expect(state.spans, isEmpty);
        expect(state.textBuffer, isEmpty);
      });
    });

    group('normalizeUrl', () {
      test('adds https:// to URLs without a scheme', () {
        expect(LinkHandler.normalizeUrl('example.com'), 'https://example.com');
      });

      test('does not modify URLs that already have a scheme (https)', () {
        expect(LinkHandler.normalizeUrl('https://example.com'), 'https://example.com');
      });

      test('does not modify URLs that already have a scheme (ftp)', () {
        expect(LinkHandler.normalizeUrl('ftp://example.com'), 'ftp://example.com');
      });

      test('does not modify URLs that already have a scheme (mailto)', () {
        expect(LinkHandler.normalizeUrl('mailto:test@example.com'), 'mailto:test@example.com');
      });

      test('does not modify URLs that already have a scheme (tel)', () {
        expect(LinkHandler.normalizeUrl('tel:+1234567890'), 'tel:+1234567890');
      });

      test('does not modify relative paths', () {
        expect(LinkHandler.normalizeUrl('/path/to/page'), '/path/to/page');
      });

      test('does not modify anchor links', () {
        expect(LinkHandler.normalizeUrl('#section1'), '#section1');
      });

      test('trims whitespace from URLs', () {
        expect(LinkHandler.normalizeUrl('  example.com  '), 'https://example.com');
      });

      test('handles empty strings', () {
        expect(LinkHandler.normalizeUrl(''), '');
      });
    });
  });
}
