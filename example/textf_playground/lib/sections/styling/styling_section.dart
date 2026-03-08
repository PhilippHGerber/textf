// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/section_header.dart';

class StylingSection extends StatefulWidget {
  const StylingSection({super.key});

  @override
  State<StylingSection> createState() => _StylingSectionState();
}

class _StylingSectionState extends State<StylingSection> {
  int _boldVariant = 0;
  int _codeVariant = 0;
  int _highlightVariant = 0;

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final boldColors = <Color>[
      cs.primary,
      cs.error,
      cs.tertiary,
      cs.onSurface,
    ];
    final boldLabels = ['Primary', 'Error', 'Tertiary', 'Default'];

    final codeBgs = <Color>[
      cs.primaryContainer,
      const Color(0xFFFFF9C4),
      const Color(0xFFDCEDC8),
    ];
    final codeLabels = ['Primary', 'Amber', 'Green'];

    final highlightBgs = <Color>[
      const Color(0x66FFD700),
      const Color(0x5500BCD4),
      const Color(0x55FF4081),
    ];
    final highlightLabels = ['Amber', 'Cyan', 'Pink'];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(
              title: 'Live Style Customizer',
              subtitle: 'Adjust TextfOptions properties and see the preview update instantly.',
            ),
            const SizedBox(height: 16),
            // Preview
            TextfOptions(
              boldStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: boldColors[_boldVariant],
              ),
              codeStyle: TextStyle(
                fontFamily: 'RobotoMono',
                backgroundColor: codeBgs[_codeVariant],
              ),
              highlightStyle: TextStyle(
                backgroundColor: highlightBgs[_highlightVariant],
              ),
              onLinkTap: (url, _) => _launchUrl(url),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: const Textf(
                  '**bold** *italic* `code` ==highlight== [link](https://pub.dev/packages/textf)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bold color control
            _StyleControl(
              label: 'Bold color',
              segments: boldLabels,
              selected: _boldVariant,
              onSelect: (i) => setState(() => _boldVariant = i),
              colors: boldColors,
            ),
            const SizedBox(height: 12),
            // Code background control
            _StyleControl(
              label: 'Code background',
              segments: codeLabels,
              selected: _codeVariant,
              onSelect: (i) => setState(() => _codeVariant = i),
              colors: codeBgs,
            ),
            const SizedBox(height: 12),
            // Highlight color control
            _StyleControl(
              label: 'Highlight color',
              segments: highlightLabels,
              selected: _highlightVariant,
              onSelect: (i) => setState(() => _highlightVariant = i),
              colors: highlightBgs,
            ),
            const SizedBox(height: 32),
            const SectionHeader(
              title: 'Hierarchical Merging',
              subtitle:
                  'Inner TextfOptions override outer ones. Other styles are inherited from the parent.',
            ),
            const SizedBox(height: 16),
            _HierarchyDemo(),
            const SizedBox(height: 32),
            const SectionHeader(
              title: 'Theme-Aware Defaults',
              subtitle: 'Code and link styles adapt automatically to light and dark themes.',
            ),
            const SizedBox(height: 12),
            TextfOptions(
              onLinkTap: (url, _) => _launchUrl(url),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: const Textf(
                  'Default `inline code` and [link](https://pub.dev/packages/textf) '
                  'styling adapts to the current theme.',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StyleControl extends StatelessWidget {
  const _StyleControl({
    required this.label,
    required this.segments,
    required this.selected,
    required this.onSelect,
    required this.colors,
  });

  final String label;
  final List<String> segments;
  final int selected;
  final ValueChanged<int> onSelect;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: SegmentedButton<int>(
            segments: List<ButtonSegment<int>>.generate(
              segments.length,
              (i) => ButtonSegment<int>(
                value: i,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(segments[i]),
                  ],
                ),
              ),
            ),
            selected: {selected},
            onSelectionChanged: (s) => onSelect(s.first),
            showSelectedIcon: false,
          ),
        ),
      ],
    );
  }
}

class _HierarchyDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: TextfOptions(
        boldStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outer TextfOptions(boldStyle: blue)',
              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            const Textf('**Blue bold** from outer options'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextfOptions(
                boldStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inner TextfOptions(boldStyle: red)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Textf('**Red bold** — inner wins'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
