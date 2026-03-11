import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '/widgets/example_card.dart';
import '/widgets/section_header.dart';

class AdvancedFormattingTab extends StatelessWidget {
  const AdvancedFormattingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Backslash Escaping',
          subtitle: r'Prefix a marker with \ to render it as literal text.',
        ),
        const SizedBox(height: 12),
        const ExampleCard(
          title: 'Escaped asterisk',
          description: 'Backslash prevents formatting',
          code: r'\*not italic\*',
          child: Textf(r'\*not italic\*'),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'Escaped backtick',
          description: 'Backslash prevents formatting',
          code: r'\`not code\`',
          child: Textf(r'\`not code\`'),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Nesting',
          subtitle: 'Up to 2 levels of nesting are supported.',
        ),
        const SizedBox(height: 12),
        const ExampleCard(
          title: 'Valid nesting (2 levels)',
          description: 'Bold containing italic',
          code: '**bold _italic_** or ==highlight **bold** text==',
          child: Textf('**bold _italic_** or ==highlight **bold** text=='),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'Triple nesting (renders as plain text)',
          description: 'Deeper than 2 levels is not supported',
          code: '**bold _italic ++oops++_**',
          child: Textf('**bold _italic ++oops++_**'),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'String Extension',
          subtitle: 'Use .textf() on any String as a shorthand for the Textf widget.',
        ),
        const SizedBox(height: 12),
        ExampleCard(
          title: 'String.textf()',
          description: 'Convenience extension on String',
          code: "'**Hello** _world ^and flutter^_'.textf()",
          child: '**Hello** _world ^and flutter^_'.textf(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
