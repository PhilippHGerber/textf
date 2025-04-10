import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';
import '../widgets/selectable_scaffold.dart';

class BasicFormattingScreen extends StatelessWidget {
  const BasicFormattingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectableScaffold(
      appBar: AppBar(
        title: const Text('Basic Formatting'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ExampleCard(
            title: 'Bold',
            description: 'Use ** or __ to make text bold',
            code: '''
Textf(
  'This is **bold** text',
  style: TextStyle(fontSize: 16),
)
''',
            child: Textf(
              'This is **bold** text',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 16),
          ExampleCard(
            title: 'Italic',
            description: 'Use * or _ to make text italic',
            code: '''
Textf(
  'This is *italic* text',
  style: TextStyle(fontSize: 16),
)
''',
            child: Textf(
              'This is *italic* text',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 16),
          ExampleCard(
            title: 'Bold and Italic',
            description: 'Use *** or ___ for both bold and italic',
            code:
                'Textf(\n  \'This is ***bold and italic*** text\',\n  style: TextStyle(fontSize: 16),\n)',
            child: Textf(
              'This is ***bold and italic*** text',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 16),
          ExampleCard(
            title: 'Strikethrough',
            description: 'Use ~~ for strikethrough text',
            code:
                'Textf(\n  \'This is ~~strikethrough~~ text\',\n  style: TextStyle(fontSize: 16),\n)',
            child: Textf(
              'This is ~~strikethrough~~ text',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 16),
          ExampleCard(
            title: 'Code',
            description: 'Use backticks for inline code',
            code:
                'Textf(\n  \'This is `code` text\',\n  style: TextStyle(fontSize: 16),\n)',
            child: Textf(
              'This is `code` text',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 16),
          ExampleCard(
            title: 'Escaped Characters',
            description: 'Use backslash to escape formatting characters',
            code:
                'Textf(\n  \'This is \\*not italic\\* but this is *italic*\',\n  style: TextStyle(fontSize: 16),\n)',
            child: Textf(
              'This is \\*not italic\\* but this is *italic*',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
