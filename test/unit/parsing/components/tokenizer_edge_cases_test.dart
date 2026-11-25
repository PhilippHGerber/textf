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

        // \\\\ should produce two literal backslashes, each as
        // EscapeMarkerToken + TextToken("\") to preserve the character count.
        expect(tokens.length, 4);
        expect(tokens.first, isA<EscapeMarkerToken>());
        expect((tokens[1] as TextToken).value, r'\');
        expect(tokens[2], isA<EscapeMarkerToken>());
        expect((tokens[3] as TextToken).value, r'\');
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
      FormatMarkerToken markerAt(List<TextfToken> tokens, int position) => tokens.firstWhere(
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

      test('Unicode whitespaces are correctly recognized for flanking', () {
        // U+00A0 is Non-Breaking Space, U+3000 is Ideographic (Japanese) Space
        final tokens = tokenizer.tokenize('*\u00A0word\u3000*');

        final first = markerAt(tokens, 0);
        // Space follows the first asterisk, so it CANNOT open
        expect(first.canOpen, isFalse, reason: 'Should recognize NBSP as whitespace');

        final second = markerAt(tokens, 7);
        // Space precedes the second asterisk, so it CANNOT close
        expect(
          second.canClose,
          isFalse,
          reason: 'Should recognize Ideographic Space as whitespace',
        );
      });

      test('All supported Unicode whitespaces are correctly recognized for flanking', () {
        // A map of code units to their readable names for debugging if a test fails
        final testWhitespaces = <int, String>{
          // Standard ASCII
          0x0020: 'Space',
          0x0009: 'Tab',
          0x000A: 'Line Feed',
          0x000D: 'Carriage Return',
          // iOS/macOS Non-Breaking Space
          0x00A0: 'Non-Breaking Space (NBSP)',
          // Unicode Space Block (Testing boundaries and a middle value)
          0x2000: 'En Quad (Block Start)',
          0x2005: 'Four-Per-Em Space (Block Middle)',
          0x200A: 'Hair Space (Block End)',
          // Specific Formatting Whitespaces
          0x2028: 'Line Separator',
          0x2029: 'Paragraph Separator',
          0x202F: 'Narrow No-Break Space',
          0x205F: 'Medium Mathematical Space',
          // CJK Full-width
          0x3000: 'Ideographic (Japanese) Space',
        };

        for (final entry in testWhitespaces.entries) {
          final wsChar = String.fromCharCode(entry.key);
          final wsName = entry.value;
          final hexCode = entry.key.toRadixString(16).toUpperCase().padLeft(4, '0');

          // Construct string: '*' + whitespace + 'word' + whitespace + '*'
          final text = '*${wsChar}word$wsChar*';
          final tokens = tokenizer.tokenize(text);

          // 1. Check Opening Marker (Index 0)
          final first = markerAt(tokens, 0);
          expect(
            first.canOpen,
            isFalse,
            reason:
                'Should recognize $wsName (U+$hexCode) as whitespace following an opening marker',
          );

          // 2. Check Closing Marker (Index 7)
          // Breakdown: 0: *, 1: ws, 2-5: 'word', 6: ws, 7: *
          final second = markerAt(tokens, 7);
          expect(
            second.canClose,
            isFalse,
            reason:
                'Should recognize $wsName (U+$hexCode) as whitespace preceding a closing marker',
          );
        }
      });

      test('marker after a word and before punctuation cannot open', () {
        // 'Price*,' — '*' at 5: 'e' precedes, ',' follows. Followed by
        // punctuation, so it opens only after whitespace or punctuation.
        final marker = markerAt(tokenizer.tokenize('Price*, shipping'), 5);
        expect(marker.canOpen, isFalse);
        expect(marker.canClose, isTrue);
      });

      test('Unicode punctuation and symbols count as punctuation', () {
        // U+3002 ideographic full stop (Po), U+00A7 section sign (Po),
        // U+20AC euro sign (Sc).
        for (final punct in ['。', '§', '€']) {
          final marker = markerAt(tokenizer.tokenize('word*$punct'), 4);
          expect(marker.canOpen, isFalse, reason: 'U+${punct.codeUnitAt(0).toRadixString(16)}');
        }
      });

      test('punctuation outside the BMP is read as one code point', () {
        // U+1D11E musical symbol G clef (So), a surrogate pair. Before the
        // marker: '𝄞*word' — '*' at 2 is right after punctuation, so it can
        // open but, followed by a letter, not close.
        final before = markerAt(tokenizer.tokenize('\u{1D11E}*word'), 2);
        expect(before.canOpen, isTrue);
        expect(before.canClose, isFalse);

        final after = markerAt(tokenizer.tokenize('word*\u{1D11E}'), 4);
        expect(after.canOpen, isFalse);
        expect(after.canClose, isTrue);
      });

      test('underscore family never opens or closes inside a word', () {
        for (final marker in ['_', '__', '___']) {
          final token = markerAt(tokenizer.tokenize('file${marker}name'), 4);
          expect(token.canOpen, isFalse, reason: marker);
          expect(token.canClose, isFalse, reason: marker);
        }
      });

      test('underscore between a word and punctuation follows punctuation', () {
        // 'foo_.' — right-flanking only, and preceded by a letter: can close.
        final closer = markerAt(tokenizer.tokenize('foo_.'), 3);
        expect(closer.canOpen, isFalse);
        expect(closer.canClose, isTrue);
        // '._foo' — both-flanking after punctuation: can open.
        final opener = markerAt(tokenizer.tokenize('._foo'), 1);
        expect(opener.canOpen, isTrue);
      });

      test('asterisk keeps intraword emphasis', () {
        final marker = markerAt(tokenizer.tokenize('un*frigging'), 2);
        expect(marker.canOpen, isTrue);
        expect(marker.canClose, isTrue);
      });

      test('a letter outside the BMP is not punctuation', () {
        // U+1D400 mathematical bold capital A (Lu).
        final marker = markerAt(tokenizer.tokenize('word*\u{1D400}'), 4);
        expect(marker.canOpen, isTrue);
        expect(marker.canClose, isTrue);
      });
    });
  });
}
