import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class ComplexFormattingScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const ComplexFormattingScreen({
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
        title: const Text('Complex Formatting'),
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
              title: 'Mixed Formatting',
              description: 'Combining multiple formatting styles in one text',
              code: '''
Textf(
  'The **quick** _brown_ fox '
  'jumps over the ~~lazy~~ `dog`.',

)''',
              child: Textf(
                'The **quick** _brown_ fox jumps over the ~~lazy~~ `dog`.',
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Style Customization',
              description: 'Using custom text style properties',
              code: '''
Textf(
  '**Styled** _text_ with ~~formatting~~',
  style: TextStyle(
    fontSize: 18,
    color: Colors.blue,
    height: 1.5,
  ),
  textAlign: TextAlign.center,
)''',
              child: Textf(
                '**Styled** _text_ with ~~formatting~~',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Unicode and Emoji Support',
              description: 'Formatting with non-Latin scripts and emoji',
              code: 'Textf(\n  \'**你好世界** *안녕하세요* ~~Привет~~ `🌍`\',\n  \n)',
              child: Textf(
                '**你好世界** *안녕하세요* ~~Привет~~ `🌍`',
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Long Text with Overflow',
              description: 'Handling long text with ellipsis',
              code: '''
Textf(
  'This is a **very long** text with _multiple_ '
  'formatting styles that will ~~likely~~ '
  'overflow and `demonstrate` how ellipsis works '
  'with formatted text.,

  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)''',
              child: Textf(
                'This is a **very long** text with _multiple_ formatting styles that will ~~likely~~ overflow and `demonstrate` how ellipsis works with formatted text.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
