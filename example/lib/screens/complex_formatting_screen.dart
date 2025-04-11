import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class ComplexFormattingScreen extends StatelessWidget {
  const ComplexFormattingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complex Formatting'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ExampleCard(
              title: 'Mixed Formatting',
              description: 'Combining multiple formatting styles in one text',
              code:
                  'Textf(\n  \'The **quick** _brown_ fox jumps over the ~~lazy~~ `dog`.\',\n  style: TextStyle(fontSize: 16),\n)',
              child: Textf(
                'The **quick** _brown_ fox jumps over the ~~lazy~~ `dog`.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Style Customization',
              description: 'Using custom text style properties',
              code:
                  'Textf(\n  \'**Styled** _text_ with ~~formatting~~\',\n  style: TextStyle(\n    fontSize: 18,\n    color: Colors.blue,\n    height: 1.5,\n  ),\n  textAlign: TextAlign.center,\n)',
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
              code:
                  'Textf(\n  \'**你好世界** *안녕하세요* ~~Привет~~ `🌍`\',\n  style: TextStyle(fontSize: 16),\n)',
              child: Textf(
                '**你好世界** *안녕하세요* ~~Привет~~ `🌍`',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Long Text with Overflow',
              description: 'Handling long text with ellipsis',
              code:
                  'Textf(\n  \'This is a **very long** text with _multiple_ formatting styles that will ~~likely~~ overflow and `demonstrate` how ellipsis works with formatted text.\',\n  style: TextStyle(fontSize: 16),\n  maxLines: 2,\n  overflow: TextOverflow.ellipsis,\n)',
              child: Textf(
                'This is a **very long** text with _multiple_ formatting styles that will ~~likely~~ overflow and `demonstrate` how ellipsis works with formatted text.',
                style: TextStyle(fontSize: 16),
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
