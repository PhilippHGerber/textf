// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

const String initText = '''
🚀 **Welcome to Textf 1.2.0!**

Edit this text to see live formatting in action:
• **Bold**, *Italic* text and ***both***
• ~~Strikethrough~~ and ++Underline++
• ==Highlighting== and `inline code` blocks
• Superscript x^2^ + y^2^ and Task^✅^
• Subscript H~2~O and hot~🔥~

Check out the [Documentation](https://pub.dev/packages/textf)
for more details.
''';

const String init2Text = '*a* **b** ==c== ~~d~~ ++e++ ^f^ ~g~ [h](i)';

// repease init2Text 20x
final String init2TextLong = List.filled(20, init2Text).join('\n');

class WebDemoScreen extends StatefulWidget {
  const WebDemoScreen({
    required this.currentThemeMode,
    required this.toggleThemeMode,
    super.key,
  });
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  @override
  State<WebDemoScreen> createState() => _WebDemoScreenState();
}

class _WebDemoScreenState extends State<WebDemoScreen> {
  late final TextfEditingController _controller;
  late final FocusNode _focusNode;
  MarkerVisibility _visibility = MarkerVisibility.always;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextfEditingController(
      text: initText,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setVisibility(MarkerVisibility visibility) {
    _visibility = visibility;
    _controller.markerVisibility = visibility;
    setState(() {});
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
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
      ..selection = TextSelection.collapsed(
        offset: start + insertText.length,
      );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final themeIcon =
        brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Textf('**Textf** — Live Formatting Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ColorFiltered(
              colorFilter: ColorFilter.mode(
                theme.colorScheme.onSurface,
                BlendMode.srcIn,
              ),
              child: Image.asset('assets/img/pub-dev.png', height: 20),
            ),
            tooltip: 'pub.dev',
            onPressed: () => _launchUrl('https://pub.dev/packages/textf'),
          ),
          IconButton(
            icon: ColorFiltered(
              colorFilter: ColorFilter.mode(
                theme.colorScheme.onSurface,
                BlendMode.srcIn,
              ),
              child: Image.asset('assets/img/github.png', height: 20),
            ),
            tooltip: 'GitHub',
            onPressed: () => _launchUrl('https://github.com/PhilippHGerber/textf'),
          ),
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleThemeMode,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TextfOptions(
        onLinkTap: (url, _) => _launchUrl(url),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Textf(
                  "A drop-in replacement for Flutter's `Text` widget with "
                  '**markdown-like** inline formatting.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 14,
                      minLines: 14,
                      decoration: InputDecoration(
                        hintText: 'Type formatted text here...',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLowest,
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(
                          _visibility == MarkerVisibility.always
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        tooltip: _visibility == MarkerVisibility.always
                            ? 'Markers visible'
                            : 'Smart hide',
                        onPressed: () => _setVisibility(
                          _visibility == MarkerVisibility.always
                              ? MarkerVisibility.whenActive
                              : MarkerVisibility.always,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.7,
                          ),
                          minimumSize: const Size(32, 32),
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FormatChips(
                  onInsert: _insertText,
                  theme: theme,
                ),
                const SizedBox(height: 32),
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
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  },
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _CodePreview(
                  theme: theme,
                  code: 'Textf(\n'
                      "  'Built with {flutter} and {dart}. "
                      "Made with {love}.\\n'\n"
                      "  'Flutter package '\n"
                      "  '[textf on pub.dev](https://pub.dev/packages/textf) '\n"
                      "  'and the '\n"
                      "  '[GitHub repo](https://github.com/PhilippHGerber/textf).',\n"
                      '  placeholders: {\n'
                      "    'flutter': WidgetSpan(\n"
                      "      child: Image.asset('flutter.png', height: 16),\n"
                      '    ),\n'
                      "    'dart': WidgetSpan(\n"
                      "      child: Image.asset('dart.png', height: 16),\n"
                      '    ),\n'
                      "    'love': WidgetSpan(\n"
                      '      child: Icon(Icons.favorite, color: Colors.red),\n'
                      '    ),\n'
                      '  },\n'
                      ')',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _CodePreview extends StatelessWidget {
  const _CodePreview({required this.theme, required this.code});
  final ThemeData theme;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 12,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _chip('**bold**'),
          _chip('*italic*'),
          _chip('~~strike~~'),
          _chip('++underline++'),
          _chip('==highlight=='),
          _chip('`code`'),
          _chip('E=mc^2^'),
          _chip('H~2~O'),
          _chip('[link](https://flutter.dev/)'),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return ActionChip(
      label: IgnorePointer(
        child: Textf(
          label,
          style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 11),
        ),
      ),
      onPressed: () => onInsert('$label '),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
