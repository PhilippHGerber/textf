// ignore_for_file: no-magic-number
// Tests for toString methods on all TextfToken subclasses.

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';

void main() {
  group('TextfToken toString coverage', () {
    test('LinkStartToken.toString contains position', () {
      const token = LinkStartToken(position: 5, length: 1);
      final str = token.toString();
      expect(str, contains('LinkStartToken'));
      expect(str, contains('5'));
    });

    test('LinkSeparatorToken.toString contains position', () {
      const token = LinkSeparatorToken(position: 12, length: 2);
      final str = token.toString();
      expect(str, contains('LinkSeparatorToken'));
      expect(str, contains('12'));
    });

    test('LinkEndToken.toString contains position', () {
      const token = LinkEndToken(position: 20, length: 1);
      final str = token.toString();
      expect(str, contains('LinkEndToken'));
      expect(str, contains('20'));
    });

    test('PlaceholderToken.toString contains key and position', () {
      const token = PlaceholderToken('icon', position: 3, length: 6);
      final str = token.toString();
      expect(str, contains('PlaceholderToken'));
      expect(str, contains('icon'));
      expect(str, contains('3'));
    });
  });
}
