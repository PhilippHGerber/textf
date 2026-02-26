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

    group('Flanking flags', () {
      FormatMarkerToken markerAt(List<TextfToken> tokens, int position) =>
          tokens.firstWhere(
            (t) => t is FormatMarkerToken && t.position == position,
          ) as FormatMarkerToken;

      test('bullet asterisk at SOF followed by space: canOpen=false, canClose=false', () {
        final tokens = tokenizer.tokenize('* Item');
        final marker = markerAt(tokens, 0);
        expect(marker.canOpen, isFalse);
        expect(marker.canClose, isFalse);
      });

      test('math asterisk surrounded by spaces: canOpen=false, canClose=false', () {
        final tokens = tokenizer.tokenize('2 * 3');
        final marker = markerAt(tokens, 2);
        expect(marker.canOpen, isFalse);
        expect(marker.canClose, isFalse);
      });

      test('opening italic: canOpen=true, canClose=false', () {
        // '*text*' — first * at pos 0: SOF → canClose=false, 't' follows → canOpen=true
        final tokens = tokenizer.tokenize('*text*');
        final first = markerAt(tokens, 0);
        expect(first.canOpen, isTrue);
        expect(first.canClose, isFalse);
      });

      test('closing italic: canClose=true, canOpen=false', () {
        // '*text*' — second * at pos 5: 't' precedes → canClose=true, EOF → canOpen=false
        final tokens = tokenizer.tokenize('*text*');
        final second = markerAt(tokens, 5);
        expect(second.canClose, isTrue);
        expect(second.canOpen, isFalse);
      });

      test('opening bold: canOpen=true, canClose=false', () {
        final tokens = tokenizer.tokenize('**bold**');
        final first = markerAt(tokens, 0);
        expect(first.canOpen, isTrue);
        expect(first.canClose, isFalse);
      });

      test('closing bold: canClose=true, canOpen=false', () {
        final tokens = tokenizer.tokenize('**bold**');
        final second = markerAt(tokens, 6);
        expect(second.canClose, isTrue);
        expect(second.canOpen, isFalse);
      });

      test('mid-word asterisk: canOpen=true, canClose=true', () {
        // 'text*more' — * at pos 4: 't' precedes, 'm' follows
        final tokens = tokenizer.tokenize('text*more');
        final marker = markerAt(tokens, 4);
        expect(marker.canOpen, isTrue);
        expect(marker.canClose, isTrue);
      });

      test('asterisk preceded by space: canOpen=true, canClose=false', () {
        // 'text *more' — * at pos 5: space precedes → canClose=false
        final tokens = tokenizer.tokenize('text *more');
        final marker = markerAt(tokens, 5);
        expect(marker.canOpen, isTrue);
        expect(marker.canClose, isFalse);
      });

      test('asterisk followed by space: canClose=true, canOpen=false', () {
        // 'text* more' — * at pos 4: space follows → canOpen=false
        final tokens = tokenizer.tokenize('text* more');
        final marker = markerAt(tokens, 4);
        expect(marker.canClose, isTrue);
        expect(marker.canOpen, isFalse);
      });
    });
  });
}
