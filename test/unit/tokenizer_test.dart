// ignore_for_file: no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/parsing/textf_tokenizer.dart';

void main() {
  group('Tokenizer Tests', () {
    // ignore: avoid-late-keyword
    late TextfTokenizer tokenizer;

    setUp(() {
      tokenizer = TextfTokenizer();
    });

    group('Basic Tokenization', () {
      test('Empty text returns empty list', () {
        final tokens = tokenizer.tokenize('');
        expect(tokens, isEmpty);
      });

      test('Plain text returns single text token', () {
        final tokens = tokenizer.tokenize('plain text');
        expect(tokens.length, 1);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value, 'plain text');
        expect(tokens.first.position, 0);
        expect(tokens.first.length, 10);
      });

      test('Whitespace-only text returns single text token', () {
        final tokens = tokenizer.tokenize('   \t\n');
        expect(tokens.length, 1);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value, '   \t\n');
      });
    });

    group('Bold Formatting', () {
      test('Bold text with asterisks', () {
        final tokens = tokenizer.tokenize('This is **bold** text');
        expect(tokens.length, 5);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value, 'This is ');
        expect(tokens[1].type, TokenType.boldMarker);
        expect(tokens[1].value, '**');
        expect(tokens[2].type, TokenType.text);
        expect(tokens[2].value, 'bold');
        expect(tokens[3].type, TokenType.boldMarker);
        expect(tokens[3].value, '**');
        expect(tokens[4].type, TokenType.text);
        expect(tokens[4].value, ' text');
      });

      test('Bold text with underscores', () {
        final tokens = tokenizer.tokenize('This is __bold__ text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.boldMarker);
        expect(tokens[1].value, '__');
        expect(tokens[3].type, TokenType.boldMarker);
        expect(tokens[3].value, '__');
      });

      test('Bold marker at beginning of text', () {
        final tokens = tokenizer.tokenize('**Bold** at start');
        expect(tokens.length, 4);
        expect(tokens.first.type, TokenType.boldMarker);
        expect(tokens.first.value, '**');
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, 'Bold');
      });

      test('Bold marker at end of text', () {
        final tokens = tokenizer.tokenize('End with **bold**');
        expect(tokens.length, 4);
        expect(tokens[2].type, TokenType.text);
        expect(tokens[2].value, 'bold');
        expect(tokens[3].type, TokenType.boldMarker);
        expect(tokens[3].value, '**');
      });
    });

    group('Italic Formatting', () {
      test('Italic text with asterisks', () {
        final tokens = tokenizer.tokenize('This is *italic* text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.italicMarker);
        expect(tokens[1].value, '*');
        expect(tokens[3].type, TokenType.italicMarker);
        expect(tokens[3].value, '*');
      });

      test('Italic text with underscores', () {
        final tokens = tokenizer.tokenize('This is _italic_ text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.italicMarker);
        expect(tokens[1].value, '_');
        expect(tokens[3].type, TokenType.italicMarker);
        expect(tokens[3].value, '_');
      });

      test('Italic marker at beginning of text', () {
        final tokens = tokenizer.tokenize('*Italic* at start');
        expect(tokens.length, 4);
        expect(tokens.first.type, TokenType.italicMarker);
        expect(tokens.first.value, '*');
      });

      test('Italic marker at end of text', () {
        final tokens = tokenizer.tokenize('End with _italic_');
        expect(tokens.length, 4);
        expect(tokens[3].type, TokenType.italicMarker);
        expect(tokens[3].value, '_');
      });
    });

    group('Bold-Italic Formatting', () {
      test('Bold-italic text with asterisks', () {
        final tokens = tokenizer.tokenize('This is ***bold-italic*** text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.boldItalicMarker);
        expect(tokens[1].value, '***');
        expect(tokens[3].type, TokenType.boldItalicMarker);
        expect(tokens[3].value, '***');
      });

      test('Bold-italic text with underscores', () {
        final tokens = tokenizer.tokenize('This is ___bold-italic___ text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.boldItalicMarker);
        expect(tokens[1].value, '___');
        expect(tokens[3].type, TokenType.boldItalicMarker);
        expect(tokens[3].value, '___');
      });
    });

    group('Strikethrough Formatting', () {
      test('Strikethrough text', () {
        final tokens = tokenizer.tokenize('This is ~~strikethrough~~ text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.strikeMarker);
        expect(tokens[1].value, '~~');
        expect(tokens[3].type, TokenType.strikeMarker);
        expect(tokens[3].value, '~~');
      });

      test('Single tilde is recognized as subscript marker', () {
        final tokens = tokenizer.tokenize('This is ~subscript~ text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.subscriptMarker);
        expect(tokens[1].value, '~');
        expect(tokens[3].type, TokenType.subscriptMarker);
        expect(tokens[3].value, '~');
      });
    });

    group('Script Formatting', () {
      test('Superscript text', () {
        final tokens = tokenizer.tokenize('This is ^superscript^ text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.superscriptMarker);
        expect(tokens[1].value, '^');
        expect(tokens[3].type, TokenType.superscriptMarker);
        expect(tokens[3].value, '^');
      });

      test('Subscript text', () {
        final tokens = tokenizer.tokenize('This is ~subscript~ text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.subscriptMarker);
        expect(tokens[1].value, '~');
        expect(tokens[3].type, TokenType.subscriptMarker);
        expect(tokens[3].value, '~');
      });
    });

    group('Code Formatting', () {
      test('Inline code', () {
        final tokens = tokenizer.tokenize('This is `code` text');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.codeMarker);
        expect(tokens[1].value, '`');
        expect(tokens[3].type, TokenType.codeMarker);
        expect(tokens[3].value, '`');
      });

      test('Code with internal backticks is correctly tokenized', () {
        final tokens = tokenizer.tokenize(r'This `code has \` character` inside');
        // The tokenizer just identifies the markers, it doesn't validate pairing
        expect(tokens.length, 7);
        expect(tokens[1].type, TokenType.codeMarker);
        expect(tokens[3].type, TokenType.text);
        expect(tokens[4].value, ' character');
        expect(tokens[5].type, TokenType.codeMarker);
      });
    });

    group('Escape Sequences', () {
      test('Escaped asterisk', () {
        final tokens = tokenizer.tokenize(r'This is \*not italic\*');
        expect(tokens.length, 4);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value, 'This is ');
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, '*');
        expect(tokens[2].type, TokenType.text);
        expect(tokens[2].value, 'not italic');
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '*');
      });

      test('Escaped underscore', () {
        final tokens = tokenizer.tokenize(r'This is \_not italic\_');
        expect(tokens.length, 4);
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, '_');
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '_');
      });

      test('Escaped tilde', () {
        final tokens = tokenizer.tokenize(r'This is \~not tilde\~');
        expect(tokens.length, 4);
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, '~');
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '~');
      });

      test('Escaped backtick', () {
        final tokens = tokenizer.tokenize(r'This is \`not code\`');
        expect(tokens.length, 4);
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, '`');
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '`');
      });

      test('Escaped backslash', () {
        final tokens = tokenizer.tokenize(r'This is \\backslash');
        expect(tokens.length, 3);
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, r'\');
      });

      test('Multiple escaped characters', () {
        final tokens = tokenizer.tokenize(r'This has \*\*\* many escapes');
        expect(tokens.length, 5);
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, '*');
        expect(tokens[2].type, TokenType.text);
        expect(tokens[2].value, '*');
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, '*');
      });

      test('Escape followed by non-special character is treated literally', () {
        final tokens = tokenizer.tokenize(r'This has \a normal character');
        expect(tokens.length, 1);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value, r'This has \a normal character');
      });

      test('Escape at end of string is preserved', () {
        final tokens = tokenizer.tokenize(r'Text ending with backslash \');
        expect(tokens.length, 1);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value, r'Text ending with backslash \');
      });
    });

    group('Nested Formatting Markers', () {
      test('Bold with nested italic using different marker types', () {
        final tokens = tokenizer.tokenize('**Bold with _nested italic_**');
        expect(tokens.length, 6);
        expect(tokens.first.type, TokenType.boldMarker);
        expect(tokens.first.value, '**');
        expect(tokens[1].type, TokenType.text);
        expect(tokens[1].value, 'Bold with ');
        expect(tokens[2].type, TokenType.italicMarker);
        expect(tokens[2].value, '_');
        expect(tokens[3].type, TokenType.text);
        expect(tokens[3].value, 'nested italic');
        expect(tokens[4].type, TokenType.italicMarker);
        expect(tokens[4].value, '_');
        expect(tokens[5].type, TokenType.boldMarker);
        expect(tokens[5].value, '**');
      });

      test('Bold with nested italic using same marker type (fails)', () {
        final tokens = tokenizer.tokenize('**Bold with *nested italic***');
        // Document the expected behavior for the non-working case
        expect(tokens.length, 5);
        // The tokenizer still identifies all markers, but the parser
        // will struggle with proper nesting when using same marker type
      });
    });

    group('Complex Scenarios', () {
      test('Multiple formats in one text', () {
        final tokens = tokenizer.tokenize('**Bold** and *italic* and `code` and ~~strike~~');
        expect(tokens.length, 15);

        // Check each formatting type appears
        final tokenTypes = tokens.map((t) => t.type).toList();
        expect(tokenTypes.contains(TokenType.boldMarker), true);
        expect(tokenTypes.contains(TokenType.italicMarker), true);
        expect(tokenTypes.contains(TokenType.codeMarker), true);
        expect(tokenTypes.contains(TokenType.strikeMarker), true);
      });

      test('Adjacent markers', () {
        final tokens = tokenizer.tokenize('**Bold**_Italic_');
        expect(tokens.length, 6);
        expect(tokens.first.type, TokenType.boldMarker);
        expect(tokens[2].type, TokenType.boldMarker);
        expect(tokens[3].type, TokenType.italicMarker);
        expect(tokens[5].type, TokenType.italicMarker);
      });

      test('Mixed markers with whitespace', () {
        final tokens = tokenizer.tokenize('** Bold** *Italic * ~~Strike ~~ `Code`');
        expect(tokens.length, 15);
      });

      test('Potential nested formatting (tokenizer handles without validation)', () {
        final tokens = tokenizer.tokenize('**Bold with _nested italic_**');
        expect(tokens.length, 6);
        expect(tokens.first.type, TokenType.boldMarker);
        expect(tokens[2].type, TokenType.italicMarker);
        expect(tokens[4].type, TokenType.italicMarker);
        expect(tokens[5].type, TokenType.boldMarker);
      });

      test('Unmatched opening markers', () {
        final tokens = tokenizer.tokenize('This **is unmatched');
        expect(tokens.length, 3);
        expect(tokens[1].type, TokenType.boldMarker);
        expect(tokens[1].value, '**');
      });

      test('Unmatched closing markers', () {
        final tokens = tokenizer.tokenize('This is unmatched**');
        expect(tokens.length, 2);
        expect(tokens[1].type, TokenType.boldMarker);
        expect(tokens[1].value, '**');
      });
    });

    group('Edge Cases', () {
      test('Unicode characters', () {
        final tokens = tokenizer.tokenize('Unicode: **你好** and *表情符号* ~~删除线~~');
        expect(tokens.length, 12);
        expect(tokens[2].type, TokenType.text);
        expect(tokens[2].value, '你好');
      });

      test('Emoji', () {
        final tokens = tokenizer.tokenize('Emoji: **😀** and *🌍* ~~🚫~~');
        expect(tokens.length, 12);
        expect(tokens[2].type, TokenType.text);
        expect(tokens[2].value, '😀');
      });

      test('Line breaks', () {
        final tokens = tokenizer.tokenize('Line\nbreak with **bold**\nformatting');
        expect(tokens.length, 5);
      });

      test('Tabs and special whitespace', () {
        final tokens = tokenizer.tokenize('Tab\t**bold**\tand space');
        expect(tokens.length, 5);
      });

      test('Single asterisk/underscore in text (not formatting)', () {
        final tokens = tokenizer.tokenize(
          'This * is not formatting and neither is this _ character',
        );
        expect(tokens.length, 5);
        expect(tokens.first.type, TokenType.text);
        expect(tokens[1].type, TokenType.italicMarker);
        expect(tokens[3].type, TokenType.italicMarker);
      });

      test('Very long input with no formatting', () {
        final longText = 'A' * 10000;
        final tokens = tokenizer.tokenize(longText);
        expect(tokens.length, 1);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value.length, 10000);
      });

      test('Very long input with formatting', () {
        final longPrefix = 'A' * 5000;
        final longSuffix = 'B' * 5000;
        final tokens = tokenizer.tokenize('$longPrefix**bold**$longSuffix');
        expect(tokens.length, 5);
        expect(tokens.first.type, TokenType.text);
        expect(tokens.first.value.length, 5000);
        expect(tokens[4].type, TokenType.text);
        expect(tokens[4].value.length, 5000);
      });
    });

    group('Performance Concerns', () {
      test('Many formatting markers', () {
        final manyMarkers = List.generate(100, (i) => '**bold$i**').join(' ');
        final tokens = tokenizer.tokenize(manyMarkers);
        expect(
          tokens.length,
          399,
        ); // 200 (100 pairs) of markers + 100 text segments + 99 spaces
      });

      test('Alternating character formatting', () {
        // This is a pathological case: b*o*l*d* (every character has a marker)
        final text = List.generate(100, (i) => '${String.fromCharCode(i + 97)}*').join();
        final tokens = tokenizer.tokenize(text);
        expect(tokens.length > 100, true);
      });
    });
  });
}
