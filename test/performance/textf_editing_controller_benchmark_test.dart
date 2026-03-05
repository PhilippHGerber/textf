// ignore_for_file: cascade_invocations, no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

// Microbenchmark to measure the performance of the TextfEditingController's caching mechanism.

void main() {
  testWidgets('Controller Cache Benchmark', (tester) async {
    // 1. Setup a massive string to stress the parser
    final text = List.generate(
      100,
      (i) => '**b** *i* `c` ~~s~~ ==h== ++u++ ^s^ ~s~ [h](i)',
    ).join('\n');

    final controller = TextfEditingController(text: text);

    // 2. Pump a real widget tree to obtain a valid BuildContext
    // We need MaterialApp so Theme and MediaQuery (TextScaler) are available.
    BuildContext? testContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              testContext = context; // Capture the context
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // 3. WARMUP & CACHE MISS
    // This forces the initial parse, mimicking the first time the text is rendered.
    final stopwatch = Stopwatch()..start();
    controller.buildTextSpan(context: testContext!, withComposing: false);
    stopwatch.stop();
    final missTime = stopwatch.elapsedMicroseconds;

    // 4. CACHE HIT
    // Simulate 100 cursor blinks (which trigger buildTextSpan without changing text)
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 100; i++) {
      controller.buildTextSpan(context: testContext!, withComposing: false);
    }
    stopwatch.stop();

    // Average out the hit time
    final hitTimeAvg = stopwatch.elapsedMicroseconds / 100;

    debugPrint('--- TextfEditingController Cache Benchmark ---');
    debugPrint('String length: ${text.length} characters');
    debugPrint('Cache Miss (1 parse) : $missTimeμs');
    debugPrint('Cache Hit (Average)  : $hitTimeAvgμs');
    debugPrint('Speedup Factor       : ${(missTime / hitTimeAvg).toStringAsFixed(1)}x faster');

    // The hit should be drastically faster (easily 10x to 100x faster)
    expect(hitTimeAvg, lessThan(missTime / 10));
  });
}
