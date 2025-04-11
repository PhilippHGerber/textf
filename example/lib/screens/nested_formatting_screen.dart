import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class NestedFormattingScreen extends StatelessWidget {
  const NestedFormattingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested Formatting'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ExampleCard(
              title: 'Bold with Italic',
              description:
                  'Bold text containing italic text (using different markers)',
              code:
                  'Textf(\n  \'**Bold with _italic_ inside**\',\n  style: TextStyle(fontSize: 16),\n)',
              child: Textf(
                '**Bold with _italic_ inside**',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Italic with Bold',
              description:
                  'Italic text containing bold text (using different markers)',
              code:
                  'Textf(\n  \'*Italic with __bold__ inside*\',\n  style: TextStyle(fontSize: 16),\n)',
              child: Textf(
                '*Italic with __bold__ inside*',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Bold with Code',
              description: 'Bold text containing code',
              code:
                  'Textf(\n  \'**Bold with `code` inside**\',\n  style: TextStyle(fontSize: 16),\n)',
              child: Textf(
                '**Bold with `code` inside**',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'Italic with Strikethrough',
              description: 'Italic text containing strikethrough text',
              code:
                  'Textf(\n  \'*Italic with ~~strikethrough~~ inside*\',\n  style: TextStyle(fontSize: 16),\n)',
              child: Textf(
                '*Italic with ~~strikethrough~~ inside*',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ExampleCard(
              title: 'What Not To Do',
              description:
                  'Using same marker type for nested formatting (may not work as expected)',
              code:
                  'Textf(\n  \'**Bold with *italic* inside**\',\n  style: TextStyle(fontSize: 16),\n)',
              child: Textf(
                '**Bold with *italic* inside**',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
