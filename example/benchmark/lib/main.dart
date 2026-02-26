import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:textf/textf.dart';

void main() {
  runApp(const BenchmarkApp());
}

// --- Configuration ---
class BenchmarkConfig {
  static const int itemHeight = 60;
  static const int totalItems = 1000;
  static const int framesToCapture = 300; // ~5 seconds at 60fps
  static const int corpusSize = 200;
  static const int minSegments = 10;
  static const int maxSegments = 20;

  static const int largeStringLength = 1000;
  static const Duration animationDuration = Duration(seconds: 5);
}

// --- Models ---
class BenchmarkResult {
  final String scenarioName;
  final String targetName; // Textf, Raw, Rich
  final double medianBuildTimeMs;
  final double maxBuildTimeMs;
  final double microsPerWidget; // For list scenarios

  BenchmarkResult({
    required this.scenarioName,
    required this.targetName,
    required this.medianBuildTimeMs,
    required this.maxBuildTimeMs,
    required this.microsPerWidget,
  });
}

enum BenchmarkTarget {
  textf,
  raw,
  rich,
}

// --- Scenarios ---
abstract class BenchmarkScenario {
  String get name;
  Widget build(BuildContext context, BenchmarkTarget target, int offset);
}

class ScrollingScenario extends BenchmarkScenario {
  @override
  String get name => 'Scrolling List';

  final List<String> corpus = _generateCorpus();
  final Map<String, InlineSpan> icons = {
    'star': const WidgetSpan(child: Icon(Icons.star, size: 16, color: Colors.amber)),
    'favorite': const WidgetSpan(child: Icon(Icons.favorite, size: 16, color: Colors.red)),
    'info': const WidgetSpan(child: Icon(Icons.info, size: 16, color: Colors.blue)),
  };

