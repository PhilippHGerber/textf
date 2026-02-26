// example/textf_core/lib/screens/basic_formatting_screen.dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class BasicFormattingScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const BasicFormattingScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the icon based on the current theme mode
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon =
        currentBrightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Formatting'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: toggleThemeMode,
          ),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ExampleCard(
              title: 'Bold',
              description: 'Use ** or __ to make text bold',
              code: "Textf('This is **bold** text')",
              child: Textf('This is **bold** text'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Italic',
              description: 'Use * or _ to make text italic',
              code: "Textf('This is *italic* text')",
              child: Textf('This is *italic* text'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Bold and Italic',
              description: 'Use *** or ___ for both bold and italic',
              code: "Textf('This is ***bold and italic*** text')",
              child: Textf('This is ***bold and italic*** text'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Strikethrough',
              description: 'Use ~~ for strikethrough text',
              code: "Textf('This is ~~strikethrough~~ text')",
              child: Textf('This is ~~strikethrough~~ text'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Underline',
              description: 'Use ++ for underlined text',
              code: "Textf('This is ++underlined++ text')",
              child: Textf('This is ++underlined++ text'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Highlight',
              description: 'Use == for highlighted text (theme-aware default)',
              code: "Textf('This is ==highlighted== text')",
              child: Textf('This is ==highlighted== text'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Code',
              description: 'Use backticks for inline code (theme-aware default)',
              code: "Textf('This is `code` text')",
              child: Textf('This is `code` text'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Escaped Characters',
              description: 'Use backslash to escape formatting characters',
              code:
                  "Textf('Escape: \\*bold\\*, \\_italic\\_, \\~\\~strike\\~\\~, \\+\\+underline\\+\\+, \\=\\=highlight\\=\\=, \\`code\\`')",
              child: Textf(
                'Escape: \\*bold\\*, \\_italic\\_, \\~\\~strike\\~\\~, \\+\\+underline\\+\\+, \\=\\=highlight\\=\\=, \\`code\\`',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
