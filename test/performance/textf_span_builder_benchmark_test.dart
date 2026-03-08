// ignore_for_file: cascade_invocations, no-magic-number, for unit test readability.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/textf_span_builder.dart';

void main() {
  testWidgets('TextfSpanBuilder Cache Performance Benchmark', (WidgetTester tester) async {
    // 1. Create a large, formatting-heavy string
    const String baseText = '*a* **b** ==c== ~~d~~ ++e++ ^f^ ~g~ [link](https://flutter.dev) ';
    final String heavyText = List.filled(15, baseText).join(); // Very long text

    // 2. Setup standard context requirements
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text(''))));
    final BuildContext context = tester.element(find.byType(Text));
    const TextStyle baseStyle = TextStyle(fontSize: 14);

    final builder = TextfSpanBuilder();

    // 3. Warmup (Compile JIT, initialize statics)
    builder.build(heavyText, context, baseStyle, cursorPosition: 0);

    // 4. Run the Benchmark
    // We simulate 1000 cursor movements/blinks without changing the text.
    const int iterations = 1000;
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      // Vary the cursor position to simulate selection/blinking
      builder.build(
        heavyText,
        context,
        baseStyle,
        cursorPosition: i % heavyText.length,
      );
    }

    stopwatch.stop();

    debugPrint('--- TextfSpanBuilder Cache Performance Benchmark ---');
    debugPrint('Benchmark for $iterations cursor updates:');
    debugPrint('Total time: ${stopwatch.elapsedMilliseconds} ms');
    debugPrint(
      'Average time per build: ${(stopwatch.elapsedMicroseconds / iterations).toStringAsFixed(2)} µs',
    );
  });
}
