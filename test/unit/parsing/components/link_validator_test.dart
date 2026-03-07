// ignore_for_file: avoid-non-null-assertion, no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/constants.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/components/link_validator.dart';

void main() {
  group('LinkValidator.isCompleteLink', () {
    group('complete links', () {
      test('recognizes valid [text](url) structure', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const TextToken('https://example.com', position: 12, length: 19),
          const LinkEndToken(position: 31, length: 1),
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isTrue);
      });

      test('recognizes [](url) with empty link text', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('', position: 1, length: 0),
          const LinkSeparatorToken(position: 1, length: 2),
          const TextToken('https://example.com', position: 3, length: 19),
          const LinkEndToken(position: 22, length: 1),
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isTrue);
      });

      test('recognizes [text]() with empty URL', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const TextToken('', position: 12, length: 0),
          const LinkEndToken(position: 12, length: 1),
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isTrue);
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

        expect(LinkValidator.isCompleteLink(tokens, 1), isTrue);
      });
    });

    group('incomplete links - array bounds', () {
      test('returns false when index + 4 exceeds array length', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('text', position: 1, length: 4),
          const LinkSeparatorToken(position: 5, length: 2),
          const TextToken('url', position: 7, length: 3),
          // Missing LinkEndToken
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
      });

      test('returns false when starting near end of array', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('text', position: 1, length: 4),
          const LinkSeparatorToken(position: 5, length: 2),
          // Not enough remaining tokens for index + 4
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
      });

      test('returns false when index alone is >= array length', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('text', position: 1, length: 4),
        ];

        // Try to access index 5 in a 2-element array
        expect(LinkValidator.isCompleteLink(tokens, 5), isFalse);
      });

      test('returns false for empty token list', () {
        final tokens = <TextfToken>[];

        expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
      });
    });

    group('incomplete links - wrong token types', () {
      test('returns false when index is not LinkStartToken', () {
        final tokens = [
          const TextToken('not a link start', position: 0, length: 15),
          const TextToken('link text', position: 15, length: 9),
          const LinkSeparatorToken(position: 24, length: 2),
          const TextToken('url', position: 26, length: 3),
          const LinkEndToken(position: 29, length: 1),
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
      });

      test(
        'returns false when index+1 is not TextToken',
        () {
          final tokens = [
            const LinkStartToken(position: 0, length: 1),
            const LinkStartToken(position: 1, length: 1), // Wrong type
            const LinkSeparatorToken(position: 2, length: 2),
            const TextToken('url', position: 4, length: 3),
            const LinkEndToken(position: 7, length: 1),
          ];

          expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
        },
      );

      test('returns false when index+2 is not LinkSeparatorToken', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const TextToken('not a separator', position: 10, length: 15),
          const TextToken('url', position: 25, length: 3),
          const LinkEndToken(position: 28, length: 1),
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
      });

      test('returns false when index+3 is not TextToken', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const LinkStartToken(position: 12, length: 1), // Wrong type
          const LinkEndToken(position: 13, length: 1),
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
      });

      test('returns false when index+4 is not LinkEndToken', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('link text', position: 1, length: 9),
          const LinkSeparatorToken(position: 10, length: 2),
          const TextToken('url', position: 12, length: 3),
          const TextToken('not end', position: 15, length: 7), // Wrong type
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isFalse);
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

        expect(LinkValidator.isCompleteLink(tokens, 0), isTrue);
        expect(LinkValidator.isCompleteLink(tokens, 5), isTrue);
      });

      test(
        'handles links with special URL characters',
        () {
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

          expect(LinkValidator.isCompleteLink(tokens, 0), isTrue);
        },
      );

      test('handles links with unicode in text and URL', () {
        final tokens = [
          const LinkStartToken(position: 0, length: 1),
          const TextToken('日本語テキスト', position: 1, length: 7),
          const LinkSeparatorToken(position: 8, length: 2),
          const TextToken('https://example.co.jp/日本語', position: 10, length: 26),
          const LinkEndToken(position: 36, length: 1),
        ];

        expect(LinkValidator.isCompleteLink(tokens, 0), isTrue);
      });
    });

    group('constants alignment', () {
      test(
        'uses correct offset constants to validate link structure',
        () {
          // Verify that the constants match expected offsets:
          // - kLinkTextOffset = 1 (tokens[index + 1] is text)
          // - kLinkSeparatorOffset = 2 (tokens[index + 2] is separator)
          // - kLinkUrlOffset = 3 (tokens[index + 3] is URL text)
          // - kLinkEndTokenOffset = 4 (tokens[index + 4] is end)
          final tokens = [
            const LinkStartToken(position: 0, length: 1),
            const TextToken('text', position: 1, length: 4),
            const LinkSeparatorToken(position: 5, length: 2),
            const TextToken('url', position: 7, length: 3),
            const LinkEndToken(position: 10, length: 1),
          ];

          // All these should be true for a complete link at index 0
          expect(tokens[kLinkTextOffset] is TextToken, isTrue);
          expect(tokens[kLinkSeparatorOffset] is LinkSeparatorToken, isTrue);
          expect(tokens[kLinkUrlOffset] is TextToken, isTrue);
          expect(tokens[kLinkEndTokenOffset] is LinkEndToken, isTrue);

          // And the LinkValidator should agree
          expect(LinkValidator.isCompleteLink(tokens, 0), isTrue);
        },
      );
    });
  });
}
