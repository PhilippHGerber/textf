// T-PERF-01 (the textf 2.0 performance regression guard): headless parse + span-build scaling
// benchmark.
//
// Times the four paths that turn a formatted string into spans, at several input sizes N:
//
// * `parse`   - `TextfParser.parse` on a cold token cache (tokenize + pair + resolve styles +
//               build spans). This is the path the theming change touched most directly.
// * `editing` - `TextfEditingController.buildTextSpan` on a cold cache (the live-editing path).
// * `widget`  - `tester.pumpWidget` of a `Textf` whose text changed (renderer + parse + layout).
// * `widget_ambient` - the same without `Textf.style`, so only the ambient style applies.
//
// Every line of output that starts with `TEXTF_BENCH` is machine-readable. The test fails only if
// the per-character cost grows super-linearly with N. It does not compare against a baseline: see
// README.md for the baseline-vs-current method.
//
// Run: flutter test test/parse_scaling_benchmark_test.dart   (from example/benchmark)
//
// ignore_for_file: no-magic-number, avoid-top-level-members-in-tests, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/textf.dart';

/// One representative chunk: a heading, every inline construct, nested formatting inside a
/// link, code inside a link, escapes, and a thematic break.
const String _chunk =
    '## Release notes\n'
    'Plain words with **bold**, *italic*, ***both***, `code`, ==highlight==, ~~strike~~ '
    'and ++underline++. E = mc^2^ and H~2~O. See [the **docs**](https://flutter.dev) or '
    '[`api`](https://api.flutter.dev). \\*not italic\\* and **nested _italic_ inside**.\n'
    '---\n';

/// Input sizes, as a number of chunks (268 characters each).
const List<int> _chunkCounts = [1, 2, 4, 8, 16, 32];

/// Samples per (scenario, N). The median of these is reported.
const int _samples = 21;

/// Each sample times enough operations to process about this many characters, so that small
/// inputs are not dominated by timer resolution.
const int _charsPerSample = 32000;

/// Index into [_chunkCounts] of the reference N (4 chunks) for the linearity check. Smaller N
/// are dominated by fixed per-call overhead.
const int _referenceIndex = 2;

/// The per-character cost at the largest N may be at most this multiple of the cost at the
/// reference N. Linear parsing gives about 1; quadratic parsing would give about 8.
const double _maxPerCharGrowth = 3;

const TextStyle _style = TextStyle(fontSize: 14, color: Color(0xFF000000));

/// One timed operation; `iteration` picks which of the two alternating texts to use.
typedef _TimedOp = Future<void> Function(int iteration);

/// Returns the text for an iteration, alternating between two variants.
typedef _TextPicker = String Function(int iteration);

void main() {
  testWidgets('T-PERF-01: parse and span build scale linearly with input size', (tester) async {
    // The probe stays mounted across every pump, so its context stays valid for the
    // `parse` and `editing` scenarios after the `widget` scenario has replaced the Textf.
    const probe = Key('probe');
    Widget host(Widget child) => MaterialApp(
      home: Material(
        child: Stack(
          children: [
            const SizedBox.shrink(key: probe),
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 800, child: child),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(host(const SizedBox.shrink()));
    final context = tester.element(find.byKey(probe));

    final parser = TextfParser();
    final controller = TextfEditingController(maxLiveFormattingLength: 1 << 20);
    addTearDown(controller.dispose);

    // Two texts of equal size and complexity per N; alternating between them defeats the
    // renderer's and the controller's "same text" caches.
    _TextPicker variants(int chunks) {
      final text = List.filled(chunks, _chunk).join();
      final other = '$text ';
      return (i) => i.isEven ? text : other;
    }

    final scenarios = <String, _TimedOp Function(_TextPicker)>{
      'parse': (texts) => (i) async {
        TextfParser.clearCache();
        parser.parse(texts(i), context, _style);
      },
      'editing': (texts) => (i) async {
        Textf.clearCache();
        controller
          ..text = texts(i)
          ..buildTextSpan(context: context, withComposing: false, style: _style);
      },
      'widget': (texts) => (i) async {
        Textf.clearCache();
        await tester.pumpWidget(host(Textf(texts(i), style: _style)));
      },
      // Same, without `Textf.style`: the spans carry only the ambient style. Before 2.0 an
      // explicit `Textf.style` replaced the ambient style instead of merging with it, so this is
      // the like-for-like layout comparison against 1.x / 2.0.0-dev.4.
      'widget_ambient': (texts) => (i) async {
        Textf.clearCache();
        await tester.pumpWidget(host(Textf(texts(i))));
      },
    };

    // Global JIT warm-up of every path before anything is measured.
    for (final build in scenarios.values) {
      final op = build(variants(_chunkCounts[_referenceIndex]));
      for (int i = 0; i < 200; i++) {
        await op(i);
      }
    }

    final failures = <String>[];
    for (final MapEntry(key: name, value: build) in scenarios.entries) {
      final perChar = <double>[];
      for (final chunks in _chunkCounts) {
        final texts = variants(chunks);
        final n = texts(0).length;
        final op = build(texts);
        final reps = (_charsPerSample ~/ n).clamp(1, 1 << 20);

        for (int i = 0; i < reps * 2; i++) {
          await op(i);
        }

        final micros = <double>[];
        for (int s = 0; s < _samples; s++) {
          final watch = Stopwatch()..start();
          for (int i = 0; i < reps; i++) {
            await op(i);
          }
          watch.stop();
          micros.add(watch.elapsedMicroseconds / reps);
        }
        micros.sort();
        final median = micros[micros.length ~/ 2];
        final p25 = micros[micros.length ~/ 4];
        final p75 = micros[(micros.length * 3) ~/ 4];
        perChar.add(median / n);

        debugPrint(
          'TEXTF_BENCH scenario=$name n=$n reps=$reps '
          'median_us=${median.toStringAsFixed(1)} '
          'p25_us=${p25.toStringAsFixed(1)} p75_us=${p75.toStringAsFixed(1)} '
          'ns_per_char=${(median / n * 1000).toStringAsFixed(1)}',
        );
      }

      final growth = perChar.last / perChar[_referenceIndex];
      debugPrint('TEXTF_BENCH_GROWTH scenario=$name growth=${growth.toStringAsFixed(2)}');
      if (growth > _maxPerCharGrowth) {
        failures.add('$name: per-character cost grew ${growth.toStringAsFixed(2)}x');
      }
    }

    expect(failures, isEmpty, reason: 'Parsing must stay O(N).');
  });
}
