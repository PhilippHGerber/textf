import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

class PlaceholderExampleScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const PlaceholderExampleScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placeholder Examples'),
        actions: [
          IconButton(
            icon: Icon(
              currentThemeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: toggleThemeMode,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can inject any InlineSpan using {{N}} syntax:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Textf(
                'Hello! This is a star icon: {{1}}. And this is a cat: {{2}}\n\n'
                'You can also mix with **bold {{1}}** or _italic {{1}}_!',
                style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
                inlineSpans: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset(
                      'assets/img/cat.gif',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Code:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black87,
              child: const Text(
                'Textf(\n'
                "  'Icon: {{1}}, Image: {{2}}',\n"
                '  inlineSpans: [\n'
                '    WidgetSpan(child: Icon(Icons.star)),\n'
                "    WidgetSpan(child: Image.asset('cat.gif')),\n"
                '  ],\n'
                ')',
                style: TextStyle(fontFamily: 'monospace', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
