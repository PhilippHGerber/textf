// ignore_for_file: no-magic-number

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/textf_cache.dart';

void main() {
  test('TextfCache Eviction Stress Benchmark', () {
    final cache = TextfCache<String, int>(
      maxEntries: 100,
      maxTotalChars: 10000,
      getCharCount: (key) => key.length,
    );

    // 1. Eviction stress: insert 10000 unique keys (constant eviction after first 100)
    const int insertions = 10000;
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < insertions; i++) {
      cache.set('key_$i', i);
    }
    stopwatch.stop();

    final evictionMs = stopwatch.elapsedMilliseconds;
    final evictionOpsPerMs = evictionMs > 0 ? insertions / evictionMs : insertions;

    // Cache must respect maxEntries
    expect(cache.length, lessThanOrEqualTo(100));

    // 2. MRU hit stress: repeatedly get the same key 100000 times
    const int lookups = 100000;
    const lastKey = 'key_${insertions - 1}';
    // Ensure the key is in the cache
    expect(cache.get(lastKey), isNotNull);

    stopwatch
      ..reset()
      ..start();
    for (int i = 0; i < lookups; i++) {
      cache.get(lastKey);
    }
    stopwatch.stop();

    final hitMs = stopwatch.elapsedMilliseconds;
    final hitOpsPerMs = hitMs > 0 ? lookups / hitMs : lookups;

    debugPrint('--- TextfCache Eviction Stress Benchmark ---');
    debugPrint('Eviction: $insertions inserts in ${evictionMs}ms ($evictionOpsPerMs ops/ms)');
    debugPrint('MRU Hit:  $lookups lookups in ${hitMs}ms ($hitOpsPerMs ops/ms)');
  });
}
