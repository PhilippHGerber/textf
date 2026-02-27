// ignore_for_file: no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

void main() {
  final tokenizer = TextfTokenizer();

  group('Tokenizer link edge cases', () {
    test('escape inside link text is handled', () {
      // [text\\]with](url) - escape inside link text
      final tokens = tokenizer.tokenize(r'[text\]with](url)');
      // Should produce link tokens since \] is escaped
      final hasLinkStart = tokens.any((t) => t is LinkStartToken);
      expect(hasLinkStart, isTrue);
    });

    test('nested brackets inside link text', () {
      // [text[nested]more](url)
      final tokens = tokenizer.tokenize('[text[nested]more](url)');
      final hasLinkStart = tokens.any((t) => t is LinkStartToken);
      expect(hasLinkStart, isTrue);
    });

    test('nested parentheses inside URL', () {
      // [link](url(nested))
      final tokens = tokenizer.tokenize('[link](url(nested))');
      final hasLinkEnd = tokens.any((t) => t is LinkEndToken);
      expect(hasLinkEnd, isTrue);
    });

    test('escape inside URL is handled', () {
      // [link](url\)more)
      final tokens = tokenizer.tokenize(r'[link](url\)more)');
      final hasLinkEnd = tokens.any((t) => t is LinkEndToken);
      expect(hasLinkEnd, isTrue);
    });

    test('bracket not followed by paren is not a link', () {
      // [text] without (url) should not produce link tokens
      final tokens = tokenizer.tokenize('[text] not a link');
      final hasLinkSeparator = tokens.any((t) => t is LinkSeparatorToken);
      expect(hasLinkSeparator, isFalse);
    });

    test('stalled loop guard advances position', () {
      // The safety guard at line 331 should handle edge cases
      // where no branch advances pos
      final tokens = tokenizer.tokenize('{');
      expect(tokens, isNotEmpty);
      // Single { should be treated as plain text
      final text = tokens.whereType<TextToken>().map((t) => t.value).join();
      expect(text, contains('{'));
    });
  });
}
