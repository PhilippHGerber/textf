// Tests for FormatStackEntry debug output.

// ignore_for_file: no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/format_stack_entry.dart';
import 'package:textf/src/models/textf_token.dart';

void main() {
  group('FormatStackEntry', () {
    test('toString returns readable format', () {
      const entry = FormatStackEntry(
        type: FormatMarkerType.bold,
        index: 5,
        matchingIndex: 10,
      );

      final str = entry.toString();

      expect(str, contains('bold'));
      expect(str, contains('5'));
    });

    test('stores all properties correctly', () {
      const entry = FormatStackEntry(
        type: FormatMarkerType.italic,
        index: 10,
        matchingIndex: 25,
      );

      expect(entry.type, FormatMarkerType.italic);
      expect(entry.index, 10);
      expect(entry.matchingIndex, 25);
    });
  });
}
