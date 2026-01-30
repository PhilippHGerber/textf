// Tests for Token and TokenType debug/toString methods.

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/token_type.dart';

void main() {
  group('Token Debug Output', () {
    test('Token.toString returns readable format', () {
      const token = Token(TokenType.boldMarker, '**', 10, 2);

      final str = token.toString();

      expect(str, contains('boldMarker'));
      expect(str, contains('**'));
      expect(str, contains('10'));
    });

    test('Token.toString handles text tokens', () {
      const token = Token(TokenType.text, 'hello world', 0, 11);

      final str = token.toString();

      expect(str, contains('text'));
      expect(str, contains('hello world'));
    });

    test('Token.toString handles special characters in value', () {
      const token = Token(TokenType.text, 'line\nbreak', 0, 10);

      // Should not throw
      final str = token.toString();
      expect(str, isNotEmpty);
    });
  });
}
