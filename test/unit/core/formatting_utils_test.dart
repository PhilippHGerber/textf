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
