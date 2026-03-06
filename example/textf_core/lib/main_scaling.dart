// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:textf/textf.dart';

void main() {
  runApp(const MaterialApp(home: ScalingReproScreen()));
}

class ScalingReproScreen extends StatefulWidget {
  @Preview(
    name: 'Scaling Repro Screen',
  )
  const ScalingReproScreen({super.key});

  @override
  State<ScalingReproScreen> createState() => _ScalingReproScreenState();
}

class _ScalingReproScreenState extends State<ScalingReproScreen> {
  double _textScaleFactor = 1;
  double _fontSize = 14;
  MarkerVisibility _markerVisibility = MarkerVisibility.always;
  late final TextfEditingController _editorController;

  @override
  void initState() {
    super.initState();
    _editorController = TextfEditingController(
      text: ' **hello** ==world==\n E = mc^2^\n H~2~O\n a^log~a~b^\n',
    );
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  void _insertText(String insertText) {
    final text = _editorController.text;
    final selection = _editorController.selection;

    final int start;
    final int end;
    if (selection.isValid && !selection.isCollapsed) {
      start = selection.start;
      end = selection.end;
    } else if (selection.isValid) {
      start = selection.baseOffset;
      end = start;
    } else {
      start = text.length;
      end = start;
    }

    // ignore: avoid-substring
    final newText = text.substring(0, start) + insertText + text.substring(end);
    _editorController
      ..text = newText
      ..selection = TextSelection.collapsed(offset: start + insertText.length);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Textf Scaling Superscript/Subscript'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Preview'),
              Tab(text: 'Editor'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _PreviewTab(
                    fontSize: _fontSize,
                    textScaleFactor: _textScaleFactor,
                  ),
                  _EditorTab(
                    fontSize: _fontSize,
                    textScaleFactor: _textScaleFactor,
                    controller: _editorController,
                    onInsert: _insertText,
                    markerVisibility: _markerVisibility,
                    onMarkerVisibilityChanged: (v) => setState(() {
                      _markerVisibility = v;
                      _editorController.markerVisibility = v;
                    }),
                  ),
                ],
              ),
            ),
            _ScalingControls(
              fontSize: _fontSize,
              textScaleFactor: _textScaleFactor,
              onFontSizeChanged: (v) => setState(() => _fontSize = v),
              onTextScaleChanged: (v) => setState(() => _textScaleFactor = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab views
// ---------------------------------------------------------------------------

class _PreviewTab extends StatelessWidget {

  const _PreviewTab({required this.fontSize, required this.textScaleFactor});
  final double fontSize;
  final double textScaleFactor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: TextfOptions(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            padding: const EdgeInsets.all(8),
            child: SelectionArea(
              child: Textf(
                ' **hello** ==world== \n'
                ' E = mc^2^ \n'
                ' H~2~O \n'
                ' a^log~a~b^ \n'
                ' Link [Flutter](https://flutter.dev) \n'
                ' This is a ~~cat~~ bird {bird} \n',
                style: TextStyle(fontSize: fontSize),
                // textScaler: TextScaler.linear(_textScaleFactor),
                placeholders: {
                  'bird': WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset(
                      'assets/img/bird.gif',
                      width: fontSize * 2,
                      height: fontSize * 2,
                    ),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorTab extends StatelessWidget {

  const _EditorTab({
    required this.fontSize,
    required this.textScaleFactor,
    required this.controller,
    required this.onInsert,
    required this.markerVisibility,
    required this.onMarkerVisibilityChanged,
  });
  final double fontSize;
  final double textScaleFactor;
  final TextfEditingController controller;
  final ValueChanged<String> onInsert;
  final MarkerVisibility markerVisibility;
  final ValueChanged<MarkerVisibility> onMarkerVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  hintText: 'Type **bold**, *italic*, ^super^, ~sub~...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<MarkerVisibility>(
              segments: const [
                ButtonSegment(
                  value: MarkerVisibility.always,
                  label: Text('Markers visible'),
                  icon: Icon(Icons.visibility_outlined),
                ),
                ButtonSegment(
                  value: MarkerVisibility.whenActive,
                  label: Text('Smart hide'),
                  icon: Icon(Icons.visibility_off_outlined),
                ),
              ],
              selected: {markerVisibility},
              onSelectionChanged: (s) => onMarkerVisibilityChanged(s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            _FormatChips(onInsert: onInsert, theme: theme),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared controls
// ---------------------------------------------------------------------------

class _ScalingControls extends StatelessWidget {

  const _ScalingControls({
    required this.fontSize,
    required this.textScaleFactor,
    required this.onFontSizeChanged,
    required this.onTextScaleChanged,
  });
  final double fontSize;
  final double textScaleFactor;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Font Size: ${fontSize.toStringAsFixed(0)}px'),
          Slider(
            min: 14,
            max: 48,
            divisions: 34,
            value: fontSize,
            onChanged: onFontSizeChanged,
          ),
          const SizedBox(height: 4),
          Text('Text Scale Factor: ${textScaleFactor.toStringAsFixed(1)}x'),
          Slider(
            min: 1,
            max: 2.5,
            value: textScaleFactor,
            onChanged: onTextScaleChanged,
          ),
        ],
      ),
    );
  }
}

class _FormatChips extends StatelessWidget {

  const _FormatChips({required this.onInsert, required this.theme});
  final ValueChanged<String> onInsert;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _chip('**bold**', onInsert),
          _chip('*italic*', onInsert),
          _chip('^super^', onInsert),
          _chip('~sub~', onInsert),
          _chip('~~strike~~', onInsert),
          _chip('==highlight==', onInsert),
          _chip('`code`', onInsert),
          _chip('[link](https://flutter.dev)', onInsert),
        ],
      ),
    );
  }

  static Widget _chip(String label, ValueChanged<String> onInsert) {
    return ActionChip(
      label: Textf(label, style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 11)),
      onPressed: () => onInsert('$label '),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
