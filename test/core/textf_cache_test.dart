// ignore_for_file: cascade_invocations, no-magic-number, avoid-late-keyword, for simplicity in tests

import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/textf_cache.dart';

void main() {
  group('TextfCache', () {
    late TextfCache<String, int> cache;

    setUp(() {
      // Small limits for easy testing
      cache = TextfCache<String, int>(
        maxEntries: 3,
        maxTotalChars: 20,
        getCharCount: (key) => key.length,
      );
    });

    test('Entry Limit Validation - evicts oldest when exceeding maxEntries', () {
      cache.set('A', 1); // length 1
      cache.set('B', 2); // length 1
      cache.set('C', 3); // length 1

      expect(cache.length, 3);
      expect(cache.get('A'), 1); // 'A' is now most recently used

      // Insert 4th item, exceeding maxEntries (3)
      cache.set('D', 4);

      expect(cache.length, 3);
      // 'B' should be evicted because 'A' was recently accessed
      expect(cache.get('B'), isNull);
      expect(cache.get('C'), 3);
      expect(cache.get('D'), 4);
      expect(cache.get('A'), 1);
    });

    test('Character Budget Validation - evicts when exceeding maxTotalChars', () {
      cache.set('Short', 1); // 5 chars, total = 5
      cache.set('MediumText', 2); // 10 chars, total = 15

      expect(cache.length, 2);
      expect(cache.currentTotalChars, 15);

      // Insert an item that doesn't exceed maxEntries (3) but exceeds maxTotalChars (20)
      cache.set('AnotherLongText', 3); // 15 chars. Total would be 30.

      // Eviction loop should remove 'Short' (5) -> Total = 25 (still > 20)
      // Eviction loop should remove 'MediumText' (10) -> Total = 15 (now <= 20)
      expect(cache.length, 1);
      expect(cache.currentTotalChars, 15);

      expect(cache.get('Short'), isNull);
      expect(cache.get('MediumText'), isNull);
      expect(cache.get('AnotherLongText'), 3);
    });

    test('LRU Ordering - get() promotes item to most recently used', () {
      cache.set('K1', 1);
      cache.set('K2', 2);
      cache.set('K3', 3);

      // Access K1 to make it most recently used
      cache.get('K1');

      // Add K4. The oldest is now K2.
      cache.set('K4', 4);

      expect(cache.get('K2'), isNull, reason: 'K2 should be evicted');
      expect(cache.get('K1'), 1, reason: 'K1 was accessed and should survive');
      expect(cache.get('K3'), 3);
      expect(cache.get('K4'), 4);
    });

    test('Update Existing Key - accurately updates character budget', () {
      cache.set('Key', 1); // 3 chars
      expect(cache.currentTotalChars, 3);
      expect(cache.length, 1);

      // Update the same key
      cache.set('Key', 2);

      // Char count should NOT double to 6. It should remain 3.
      expect(cache.currentTotalChars, 3);
      expect(cache.length, 1);
      expect(cache.get('Key'), 2);
    });

    test('clear() resets map and character budget', () {
      cache.set('Hello', 1);
      cache.set('World', 2);

      expect(cache.length, 2);
      expect(cache.currentTotalChars, 10);

      cache.clear();

      expect(cache.length, 0);
      expect(cache.currentTotalChars, 0);
      expect(cache.get('Hello'), isNull);
    });
  });
}
