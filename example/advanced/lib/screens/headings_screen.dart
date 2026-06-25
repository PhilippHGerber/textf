import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class HeadingsScreen extends StatelessWidget {
  const HeadingsScreen({
    required this.toggleThemeMode,
    super.key,
  });
  final VoidCallback toggleThemeMode;

  @override
  Widget build(BuildContext context) {
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon =
        currentBrightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Headings'),
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
              title: 'All Six Levels',
              description: "1–6 '#' at the start of a line; style scopes to the line's end",
              code: r"Textf('# H1\n## H2\n### H3\n#### H4\n##### H5\n###### H6\nbody')",
              child: Textf(
                '# Heading 1\n'
                '## Heading 2\n'
                '### Heading 3\n'
                '#### Heading 4\n'
                '##### Heading 5\n'
                '###### Heading 6\n'
                'Normal body text.',
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Inline Formatting Nests',
              description: 'Bold, italic, etc. compose inside a heading line',
              code: "Textf('# Heading with **bold** and *italic*')",
              child: Textf('# Heading with **bold** and *italic*'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Not a Heading Mid-Line',
              description: "'#' only starts a heading at the beginning of a line",
              code: "Textf('Use C# and #hashtags freely.')",
              child: Textf('Use C# and #hashtags freely.'),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Custom Heading Styles',
              description: 'Override any level via TextfOptions h1Style–h6Style',
              code: 'TextfOptions(h1Style: ..., h2Style: ..., child: Textf(...))',
              child: TextfOptions(
                h1Style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepPurple,
                ),
                h2Style: TextStyle(fontSize: 24, color: Colors.purple),
                child: Textf(
                  '# Custom H1\n'
                  '## Custom H2\n'
                  'Default-styled body.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
