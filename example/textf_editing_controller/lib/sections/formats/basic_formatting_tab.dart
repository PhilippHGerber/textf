import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '/widgets/example_card.dart';

class BasicFormattingTab extends StatelessWidget {
  const BasicFormattingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ExampleCard(
          title: 'Bold',
          description: 'Markers: ** or __',
          code: '**bold text**',
          child: Textf('**bold text**'),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Italic',
          description: 'Markers: * or _',
          code: '*italic text*',
          child: Textf('*italic text*'),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Bold + Italic',
          description: 'Markers: *** or ___',
          code: '***bold and italic***',
          child: Textf('***bold and italic***'),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Strikethrough',
          description: 'Markers: ~~',
          code: '~~strikethrough~~',
          child: Textf('~~strikethrough~~'),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Underline',
          description: 'Markers: ++',
          code: '++underline++',
          child: Textf('++underline++'),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Highlight',
          description: 'Markers: ==',
          code: '==highlighted==',
          child: Textf('==highlighted=='),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Inline Code',
          description: 'Markers: `',
          code: '`inline code`',
          child: Textf('`inline code`'),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Superscript',
          description: 'Markers: ^',
          code: 'E=mc^2^',
          child: Textf('E=mc^2^'),
        ),
        SizedBox(height: 8),
        ExampleCard(
          title: 'Subscript',
          description: 'Markers: ~',
          code: 'H~2~O',
          child: Textf('H~2~O'),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
