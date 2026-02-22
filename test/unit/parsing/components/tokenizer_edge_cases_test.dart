// ignore_for_file: avoid-late-keyword, no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

void main() {
  group('TextfTokenizer Edge Cases', () {
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    group('Escape sequence edge cases', () {
      test('handles escape character at end of string', () {
        const text = r'trailing escape\';
        final tokens = tokenizer.tokenize(text);

        // Escape at end should be treated as literal backslash
        expect(tokens.length, 1);
        expect(tokens.first, isA<TextToken>());
        expect((tokens.first as TextToken).value, r'trailing escape\');
      });

      test('handles standalone escape without escapable char', () {
        const text = r'normal \n text';
        final tokens = tokenizer.tokenize(text);

        // \n is not an escapable formatting char, treat as literal
        expect(tokens.length, 1);
        expect(tokens.first, isA<TextToken>());
        expect((tokens.first as TextToken).value, r'normal \n text');
      });

      test('handles multiple consecutive escapes', () {
        const text = r'\\\\';
        final tokens = tokenizer.tokenize(text);

        // \\\\ should produce two literal backslashes
        expect(tokens.length, 2);
        expect((tokens.first as TextToken).value, r'\');
        expect((tokens[1] as TextToken).value, r'\');
      });

      test('handles escape before non-formatting punctuation', () {
        const text = r'price is \$100';
        final tokens = tokenizer.tokenize(text);

        // \$ should remain as literal \$
        expect(tokens.length, 1);
        expect((tokens.first as TextToken).value, r'price is \$100');
      });
    });

    group('Incomplete marker patterns', () {
      test('handles single tilde as subscript marker', () {
        const text = 'H~2~O';
        final tokens = tokenizer.tokenize(text);

        expect(
          tokens.any((t) => t is FormatMarkerToken && t.markerType == FormatMarkerType.subscript),
          true,
        );
      });

      test('handles single plus as plain text', () {
        const text = '1 + 1 = 2';
        final tokens = tokenizer.tokenize(text);

        // Single + should not create underline marker
        expect(tokens.length, 1);
        expect(tokens.first, isA<TextToken>());
        expect((tokens.first as TextToken).value, '1 + 1 = 2');
      });

      test('handles single equals as plain text', () {
        const text = 'a = b';
        final tokens = tokenizer.tokenize(text);

        // Single = should not create highlight marker
        expect(tokens.length, 1);
        expect(tokens.first, isA<TextToken>());
      });
    });

    group('Malformed link patterns', () {
      test('handles open bracket without closing structure', () {
        const text = 'start [incomplete';
        final tokens = tokenizer.tokenize(text);

        // Should treat [ as plain text
        expect(tokens.any((t) => t is LinkStartToken), isFalse);
      });

      test('handles bracket without URL parentheses', () {
        const text = 'text [label] more';
        final tokens = tokenizer.tokenize(text);

        // [label] without (url) should be plain text
        expect(tokens.any((t) => t is LinkStartToken), isFalse);
      });

      test('handles unclosed URL parenthesis', () {
        const text = '[label](http://example.com';
        final tokens = tokenizer.tokenize(text);

        // Incomplete link should fall back to plain text
        expect(tokens.any((t) => t is LinkEndToken), isFalse);
      });
    });

    group('Malformed placeholder patterns', () {
      test('handles empty placeholder braces', () {
        const text = 'empty {} here';
        final tokens = tokenizer.tokenize(text);

        // {} should be plain text, not a placeholder
        expect(tokens.any((t) => t is PlaceholderToken), isFalse);
      });

      test('handles placeholder with spaces', () {
        const text = 'invalid {a b} placeholder';
        final tokens = tokenizer.tokenize(text);

        // {a b} should be plain text due to space
        expect(tokens.any((t) => t is PlaceholderToken), isFalse);
      });

      test('handles unclosed brace', () {
        const text = 'unclosed {key';
        final tokens = tokenizer.tokenize(text);

        expect(tokens.any((t) => t is PlaceholderToken), isFalse);
      });
    });
  });
}
