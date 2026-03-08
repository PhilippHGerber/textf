// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';

void main() {
  testWidgets('TextfParser Cache Hit vs Miss Benchmark', (tester) async {
    // 1. Generate a formatting-heavy string
    final text = List.generate(
      100,
      (i) => '**b** *i* `c` ~~s~~ ==h== ++u++ ^s^ ~s~ [link](https://flutter.dev) ',
    ).join();

    // 2. Pump a widget tree to get a valid BuildContext
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text(''))));
    final BuildContext context = tester.element(find.byType(Text));
    const TextStyle baseStyle = TextStyle(fontSize: 14);
    final parser = TextfParser();

    // 3. CACHE MISS — clear cache, then parse once
    TextfParser.clearCache();
    final missStopwatch = Stopwatch()..start();
    parser.parse(text, context, baseStyle);
    missStopwatch.stop();
    final missTime = missStopwatch.elapsedMicroseconds;

    // 4. CACHE HIT — parse 1000 times with warm token cache
    const int iterations = 1000;
    final hitStopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      parser.parse(text, context, baseStyle);
    }
    hitStopwatch.stop();
    final hitTimeAvg = hitStopwatch.elapsedMicroseconds / iterations;

    debugPrint('--- TextfParser Cache Hit vs Miss Benchmark ---');
    debugPrint('String length: ${text.length} characters');
    debugPrint('Cache Miss (1 parse) : $missTimeμs');
    debugPrint('Cache Hit (Average)  : ${hitTimeAvg.toStringAsFixed(2)}μs');
    debugPrint('Speedup Factor       : ${(missTime / hitTimeAvg).toStringAsFixed(1)}x faster');

    // Cache hit should be at least 2x faster than miss
    expect(hitTimeAvg, lessThan(missTime / 2));
  });
}
