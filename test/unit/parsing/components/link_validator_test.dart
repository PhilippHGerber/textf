// ignore_for_file: avoid-non-null-assertion, no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/parsed_link.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/components/link_validator.dart';

void main() {
  group('ParsedLink', () {
    test('stores and exposes displayText, url, startPosition, and endPosition', () {
      const link = ParsedLink(
        displayText: 'example',
        url: 'https://example.com',
        startPosition: 5,
        endPosition: 30,
      );

      expect(link.displayText, 'example');
      expect(link.url, 'https://example.com');
      expect(link.startPosition, 5);
      expect(link.endPosition, 30);
    });

    test('value equality and hashCode', () {
      const link1 = ParsedLink(
        displayText: 'example',
        url: 'https://example.com',
        startPosition: 5,
        endPosition: 30,
      );
      const link2 = ParsedLink(
        displayText: 'example',
        url: 'https://example.com',
        startPosition: 5,
        endPosition: 30,
      );
      const linkDiffText = ParsedLink(
        displayText: 'other',
        url: 'https://example.com',
        startPosition: 5,
        endPosition: 30,
      );
      const linkDiffUrl = ParsedLink(
        displayText: 'example',
        url: 'https://other.com',
        startPosition: 5,
        endPosition: 30,
      );
      const linkDiffStart = ParsedLink(
        displayText: 'example',
        url: 'https://example.com',
        startPosition: 6,
        endPosition: 30,
      );
      const linkDiffEnd = ParsedLink(
        displayText: 'example',
        url: 'https://example.com',
        startPosition: 5,
        endPosition: 31,
      );

      expect(link1, equals(link2));
      expect(link1.hashCode, equals(link2.hashCode));

      expect(link1, isNot(equals(linkDiffText)));
      expect(link1, isNot(equals(linkDiffUrl)));
      expect(link1, isNot(equals(linkDiffStart)));
      expect(link1, isNot(equals(linkDiffEnd)));
    });

    test('toString includes all fields', () {
      const link = ParsedLink(
        displayText: 'text',
        url: 'url',
        startPosition: 0,
        endPosition: 10,
      );

      expect(
        link.toString(),
        'ParsedLink(displayText: "text", url: "url", startPosition: 0, endPosition: 10)',
      );
    });
  });

  group('LinkValidator.validate', () {
    group('complete links', () {
      test('recognizes valid [text](url) structure and returns ParsedLink', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const TextToken('https://example.com', position: 12, length: 19),
          const LinkEndToken(position: 31, length: 1),
        ];

        final parsed = LinkValidator.validate(tokens, 0);
        expect(parsed, isNotNull);
        expect(parsed!.displayText, 'link text');
        expect(parsed.url, 'https://example.com');
        expect(parsed.startPosition, 0);
        expect(parsed.endPosition, 32);
        expect(
          parsed,
          equals(
            const ParsedLink(
              displayText: 'link text',
              url: 'https://example.com',
              startPosition: 0,
              endPosition: 32,
            ),
          ),
        );
      });

      test('recognizes [](url) with empty link text', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('', position: 1, length: 0),
          const LinkSeparatorToken(position: 1, length: 2),
          const TextToken('https://example.com', position: 3, length: 19),
          const LinkEndToken(position: 22, length: 1),
        ];

        final parsed = LinkValidator.validate(tokens, 0);
        expect(parsed, isNotNull);
        expect(parsed!.displayText, '');
        expect(parsed.url, 'https://example.com');
        expect(parsed.startPosition, 0);
        expect(parsed.endPosition, 23);
      });

      test('recognizes [text]() with empty URL', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const TextToken('', position: 12, length: 0),
          const LinkEndToken(position: 12, length: 1),
        ];

        final parsed = LinkValidator.validate(tokens, 0);
        expect(parsed, isNotNull);
        expect(parsed!.displayText, 'link text');
        expect(parsed.url, '');
        expect(parsed.startPosition, 0);
        expect(parsed.endPosition, 13);
      });

      test('recognizes link when starting at non-zero index', () {
        final tokens = [
          const TextToken('prefix', position: 0, length: 6),
          const LinkStartToken(position: 6, length: 1),
          const TextToken('link text', position: 7, length: 9),
          const LinkSeparatorToken(position: 16, length: 2),
          const TextToken('url', position: 18, length: 3),
          const LinkEndToken(position: 21, length: 1),
          const TextToken('suffix', position: 22, length: 6),
        ];

        final parsed = LinkValidator.validate(tokens, 1);
        expect(parsed, isNotNull);
        expect(parsed!.displayText, 'link text');
        expect(parsed.url, 'url');
        expect(parsed.startPosition, 6);
        expect(parsed.endPosition, 22);
      });
    });

    group('incomplete links - array bounds', () {
      test('returns null when index + 4 exceeds array length', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('text', position: 1, length: 4),
          const LinkSeparatorToken(position: 5, length: 2),
          const TextToken('url', position: 7, length: 3),
          // Missing LinkEndToken
        ];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });

      test('returns null when starting near end of array', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('text', position: 1, length: 4),
          const LinkSeparatorToken(position: 5, length: 2),
          // Not enough remaining tokens for index + 4
        ];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });

      test('returns null when index alone is >= array length', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('text', position: 1, length: 4),
        ];

        // Try to access index 5 in a 2-element array
        expect(LinkValidator.validate(tokens, 5), isNull);
      });

      test('returns null for negative index', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('text', position: 1, length: 4),
          const LinkSeparatorToken(position: 5, length: 2),
          const TextToken('url', position: 7, length: 3),
          const LinkEndToken(position: 10, length: 1),
        ];

        expect(LinkValidator.validate(tokens, -1), isNull);
      });

      test('returns null for empty token list', () {
        final tokens = <TextfToken>[];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });
    });

    group('incomplete links - wrong token types', () {
      test('returns null when index is not LinkStartToken', () {
        final tokens = [
          const TextToken('not a link start', position: 0, length: 15),
          const TextToken('link text', position: 15, length: 9),
          const LinkSeparatorToken(position: 24, length: 2),
          const TextToken('url', position: 26, length: 3),
          const LinkEndToken(position: 29, length: 1),
        ];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });

      test('returns null when index+1 is not TextToken', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const LinkStartToken(position: 1, length: 1), // Wrong type
          const LinkSeparatorToken(position: 2, length: 2),
          const TextToken('url', position: 4, length: 3),
          const LinkEndToken(position: 7, length: 1),
        ];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });

      test('returns null when index+2 is not LinkSeparatorToken', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const TextToken('not a separator', position: 10, length: 15),
          const TextToken('url', position: 25, length: 3),
          const LinkEndToken(position: 28, length: 1),
        ];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });

      test('returns null when index+3 is not TextToken', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const LinkStartToken(position: 12, length: 1), // Wrong type
          const LinkEndToken(position: 13, length: 1),
        ];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });

      test('returns null when index+4 is not LinkEndToken', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const TextToken('url', position: 12, length: 3),
          const TextToken('not end', position: 15, length: 7), // Wrong type
        ];

        expect(LinkValidator.validate(tokens, 0), isNull);
      });
    });

    group('edge cases', () {
      test('correctly identifies second link in sequence of two', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('first', position: 1, length: 5),
          const LinkSeparatorToken(position: 6, length: 2),
          const TextToken('url1', position: 8, length: 4),
          const LinkEndToken(position: 12, length: 1),
          const LinkStartToken(position: 13, length: 1),
          const TextToken('second', position: 14, length: 6),
          const LinkSeparatorToken(position: 20, length: 2),
          const TextToken('url2', position: 22, length: 4),
          const LinkEndToken(position: 26, length: 1),
        ];

        final first = LinkValidator.validate(tokens, 0);
        final second = LinkValidator.validate(tokens, 5);

        expect(first, isNotNull);
        expect(first!.displayText, 'first');
        expect(first.url, 'url1');
        expect(first.startPosition, 0);
        expect(first.endPosition, 13);

        expect(second, isNotNull);
        expect(second!.displayText, 'second');
        expect(second.url, 'url2');
        expect(second.startPosition, 13);
        expect(second.endPosition, 27);
      });

      test('handles links with special URL characters', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('Visit', position: 1, length: 5),
          const LinkSeparatorToken(position: 6, length: 2),
          const TextToken(
            'https://example.com/path?query=value&other=123#fragment',
            position: 8,
            length: 58,
          ),
          const LinkEndToken(position: 66, length: 1),
        ];

        final parsed = LinkValidator.validate(tokens, 0);
        expect(parsed, isNotNull);
        expect(parsed!.displayText, 'Visit');
        expect(parsed.url, 'https://example.com/path?query=value&other=123#fragment');
        expect(parsed.startPosition, 0);
        expect(parsed.endPosition, 67);
      });

      test('handles links with unicode in text and URL', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('日本語テキスト', position: 1, length: 7),
          const LinkSeparatorToken(position: 8, length: 2),
          const TextToken('https://example.co.jp/日本語', position: 10, length: 26),
          const LinkEndToken(position: 36, length: 1),
        ];

        final parsed = LinkValidator.validate(tokens, 0);
        expect(parsed, isNotNull);
        expect(parsed!.displayText, '日本語テキスト');
        expect(parsed.url, 'https://example.co.jp/日本語');
        expect(parsed.startPosition, 0);
        expect(parsed.endPosition, 37);
      });
    });
  });
}
