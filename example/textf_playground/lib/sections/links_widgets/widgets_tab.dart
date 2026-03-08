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
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Widget Placeholders',
          subtitle: 'Use {key} to embed inline widgets inside formatted text.',
        ),
        const SizedBox(height: 12),
        const ExampleCard(
          title: 'Icon placeholder',
          description: 'Map a key to any widget',
          code: 'Textf(\n'
              "  'Tap {heart} to like',\n"
              '  placeholders: {\n'
              "    'heart': WidgetSpan(child: Icon(Icons.favorite_border)),\n"
              '  },\n'
              ')',
          child: Textf(
            'Tap {heart} to like',
            placeholders: {
              'heart': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.favorite_border, size: 18, color: Colors.red),
              ),
            },
          ),
        ),
        const SizedBox(height: 8),
        ExampleCard(
          title: 'Image placeholder',
          description: 'Embed image assets inline',
          code: 'Textf(\n'
              "  'Built with {flutter} and {dart}',\n"
              '  placeholders: {\n'
              "    'flutter': WidgetSpan(child: Image.asset('flutter.png', height: 16)),\n"
              "    'dart': WidgetSpan(child: Image.asset('dart.png', height: 16)),\n"
              '  },\n'
              ')',
          child: Textf(
            'Built with {flutter} and {dart}',
            placeholders: {
              'flutter': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Image.asset('assets/img/flutter.png', height: 16),
              ),
              'dart': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Image.asset('assets/img/dart.png', height: 16),
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
        const ExampleCard(
          title: 'Badge placeholder',
          description: 'Any widget can be embedded',
          code: 'Textf(\n'
              "  'Hello {admin}',\n"
              "  placeholders: {'admin': WidgetSpan(child: _Badge())},\n"
              ')',
          child: Textf(
            'Hello {admin}',
            placeholders: {
              'admin': WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _Badge(),
              ),
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'admin',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
