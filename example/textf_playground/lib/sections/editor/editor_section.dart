// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/section_header.dart';

const String _initText = '''
🚀 **Welcome to Textf!**

Edit this text to see live formatting in action:
• **Bold**, *Italic* text and ***both***
• ~~Strikethrough~~ and ++Underline++
• ==Highlighting== and `inline code` blocks
• Superscript x^2^ + y^2^ and Task^✅^
• Subscript H~2~O and hot~🔥~

Check out the [Documentation](https://pub.dev/packages/textf)
for more details.
''';

class EditorSection extends StatefulWidget {
  const EditorSection({
    required this.currentThemeMode,
    required this.toggleThemeMode,
    super.key,
  });

  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  @override
  State<EditorSection> createState() => _EditorSectionState();
}

class _EditorSectionState extends State<EditorSection> {
  late final TextfEditingController _controller;
  late final FocusNode _focusNode;
  MarkerVisibility _visibility = MarkerVisibility.always;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextfEditingController(text: _initText);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  void _setVisibility(MarkerVisibility visibility) {
    setState(() {
      _visibility = visibility;
      _controller.markerVisibility = visibility;
    });
  }

  void _insertText(String insertText) {
    final text = _controller.text;
    final selection = _controller.selection;

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
    _controller
      ..text = newText
      ..selection = TextSelection.collapsed(offset: start + insertText.length);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: TextfOptions(
          onLinkTap: (url, _) => _launchUrl(url),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(
                title: 'Live Formatting Editor',
                subtitle: 'TextfEditingController renders markers as you type.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 12,
                minLines: 12,
                decoration: InputDecoration(
                  hintText: 'Type formatted text here...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                ),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              _FormatChips(onInsert: _insertText),
              const SizedBox(height: 12),
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
                selected: {_visibility},
                onSelectionChanged: (s) => _setVisibility(s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 32),
              const SectionHeader(
                title: 'Placeholders',
                subtitle: 'Use {key} to embed inline widgets inside a Textf widget.',
              ),
              const SizedBox(height: 12),
              Textf(
                'Built with {flutter} and {dart}. Made with {love}.\n'
                'Flutter package '
                '[textf on pub.dev](https://pub.dev/packages/textf) '
                'and the '
                '[GitHub repo](https://github.com/PhilippHGerber/textf).',
                placeholders: {
                  'flutter': WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset('assets/img/flutter.png', height: 16),
                  ),
                  'dart': WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset('assets/img/dart.png', height: 16),
                  ),
                  'love': const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(Icons.favorite, color: Colors.red, size: 16),
                  ),
                },
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SectionHeader(
                title: 'Custom Styles via TextfOptions',
                subtitle: 'Wrap any TextField to customize formatting appearance.',
              ),
              const SizedBox(height: 12),
              TextfOptions(
                boldStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
                italicStyle: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.tertiary,
                ),
                codeStyle: TextStyle(
                  fontFamily: 'RobotoMono',
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  color: theme.colorScheme.primary,
                ),
                highlightStyle: const TextStyle(backgroundColor: Color(0x66FFD700)),
                child: TextField(
                  controller: TextfEditingController(
                    text: '**Primary bold** with *tertiary italic* and `styled code`',
                  ),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Custom styled',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 32),
              const SectionHeader(
                title: 'TextFormField Integration',
                subtitle: 'Works seamlessly with TextFormField for form validation.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: TextfEditingController(
                  text: 'A **required** field with *formatted* hints',
                ),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  helperText: 'Supports bold, italic, code, and more',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your bio';

                  return null;
                },
              ),
              const SizedBox(height: 32),
              const SectionHeader(
                title: 'Side-by-Side Comparison',
                subtitle: 'Same text rendered in TextField (editable) vs Textf (read-only).',
              ),
              const SizedBox(height: 12),
              const _SideBySideComparison(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatChips extends StatelessWidget {
  const _FormatChips({required this.onInsert});

  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
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
          _chip('~~strike~~', onInsert),
          _chip('++underline++', onInsert),
          _chip('==highlight==', onInsert),
          _chip('`code`', onInsert),
          _chip('^super^', onInsert),
          _chip('~sub~', onInsert),
          _chip('[link](https://flutter.dev)', onInsert),
        ],
      ),
    );
  }

  Widget _chip(String label, ValueChanged<String> onInsert) {
    return ActionChip(
      label: IgnorePointer(
        child: Textf(label, style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 11)),
      ),
      onPressed: () => onInsert('$label '),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SideBySideComparison extends StatefulWidget {
  const _SideBySideComparison();

  @override
  State<_SideBySideComparison> createState() => _SideBySideComparisonState();
}

class _SideBySideComparisonState extends State<_SideBySideComparison> {
  late final TextfEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextfEditingController(
      text: 'Hello **bold** and *italic* `code` world!',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Editable (TextField)',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Read-only (Textf)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Textf(_controller.text, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
