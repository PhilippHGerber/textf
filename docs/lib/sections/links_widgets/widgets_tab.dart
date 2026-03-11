// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '/widgets/example_card.dart';
import '/widgets/section_header.dart';

class WidgetsTab extends StatelessWidget {
  const WidgetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Widget Placeholders',
          subtitle: 'Use {key} to embed inline widgets inside formatted text.',
        ),
        const SizedBox(height: 12),
        ExampleCard(
          title: 'Icon placeholder',
          description: 'Map a key to any widget, embed image assets inline',
          code: '''
Textf('This is a star icon: {star}. And this is a ~~cat~~ bird: {bird}'
  placeholders: {
    'star': WidgetSpan(child: Icon(Icons.star, color: Colors.amber)),
    'bird': WidgetSpan(child: Image.asset('bird.png')),
  },
)
''',
          child: Textf(
            'This is a star icon: {star}. And this is a ~~cat~~ bird: {bird}',
            placeholders: {
              'star': const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.star, color: Colors.amber),
              ),
              'bird': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Image.asset('assets/img/bird.png', height: 28),
              ),
            },
          ),
        ),
        const SizedBox(height: 8),
        ExampleCard(
          title: 'Rich Media Support',
          description:
              'Support for animated GIFs and other media assets, allowing for more dynamic content.',
          code: '''
Textf(
  'Witness the flight of the bird: {bird}',
  placeholders: {
    'bird': WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Image.asset('bird.gif'),
    ),
  },
)''',
          child: Textf(
            'Witness the flight of the bird: {bird}',
            placeholders: {
              'bird': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Image.asset('assets/img/bird.gif', width: 48, height: 48),
              ),
            },
          ),
        ),
        const SizedBox(height: 8),
        const ExampleCard(
          title: 'Style inheritance',
          description: 'Placeholders inside formatted text',
          code: 'Textf(\n'
              "  '**Bold {star} star**',\n"
              '  placeholders: {\n'
              "    'star': WidgetSpan(child: Icon(Icons.star, size: 16)),\n"
              '  },\n'
              ')',
          child: Textf(
            '**Bold {star} star**',
            placeholders: {
              'star': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.star, size: 16, color: Colors.amber),
              ),
            },
          ),
        ),
        const SizedBox(height: 8),
        ExampleCard(
          title: 'Badge placeholder',
          description:
              'Build complex inline elements like badges, tags, or status indicators using standard Flutter widgets.',
          code: '''
Textf(
  'The user {admin} has been successfully verified.',
  placeholders: {
    'admin': WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 12)),
      ),
    ),
  },
)''',
          child: Textf(
            'The user {admin} has been successfully verified.',
            style: const TextStyle(fontSize: 18),
            placeholders: {
              'admin': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