  static List<String> _generateCorpus() {
    final random = Random(42);
    final parts = [
      '**Bold**',
      '*Italic*',
      '~~Strike~~',
      '`code`',
      '++Under++',
      '==High==',
      '^Sup^',
      '~Sub~',
      '[Link](https://flutter.dev)',
      'Normal text content that is a bit longer to test performance better.',
      'Some {star} icons {favorite} in between {info}.',
    ];
    return List.generate(BenchmarkConfig.corpusSize, (index) {
      final buffer = StringBuffer();
      int segments = random.nextInt(BenchmarkConfig.maxSegments - BenchmarkConfig.minSegments) +
          BenchmarkConfig.minSegments;
      for (int i = 0; i < segments; i++) {
        buffer.write(parts[random.nextInt(parts.length)]);
        buffer.write(' ');
      }
      return buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context, BenchmarkTarget target, int offset) {
    return ListView.builder(
      itemExtent: BenchmarkConfig.itemHeight.toDouble(),
      itemCount: BenchmarkConfig.totalItems,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final contentIndex = (index + offset) % corpus.length;
        final text = corpus[contentIndex];

        switch (target) {
          case BenchmarkTarget.textf:
            return Center(
              key: ValueKey('textf_$index'),
              child: Textf(
                text,
                placeholders: icons,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          case BenchmarkTarget.raw:
            return Center(
              key: ValueKey('raw_$index'),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          case BenchmarkTarget.rich:
            // Improved rich text baseline: Just the text for now,
            // as manually recreating the exact Textf tree is complex.
            // At least we remove the forced 3-icon overhead.
            return Center(
              key: ValueKey('rich_$index'),
              child: Text.rich(
                TextSpan(text: text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
        }
      },
    );
  }
}

class AnimationScenario extends BenchmarkScenario {
  @override
  String get name => 'Animated Large Text';

  final String largeText = _generateLargeText();

  /// Pre-parsed baseline for RICH target to show layout cost without parsing cost.
  static List<InlineSpan>? _richBaselineSpans;

  static String _generateLargeText() {
    final buffer = StringBuffer();
    final parts = ['Normal ', '**Bold** ', '*Italic* ', '~~Strike~~ ', '[Link](url) '];
    final random = Random(42);
    while (buffer.length < BenchmarkConfig.largeStringLength) {
      buffer.write(parts[random.nextInt(parts.length)]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, BenchmarkTarget target, int offset) {
    // offset is used as a proxy for animation progress here
    final progress = (offset % 100) / 100.0;
    final fontSize = 10.0 + (progress * 20.0);
    final color = Color.lerp(Colors.blue, Colors.red, progress)!;

    final style = TextStyle(fontSize: fontSize, color: color);

    switch (target) {
      case BenchmarkTarget.textf:
        return SingleChildScrollView(
          child: Textf(largeText, style: style),
        );
      case BenchmarkTarget.raw:
        return SingleChildScrollView(
          child: Text(largeText, style: style),
        );
      case BenchmarkTarget.rich:
        return SingleChildScrollView(
          child: Text.rich(
            TextSpan(
              style: style,
              children: _richBaselineSpans,
            ),
          ),
        );
    }
  }
}

class OptionsRebuildScenario extends BenchmarkScenario {
  @override
  String get name => 'Options Rebuild (Cache Stress)';

  // Generate a heavy string to make the cost of re-parsing obvious
  final String heavyText =
      List.generate(100, (i) => 'Item $i: **Bold**, *Italic*, [Link](https://google.com)')
          .join('\n');

  @override
  Widget build(BuildContext context, BenchmarkTarget target, int offset) {
    // We simulate an animation value to ensure the parent rebuilds
    // but the actual TextfOptions styles remain CONSTANT.

    // We construct styles here to simulate "new instances" every frame
    final dynamicBoldStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.red);

    switch (target) {
      case BenchmarkTarget.textf:
        return Center(
          child: TextfOptions(
            // NEW INSTANCE every frame, but SAME content
            boldStyle: dynamicBoldStyle,
            child: SingleChildScrollView(
              child: Textf(heavyText),
            ),
          ),
        );
      case BenchmarkTarget.raw:
        return const Center(child: Text('Raw not applicable for Options test'));
      case BenchmarkTarget.rich:
        return const Center(child: Text('Rich not applicable for Options test'));
    }
  }
}

// --- App ---
class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Textf Benchmark',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const BenchmarkHome(),
    );
  }
}

class BenchmarkHome extends StatefulWidget {
  const BenchmarkHome({super.key});

  @override
  State<BenchmarkHome> createState() => _BenchmarkHomeState();
}

class _BenchmarkHomeState extends State<BenchmarkHome> with SingleTickerProviderStateMixin {
  final List<BenchmarkScenario> _scenarios = [
    ScrollingScenario(),
    AnimationScenario(),
    OptionsRebuildScenario(),
  ];

  final List<BenchmarkResult> _results = [];
  bool _isBatchRunning = false;
  BenchmarkScenario? _currentScenario;
  BenchmarkTarget? _currentTarget;
  int _offset = 0;
  final List<double> _frameTimes = [];
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _offset++;
    });

    if (_frameTimes.length >= BenchmarkConfig.framesToCapture) {
      _finishCurrentRun();
    }
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    if (!_ticker.isActive) return;
    for (final timing in timings) {
      _frameTimes.add(timing.buildDuration.inMicroseconds.toDouble());
    }
  }

  Future<void> _runAll() async {
    setState(() {
      _results.clear();
      _isBatchRunning = true;
    });

    for (final scenario in _scenarios) {
      for (final target in BenchmarkTarget.values) {
        await _runScenario(scenario, target);
      }
    }

    setState(() {
      _isBatchRunning = false;
      _currentScenario = null;
      _currentTarget = null;
    });
  }

  Future<void> _runScenario(BenchmarkScenario scenario, BenchmarkTarget target) async {
    setState(() {
      _currentScenario = scenario;
      _currentTarget = target;
      _frameTimes.clear();
      _offset = 0;
    });

    _ticker.start();

    // Wait for ticker to finish (it stops in _finishCurrentRun)
    while (_ticker.isActive) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  void _finishCurrentRun() {
    _ticker.stop();

    _frameTimes.sort();
    final medianMs = _frameTimes[_frameTimes.length ~/ 2] / 1000.0;
    final maxMs = _frameTimes.last / 1000.0;

    double microsPerWidget = 0;
    if (_currentScenario is ScrollingScenario) {
      final screenHeight = MediaQuery.of(context).size.height;
      final itemsOnScreen = (screenHeight / BenchmarkConfig.itemHeight).ceil();
      microsPerWidget = (medianMs * 1000) / itemsOnScreen;
    }

    final result = BenchmarkResult(
      scenarioName: _currentScenario!.name,
      targetName: _currentTarget.toString().split('.').last.toUpperCase(),
      medianBuildTimeMs: medianMs,
      maxBuildTimeMs: maxMs,
      microsPerWidget: microsPerWidget,
    );

    setState(() {
      _results.add(result);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Textf Benchmark'),
        actions: [
          if (!_isBatchRunning)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _runAll,
              tooltip: 'Run All Benchmarks',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_currentScenario != null)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                child: Stack(
                  children: [
                    _currentScenario!.build(context, _currentTarget!, _offset),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          '${_currentScenario!.name} - ${_currentTarget.toString().split('.').last.toUpperCase()}\nFrames: ${_frameTimes.length} / ${BenchmarkConfig.framesToCapture}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: _results.isEmpty && !_isBatchRunning
                ? const Center(child: Text('Press Play to start benchmarks'))
                : _Dashboard(results: _results, isRunning: _isBatchRunning),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final List<BenchmarkResult> results;
  final bool isRunning;

  const _Dashboard({required this.results, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<BenchmarkResult>> grouped = {};
    for (final r in results) {
      grouped.putIfAbsent(r.scenarioName, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isRunning)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        ...grouped.entries
            .map((entry) => _ScenarioResultGroup(name: entry.key, results: entry.value)),
      ],
    );
  }
}

class _ScenarioResultGroup extends StatelessWidget {
  final String name;
  final List<BenchmarkResult> results;

  const _ScenarioResultGroup({required this.name, required this.results});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Target')),
                  DataColumn(label: Text('Med (ms)')),
                  DataColumn(label: Text('Max (ms)')),
                  DataColumn(label: Text('µs/W')),
                ],
                rows: results.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          r.targetName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(r.medianBuildTimeMs.toStringAsFixed(3))),
                      DataCell(Text(r.maxBuildTimeMs.toStringAsFixed(3))),
                      DataCell(
                        Text(r.microsPerWidget > 0 ? r.microsPerWidget.toStringAsFixed(1) : '-'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
