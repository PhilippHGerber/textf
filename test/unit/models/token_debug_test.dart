// Tests for TextfToken and subclass debug/toString methods.

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/textf_token.dart';

void main() {
  group('Token Debug Output', () {
    test('Token.toString returns readable format', () {
      const token = FormatMarkerToken(FormatMarkerType.bold, '**', position: 10, length: 2);

      final str = token.toString();

      expect(str, contains('bold'));
      expect(str, contains('**'));
      expect(str, contains('10'));
    });

    test('Token.toString handles text tokens', () {
      const token = TextToken('hello world', position: 0, length: 11);

      final str = token.toString();

      expect(str, contains('Text'));
      expect(str, contains('hello world'));
    });

    test('Token.toString handles special characters in value', () {
      const token = TextToken('line\nbreak', position: 0, length: 10);

      // Should not throw
      final str = token.toString();
      expect(str, isNotEmpty);
    });
  });
}
