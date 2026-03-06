// ignore_for_file: cascade_invocations for readability and chaining methods.

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/formatting_utils.dart';

void main() {
  group('FormattingUtils Tests', () {
    group('hasFormatting', () {
      // Test cases for characters that should return true.
      final Map<String, String> positiveCases = {
        'asterisk': 'an *italic* example',
        'underscore': 'an _italic_ example',
        'tilde': 'a ~~strike~~ example',
        'backtick': 'some `code` example',
        'equals': 'a ==highlight== example',
        'plus': 'an ++underline++ example',
        'caret': 'a ^superscript^ example',
        'escape': r'an \escaped char',
        'link start ([)': 'a [link] example',
        'placeholder start ({)': 'a {0} placeholder',
      };

      positiveCases.forEach((description, text) {
        test('should return true for strings containing $description', () {
          expect(FormattingUtils.hasFormatting(text), isTrue);
        });
      });

      // Test cases for characters that SHOULD return false (performance optimization).
      // These characters are only meaningful if preceded by a valid opener,
      // so the tokenizer shouldn't even start if only these are present.
      final Map<String, String> negativeCases = {
        'plain text': 'This is just a regular sentence.',
        'empty string': '',
        'close bracket only (])': 'a link] without start',
        'open paren only (()': 'text (with parens)',
        'close paren only ())': 'text with parens)',
        'close brace only (})': 'text with } brace',
      };

      negativeCases.forEach((description, text) {
        test('should return false for $description', () {
          expect(FormattingUtils.hasFormatting(text), isFalse);
        });
      });
    });

    group('stripFormatting', () {
      group('no-op paths', () {
        test('empty string returns empty string', () {
          expect(FormattingUtils.stripFormatting(''), '');
        });

        test('plain text with no markers returns unchanged', () {
          const text = 'This is just a regular sentence.';
          expect(FormattingUtils.stripFormatting(text), text);
        });
      });

      group('all format types stripped', () {
        final Map<String, (String, String)> cases = {
          'bold (**)': ('**bold**', 'bold'),
          'bold (__)': ('__bold__', 'bold'),
          'italic (*)': ('*italic*', 'italic'),
          'italic (_)': ('_italic_', 'italic'),
          'bold+italic (***)': ('***both***', 'both'),
          'bold+italic (___)': ('___both___', 'both'),
          'strikethrough': ('~~strike~~', 'strike'),
          'code': ('`code`', 'code'),
          'highlight': ('==highlight==', 'highlight'),
          'underline': ('++underline++', 'underline'),
          'superscript': ('^super^', 'super'),
          'subscript': ('~sub~', 'sub'),
        };

        cases.forEach((description, testCase) {
          final (input, expected) = testCase;
          test('strips $description', () {
            expect(
              FormattingUtils.stripFormatting(input),
              expected,
              reason: '"$input" should strip markers and return "$expected"',
            );
          });
        });
      });

      group('links', () {
        test('extracts link display text', () {
          expect(FormattingUtils.stripFormatting('[text](url)'), 'text');
        });

        test('extracts link text with nested bold', () {
          expect(FormattingUtils.stripFormatting('[**bold**](url)'), 'bold');
        });

        test('broken link — no separator — preserves literal bracket', () {
          expect(FormattingUtils.stripFormatting('[no close'), '[no close');
        });

        test('orphaned separator is preserved as literal text', () {
          expect(FormattingUtils.stripFormatting('just ](url) text'), 'just ](url) text');
        });

        test('link with empty text is treated as broken — full syntax preserved', () {
          // _isCompleteLink requires non-empty link text; broken path writes
          // each token literally: '[' + '](' + 'url' + ')'
          expect(FormattingUtils.stripFormatting('[](url)'), '[](url)');
        });
      });

      group('unpaired markers preserved', () {
        test('single asterisk between numbers', () {
          expect(FormattingUtils.stripFormatting('2 * 3 = 6'), '2 * 3 = 6');
        });

        test('unclosed italic marker preserved', () {
          expect(FormattingUtils.stripFormatting('*not closed'), '*not closed');
        });
      });

      group('placeholders preserved', () {
        test('standalone placeholder preserved', () {
          expect(FormattingUtils.stripFormatting('{icon}'), '{icon}');
        });

        test('placeholder in sentence preserved', () {
          expect(
            FormattingUtils.stripFormatting('hello {name} world'),
            'hello {name} world',
          );
        });
      });

      group('escape handling', () {
        test('backslash stripped, escaped character preserved', () {
          expect(FormattingUtils.stripFormatting(r'\*not italic\*'), '*not italic*');
        });
      });

      group('mixed content', () {
        test('bold and link combined', () {
          expect(
            FormattingUtils.stripFormatting('**bold** and [link](url)'),
            'bold and link',
          );
        });

        test('multiple format types in sentence', () {
          expect(
            FormattingUtils.stripFormatting('**Hello** [World](url)!'),
            'Hello World!',
          );
        });
      });
    });

    group('hasFormattingMarkers', () {
      // Test cases for characters that imply styling (bold, italic, etc)
      // but NOT structural elements like links or placeholders.
      final Map<String, String> positiveCases = {
        'asterisk': 'an *italic* example',
        'underscore': 'an _italic_ example',
        'tilde': 'a ~~strike~~ example',
        'backtick': 'some `code` example',
        'equals': 'a ==highlight== example',
        'plus': 'an ++underline++ example',
        'caret': 'a ^superscript^ example',
        'escape': r'an \escaped char',
      };

      positiveCases.forEach((description, text) {
        test('should return true for strings containing styling marker: $description', () {
          expect(FormattingUtils.hasFormattingMarkers(text), isTrue);
        });
      });

      test('should return false for strings with only link/placeholder syntax', () {
        const structuralOnly = 'This is text with [brackets] and {braces} and (parens)';
        expect(
          FormattingUtils.hasFormattingMarkers(structuralOnly),
          isFalse,
          reason: 'Brackets, braces, and parens are not styling markers.',
        );
      });

      test('should return false for plain text', () {
        const plainText = 'This is just a regular sentence.';
        expect(FormattingUtils.hasFormattingMarkers(plainText), isFalse);
      });
    });
  });
}
