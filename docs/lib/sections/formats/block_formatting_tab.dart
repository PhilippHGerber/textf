// ignore_for_file: no-magic-number

import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';

import '/widgets/example_card.dart';
import '/widgets/section_header.dart';

class BlockFormattingTab extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Headings',
          subtitle: 'Start a line with one to six # characters, followed by a space or tab.',
        ),
        const SizedBox(height: 12),
        const ExampleCard(
          title: 'Heading levels',
          description: 'Markers: # to ######',
          code: '# Heading 1\n## Heading 2\n### Heading 3\n#### Heading 4\n##### Heading 5\n###### Heading 6',
          child: Textf(
            '# Heading 1\n## Heading 2\n### Heading 3\n#### Heading 4\n##### Heading 5\n###### Heading 6',
          ),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'Inline formatting in headings',
          description: 'A heading styles its line; inline markers still apply',
          code: '## Release *notes* for `textf`\nBody text continues on the next line.',
          child: Textf('## Release *notes* for `textf`\nBody text continues on the next line.'),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'Closing sequence and indentation',
          description: 'Trailing # characters are dropped; up to 3 leading spaces are allowed',
          code: '## Closed heading ##\n   ### Indented heading',
          child: Textf('## Closed heading ##\n   ### Indented heading'),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'Not a heading',
          description: 'No space after the #, more than six #, or an escaped #',
          code: '#hashtag\n####### seven\n\\# escaped',
          child: Textf('#hashtag\n####### seven\n\\# escaped'),
        ),
        const SizedBox(height: 8),
        ExampleCard(
          title: 'Custom heading style',
          description: 'h1Style to h6Style merge onto the built-in size and weight',
          code:
              'TextfOptions(\n'
              '  h2Style: TextStyle(color: colorScheme.primary),\n'
              "  child: Textf('## Colored heading'),\n"
              ')',
          child: TextfOptions(
            h2Style: TextStyle(color: cs.primary),
            child: const Textf('## Colored heading'),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Thematic Breaks',
          subtitle: 'A line of three or more -, * or _ renders as a full-width divider.',
        ),
        const SizedBox(height: 12),
        const ExampleCard(
          title: 'Thematic break',
          description: 'Markers: ---, *** or ___',
          code: 'Above the break\n---\nBelow the break',
          child: Textf('Above the break\n---\nBelow the break'),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'Marker variants',
          description: 'Longer runs and spaces between the markers are allowed',
          code: 'One\n***\nTwo\n_____\nThree\n- - -\nFour',
          child: Textf('One\n***\nTwo\n_____\nThree\n- - -\nFour'),
        ),
        const SizedBox(height: 8),
        ExampleCard(
          title: 'Custom color',
          description: 'thematicBreakColor tints the default 1px rule',
          code:
              'TextfOptions(\n'
              '  thematicBreakColor: colorScheme.primary,\n'
              "  child: Textf('Above\\n---\\nBelow'),\n"
              ')',
          child: TextfOptions(
            thematicBreakColor: cs.primary,
            child: const Textf('Above\n---\nBelow'),
          ),
        ),
        const SizedBox(height: 8),
        ExampleCard(
          title: 'Custom builder',
          description: 'thematicBreakBuilder replaces the rule with any widget',
          code:
              'TextfOptions(\n'
              '  thematicBreakBuilder: (context) => Divider(\n'
              '    thickness: 3,\n'
              '    color: colorScheme.tertiary,\n'
              '  ),\n'
              "  child: Textf('Above\\n---\\nBelow'),\n"
              ')',
          child: TextfOptions(
            thematicBreakBuilder: (context) => Divider(thickness: 3, color: cs.tertiary),
            child: const Textf('Above\n---\nBelow'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
