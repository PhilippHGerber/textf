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
  const EditorSection({super.key});

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Live Formatting Editor',
                  subtitle: 'TextfEditingController renders markers as you type.',
                ),
                const SizedBox(height: 12),
                _FormatChips(onInsert: _insertText),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        expands: true,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Type formatted text here...',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceContainerLowest,
                          hoverColor: theme.brightness == Brightness.light
                              ? theme.colorScheme.surfaceDim.withValues(alpha: 0.4)
                              : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.85),
                        ),
                        style: theme.textTheme.bodyLarge,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(
                            _visibility == MarkerVisibility.always
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => _setVisibility(
                            _visibility == MarkerVisibility.always
                                ? MarkerVisibility.whenActive
                                : MarkerVisibility.always,
                          ),
                          tooltip: _visibility == MarkerVisibility.always
                              ? 'Markers visible'
                              : 'Smart hide markers',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
