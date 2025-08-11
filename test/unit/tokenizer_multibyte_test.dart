// test/unit/tokenizer_multibyte_test.dart

// ignore_for_file: no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

void main() {
  group('TextfTokenizer Multi-byte Character Tests', () {
    // ignore: avoid-late-keyword
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    // This test directly verifies that using `substring` with code-unit-based
    // indices correctly extracts link text containing multi-byte emojis.
    // This test would fail if `characters.getRange` were used instead.
    test('Correctly tokenizes link text with a simple emoji', () {
      // ARRANGE
      const text = 'Link with [Hello 👋](http://example.com)';
      final tokens = tokenizer.tokenize(text);

      // ASSERT
      // Expected tokens: 'Link with ', '[', 'Hello 👋', '](', 'http://example.com', ')'
      expect(tokens.length, 6, reason: 'Should produce 6 distinct tokens');

      // Verify the type and value of each token
      expect(tokens.first.type, TokenType.text);
      expect(tokens.first.value, 'Link with ');

      expect(tokens[1].type, TokenType.linkStart);
      expect(tokens[1].value, '[');

      // --- CRITICAL ASSERTION for Link Text ---
      expect(
        tokens[2].type,
        TokenType.text,
        reason: 'The link display text should be a text token',
      );
      expect(
        tokens[2].value,
        'Hello 👋',
        reason: 'The extracted link text with emoji must be correct',
      );

      expect(tokens[3].type, TokenType.linkSeparator);
      expect(tokens[3].value, '](');

      expect(tokens[4].type, TokenType.text, reason: 'The URL should be a text token');
      expect(tokens[4].value, 'http://example.com');

      expect(tokens[5].type, TokenType.linkEnd);
      expect(tokens[5].value, ')');
    });

    // This test validates the correct handling of a URL containing multi-byte characters.
    test('Correctly tokenizes a link URL with a simple emoji', () {
      // ARRANGE
      const text = '[Link to Emoji URL](http://example.com/page-with-😊)';
      final tokens = tokenizer.tokenize(text);

      // ASSERT
      // Expected: '[', 'Link to Emoji URL', '](', 'http://example.com/page-with-😊', ')'
      expect(tokens.length, 5);

      // --- CRITICAL ASSERTION for Link URL ---
      expect(tokens[3].type, TokenType.text, reason: 'The URL part should be a text token');
      expect(
        tokens[3].value,
        'http://example.com/page-with-😊',
        reason: 'The extracted URL with emoji must be correct',
      );
    });

    // This test uses a complex, multi-code-unit emoji (a family emoji) to
    // further stress-test the index calculations.
    test('Correctly tokenizes link text with a complex emoji', () {
      // ARRANGE
      const text = '[Family emoji 👨‍👩‍👧‍👦 link](url)';
      final tokens = tokenizer.tokenize(text);

      // ASSERT
      expect(tokens.length, 5);

      // --- CRITICAL ASSERTION for Complex Emoji in Link Text ---
      expect(tokens[1].type, TokenType.text);
      expect(
        tokens[1].value,
        'Family emoji 👨‍👩‍👧‍👦 link',
        reason: 'The extracted text with a complex family emoji must be correct',
      );
    });

    // This test ensures that the start and end indices are calculated correctly
    // when emojis are at the very beginning and end of the link text.
    test('Correctly tokenizes link text surrounded by emojis', () {
      // ARRANGE
      const text = '[👋Surrounded👍](url)';
      final tokens = tokenizer.tokenize(text);

      // ASSERT
      expect(tokens.length, 5);

      // --- CRITICAL ASSERTION for Surrounded Text ---
      expect(tokens[1].type, TokenType.text);
      expect(
        tokens[1].value,
        '👋Surrounded👍',
        reason: 'The extracted text surrounded by emojis must be correct',
      );
    });

    test('Correctly tokenizes plain text with emojis outside of links', () {
      // ARRANGE
      const text = 'Plain text with emoji in it 😊. And another one 🚀.';
      final tokens = tokenizer.tokenize(text);

      // ASSERT
      // This is a sanity check to ensure that the `addTextToken` helper function,
      // which contains the `substring` call, works correctly for general text as well.
      // Since there are no formatting markers, it should produce a single text token.
      expect(tokens.length, 1);
      expect(tokens.first.type, TokenType.text);
      expect(tokens.first.value, text, reason: 'The entire string should be one text token');
    });
  });
}
