// ignore_for_file: cascade_invocations // cascade_invocations for readability and chaining methods.

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
        'escape': r'an \escaped char',
        'open bracket': 'a [link] example',
        'close bracket': 'a [link] example',
        'open paren': 'a link (url)',
        'close paren': 'a link (url)',
      };

      positiveCases.forEach((description, text) {
        test('should return true for strings containing: $description', () {
          expect(FormattingUtils.hasFormatting(text), isTrue);
        });
      });

      test('should return false for strings without any formatting characters', () {
        const plainText = 'This is just a regular sentence.';
        expect(FormattingUtils.hasFormatting(plainText), isFalse);
      });

      test('should return false for an empty string', () {
        const emptyText = '';
        expect(FormattingUtils.hasFormatting(emptyText), isFalse);
      });
    });

    group('hasFormattingMarkers', () {
      // Test cases for characters that should return true.
      final Map<String, String> positiveCases = {
        'asterisk': 'an *italic* example',
        'underscore': 'an _italic_ example',
        'tilde': 'a ~~strike~~ example',
        'backtick': 'some `code` example',
        'equals': 'a ==highlight== example',
        'plus': 'an ++underline++ example',
        'escape': r'an \escaped char',
      };

      positiveCases.forEach((description, text) {
        test('should return true for strings containing styling marker: $description', () {
          expect(FormattingUtils.hasFormattingMarkers(text), isTrue);
        });
      });

      test('should return false for strings with only link syntax characters', () {
        const linkSyntaxOnly = 'This is text with [brackets] and (parens)';
        expect(
          FormattingUtils.hasFormattingMarkers(linkSyntaxOnly),
          isFalse,
          reason: 'Brackets and parentheses are not considered styling markers.',
        );
      });

      test('should return false for strings without any styling markers', () {
        const plainText = 'This is just a regular sentence.';
        expect(FormattingUtils.hasFormattingMarkers(plainText), isFalse);
      });

      test('should return false for an empty string', () {
        const emptyText = '';
        expect(FormattingUtils.hasFormattingMarkers(emptyText), isFalse);
      });
    });
  });
}
