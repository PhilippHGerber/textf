// example/textf_core/lib/screens/complex_formatting_screen.dart
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
          children: [
            ExampleCard(
              title: 'Mixed Formatting',
              description: 'Combining multiple formatting styles in one text',
              code: '''
Textf(
  'The **quick** _brown_ fox jumps over '
  'the ~~lazy~~ ++wily++ ==alert== `dog`.'
)''',
              child: Textf(
                'The **quick** _brown_ fox jumps over '
                'the ~~lazy~~ ++wily++ ==alert== `dog`.',
              ),
            ),
            const SizedBox(height: 16),
            ExampleCard(
              title: 'Style Customization with TextfOptions',
              description: 'Using custom text style properties via TextfOptions for new formats',
              code: '''
TextfOptions(
  underlineStyle: TextStyle(
    decorationColor: Colors.deepOrange,
    decorationStyle: TextDecorationStyle.dotted,
    decorationThickness: 2,
  ),
  highlightStyle: TextStyle(
    backgroundColor: Colors.tealAccent.withOpacity(0.4),
    color: Colors.black,
    fontStyle: FontStyle.italic,
  ),
  child: Textf(
    '**Styled** _text_ with ~~formatting~~, '
    '++custom underline++, and ==custom highlight==.',
    style: TextStyle(
      fontSize: 18,
      height: 1.5,
    ),
    textAlign: TextAlign.center,
  ),
)''',
              child: TextfOptions(
                underlineStyle: const TextStyle(
                  decorationColor: Colors.deepOrange,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationThickness: 2,
                ),
                highlightStyle: TextStyle(
                  backgroundColor: Colors.tealAccent.withValues(alpha: .4),
                  color: Colors.black, // Text color for highlight
                  fontStyle: FontStyle.italic,
                ),
                child: Textf(
                  '**Styled** _text_ with ~~formatting~~, '
                  '++custom underline++, and ==custom highlight==.',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const ExampleCard(
              title: 'Unicode and Emoji Support',
              description: 'Formatting with non-Latin scripts and emoji, including new formats',
              code: "Textf('**你好世界** *안녕하세요* ~~Привет~~ `🌍` ++🤯++ ==👀==')",
              child: Textf(
                '**你好世界** *안녕하세요* ~~Привет~~ `🌍` ++🤯++ ==👀==',
              ),
            ),
            const SizedBox(height: 16),
            ExampleCard(
              title: 'Long Text with Overflow',
              description: 'Handling long text with ellipsis, including new formats',
              code: '''
Textf(
  'This is a **very long** text with _multiple_ '
  'formatting styles that will ~~likely~~ '
  'overflow, ++be underlined++, ==get highlighted==, '
  'and `demonstrate` how ellipsis works '
  'with formatted text.',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)''',
              child: Textf(
                'This is a **very long** text with _multiple_ '
                'formatting styles that will ~~likely~~ '
                'overflow, ++be underlined++, ==get highlighted==, '
                'and `demonstrate` how ellipsis works '
                'with formatted text.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            const ExampleCard(
              title: 'Combined Decorations',
              description: 'Demonstrating combined strikethrough and underline',
              code: "Textf('This text is ++~~both underlined and strikethrough~~++. And also ~~++vice versa++~~.')",
              child: Textf('This text is ++~~both underlined and strikethrough~~++. And also ~~++vice versa++~~.'),
            ),
          ],
        ),
      ),
    );
  }
}
