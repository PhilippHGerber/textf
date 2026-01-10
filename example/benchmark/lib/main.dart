import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:textf/textf.dart';

void main() {
  runApp(const BenchmarkApp());
}

/// A data class to hold the results of a run
class BenchmarkResult {
  final String label;
  final int frames;
  final double medianBuildTimeMs;
  final double maxBuildTimeMs;
  final double microsPerWidget;

  BenchmarkResult({
    required this.label,
    required this.frames,
    required this.medianBuildTimeMs,
    required this.maxBuildTimeMs,
    required this.microsPerWidget,
  });
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Textf Profiler',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const BenchmarkScreen(),
    );
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> with SingleTickerProviderStateMixin {
  // Config
  static const int _itemHeight = 60;
  static const int _totalItems = 1000;
  static const int _framesToCapture = 300; // Run for ~5 seconds at 60fps

  // State
  late final List<String> _corpus;
  late final Ticker _ticker;
  int _offset = 0;
  bool _isRunning = false;
  bool _isTextfMode = true;

  // Metrics
  final List<double> _recordedBuildTimes = [];
  BenchmarkResult? _textfResult;
  BenchmarkResult? _rawResult;

  @override
  void initState() {
    super.initState();
    _corpus = _generateCorpus(200);
    _ticker = createTicker((elapsed) {
      if (_isRunning) {
        setState(() {
          _offset++; // Force widget update every frame
        });

        // Auto-stop after N frames
        if (_recordedBuildTimes.length >= _framesToCapture) {
          _finishRun();
        }
      }
    });

    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    if (!_isRunning) return;
    for (final timing in timings) {
      // Record only the Build duration (Dart CPU time)
      _recordedBuildTimes.add(timing.buildDuration.inMicroseconds.toDouble());
    }
  }

  void _startRun() {
    setState(() {
      _recordedBuildTimes.clear();
      _isRunning = true;
      _ticker.start();
    });
  }

  void _finishRun() {
    _ticker.stop();
    final result = _calculateResult(_isTextfMode ? 'Textf' : 'Raw Text');

    setState(() {
      _isRunning = false;
      if (_isTextfMode) {
        _textfResult = result;
      } else {
        _rawResult = result;
      }
    });
  }

  BenchmarkResult _calculateResult(String label) {
    _recordedBuildTimes.sort(); // Sort to find median
    final medianMs = _recordedBuildTimes[_recordedBuildTimes.length ~/ 2] / 1000.0;
    final maxMs = _recordedBuildTimes.last / 1000.0;

    // Calculate items visible on screen to get per-widget cost
    final screenHeight = MediaQuery.of(context).size.height;
    // Approximation: screen - bottomSheet(250) - appBar(56) - status(24)
    // We want the number of widgets actually laid out.
    // In ListView with itemExtent, Flutter lays out: ceil(height / extent) + 1
    final listHeight = screenHeight; // We use the full height for calculation safety
    final itemsOnScreen = (listHeight / _itemHeight).ceil();

    final costPerWidget = (medianMs * 1000) / itemsOnScreen; // in Microseconds

    return BenchmarkResult(
      label: label,
      frames: _recordedBuildTimes.length,
      medianBuildTimeMs: medianMs,
      maxBuildTimeMs: maxMs,
      microsPerWidget: costPerWidget,
    );
  }

  List<String> _generateCorpus(int count) {
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
      'Normal Text',
      r'Esc \*Char\*',
    ];
    return List.generate(count, (index) {
      final buffer = StringBuffer();
      int segments = random.nextInt(5) + 3;
      for (int i = 0; i < segments; i++) {
        buffer.write(parts[random.nextInt(parts.length)]);
        buffer.write(' ');
      }
      return buffer.toString();
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
        title: const Text('Textf Profiler'),
        elevation: 2,
        actions: [
          if (!_isRunning)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Profile Mode Recommended',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- The Test Area ---
          Expanded(
            child: Stack(
              children: [
                Opacity(
                  // Dim the list when showing results so user focuses on data
                  opacity: _isRunning ? 1.0 : 0.3,
                  child: TextfOptions(
                    boldStyle: const TextStyle(color: Colors.blue),
                    child: ListView.builder(
                      itemExtent: _itemHeight.toDouble(),
                      itemCount: _totalItems,
                      physics:
                          const NeverScrollableScrollPhysics(), // Prevent manual scrolling affecting results
                      itemBuilder: (context, index) {
                        final contentIndex = (index + _offset) % _corpus.length;
                        final text = _corpus[contentIndex];

                        return Center(
                          // Key ensures we update the existing widget
                          key: ValueKey('row_$index'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _isTextfMode
                                ? Textf(text, maxLines: 1, overflow: TextOverflow.ellipsis)
                                : Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_isRunning)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Profiling ${_isTextfMode ? "Textf" : "Raw Text"}...\n${_recordedBuildTimes.length} / $_framesToCapture frames',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- Control & Result Panel ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Results Grid
                  if (_rawResult != null || _textfResult != null)
                    Row(
                      children: [
                        if (_rawResult != null)
                          Expanded(child: _ResultCard(result: _rawResult!, isBaseline: true)),
                        if (_rawResult != null && _textfResult != null) const SizedBox(width: 12),
                        if (_textfResult != null)
                          Expanded(child: _ResultCard(result: _textfResult!, isBaseline: false)),
                      ],
                    ),

                  if (_rawResult != null && _textfResult != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: _buildComparisonSummary(),
                    ),

                  const SizedBox(height: 24),

                  // Controls
                  if (!_isRunning)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(
                              _isTextfMode ? Icons.check_box_outline_blank : Icons.check_box,
                            ),
                            label: const Text('Baseline (Raw)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: !_isTextfMode ? Colors.blue : Colors.grey,
                              side: BorderSide(
                                color: !_isTextfMode ? Colors.blue : Colors.grey[300]!,
                              ),
                            ),
                            onPressed: () => setState(() => _isTextfMode = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(
                              _isTextfMode ? Icons.check_box : Icons.check_box_outline_blank,
                            ),
                            label: const Text('Subject (Textf)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isTextfMode ? Colors.blue : Colors.grey,
                              side: BorderSide(
                                color: _isTextfMode ? Colors.blue : Colors.grey[300]!,
                              ),
                            ),
                            onPressed: () => setState(() => _isTextfMode = true),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isRunning ? null : _startRun,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isRunning ? 'Running...' : 'START BENCHMARK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSummary() {
    final overhead = _textfResult!.microsPerWidget - _rawResult!.microsPerWidget;
    // Convert micros to millis for cleaner reading if large, but usually it's < 0.1ms
    final overheadMs = overhead / 1000.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.speed, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            'Textf Cost: +${overheadMs.toStringAsFixed(4)} ms / widget',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final BenchmarkResult result;
  final bool isBaseline;

  const _ResultCard({required this.result, required this.isBaseline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBaseline ? Colors.grey[100] : Colors.white,
        border: Border.all(
          color: isBaseline ? Colors.grey[300]! : Colors.blue[200]!,
          width: isBaseline ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isBaseline ? Colors.grey[600] : Colors.blue[800],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          _MetricRow('Build (Med)', '${result.medianBuildTimeMs.toStringAsFixed(3)} ms'),
          _MetricRow('Per Widget', '${result.microsPerWidget.toStringAsFixed(1)} µs'),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
