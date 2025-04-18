import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class NestedFormattingScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const NestedFormattingScreen({
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
        title: const Text('Nested Formatting'),
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
              title: 'Bold with Italic',
              description: 'Bold text containing italic text (using different markers)',
              code: 'Textf(\n  \'**Bold with _italic_ inside**\',\n  \n)',
              child: Textf(
                '**Bold with _italic_ inside**',
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Italic with Bold',
              description: 'Italic text containing bold text (using different markers)',
              code: 'Textf(\n  \'*Italic with __bold__ inside*\',\n  \n)',
              child: Textf(
                '*Italic with __bold__ inside*',
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Bold with Code',
              description: 'Bold text containing code',
              code: 'Textf(\n  \'**Bold with `code` inside**\',\n  \n)',
              child: Textf(
                '**Bold with `code` inside**',
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Italic with Strikethrough',
              description: 'Italic text containing strikethrough text',
              code: 'Textf(\n  \'*Italic with ~~strikethrough~~ inside*\',\n  \n)',
              child: Textf(
                '*Italic with ~~strikethrough~~ inside*',
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'What Not To Do',
              description: 'Using same marker type for nested formatting (may not work as expected)',
              code: 'Textf(\n  \'**Bold with *italic* inside**\',\n  \n)',
              child: Textf(
                '**Bold with *italic* inside**',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
