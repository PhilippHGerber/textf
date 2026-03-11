// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/code_panel.dart';
import '/widgets/section_header.dart';

class StylingSection extends StatefulWidget {
  const StylingSection({super.key});

  @override
  State<StylingSection> createState() => _StylingSectionState();
}

class _StylingSectionState extends State<StylingSection> {
  int _boldColorIdx = 0;
  int _boldWeightIdx = 3; // default: FontWeight.bold (w700)
  int _boldStyleIdx = 0; // default: FontStyle.normal
  int _boldBgIdx = 0; // 0 = none (transparent)
  int _highlightIdx = 0;

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  String _colorHex(Color c) => '0x${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Bold color
    final boldColors = <Color>[cs.primary, cs.secondary, cs.tertiary, cs.onSurface];
    final boldColorLabels = ['Primary', 'Secondary', 'Tertiary', 'OnSurface'];

    // Bold weight options
    final boldWeights = [
      FontWeight.w200,
      FontWeight.w400,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w900,
    ];
    final boldStyles = [FontStyle.normal, FontStyle.italic];
    final boldWeightLabels = ['Light', 'Regular', 'SemiBold', 'Bold', 'Black'];
    final boldStyleLabels = ['Normal', 'Italic'];

    // Bold background
    final boldBgs = <Color>[
      Colors.transparent, // None
      // raibow colors
      const Color(0x2200C853), // mint
      const Color(0x22AA00FF), // lavender
      const Color(0x22FF6D00), // coral
      const Color(0x220091EA), // sky
    ];
    final boldBgLabels = ['None', 'Mint', 'Lavender', 'Coral', 'Sky'];

    // Highlight
    final highlightColors = <Color>[
      const Color(0x66FFD700), // gold
      const Color(0x5500C853), // mint
      const Color(0x55AA00FF), // lavender
      const Color(0x55FF6D00), // coral
      const Color(0x550091EA), // sky
    ];
    final highlightLabels = ['Gold', 'Mint', 'Lavender', 'Coral', 'Sky'];

    final boldBgLine = _boldBgIdx == 0
        ? '\n    // backgroundColor: null, '
        : '\n    backgroundColor: Color(${_colorHex(boldBgs[_boldBgIdx])}),';
    final boldWeightName = [
      'FontWeight.w200',
      'FontWeight.w400',
      'FontWeight.w600',
      'FontWeight.w700',
      'FontWeight.w900',
    ][_boldWeightIdx];

    final generatedCode = '''
TextfOptions(
  boldStyle: TextStyle(
    fontWeight: $boldWeightName,
    fontStyle: ${boldStyles[_boldStyleIdx] == FontStyle.italic ? 'FontStyle.italic' : 'FontStyle.normal'},
    color: Color(${_colorHex(boldColors[_boldColorIdx])}),$boldBgLine
  ),
  highlightStyle: TextStyle(
    backgroundColor: Color(${_colorHex(highlightColors[_highlightIdx])}),
  ),
  child: Textf(...),
)''';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Live Style Customizer',
                subtitle: 'Every marker type — bold, italic, code, highlight, links and more — '
                    'can be fully customized with any TextStyle property.',
              ),
              const SizedBox(height: 16),
              // Bold weight control
              _ChipControl(
                label: 'Bold weight',
                options: boldWeightLabels,
                selected: _boldWeightIdx,
                onSelect: (i) => setState(() => _boldWeightIdx = i),
              ),
              const SizedBox(height: 12),
              _ChipControl(
                label: 'Bold style',
                options: boldStyleLabels,
                selected: _boldStyleIdx,
                onSelect: (i) => setState(() => _boldStyleIdx = i),
              ),
              const SizedBox(height: 12),
              _StyleControl(
                label: 'Bold color',
                segments: boldColorLabels,
                selected: _boldColorIdx,
                onSelect: (i) => setState(() => _boldColorIdx = i),
                colors: boldColors,
              ),
              const SizedBox(height: 12),
              // Bold background control
              _StyleControl(
                label: 'Bold background',
                segments: boldBgLabels,
                selected: _boldBgIdx,
                onSelect: (i) => setState(() => _boldBgIdx = i),
                colors: boldBgs,
              ),
              const SizedBox(height: 12),
              // Highlight color control
              _StyleControl(
                label: 'Highlight',
                segments: highlightLabels,
                selected: _highlightIdx,
                onSelect: (i) => setState(() => _highlightIdx = i),
                colors: highlightColors,
              ),
              const SizedBox(height: 24),
              CodePanel(
                code: generatedCode,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              TextfOptions(
                boldStyle: TextStyle(
                  fontWeight: boldWeights[_boldWeightIdx],
                  fontStyle: boldStyles[_boldStyleIdx],
                  color: boldColors[_boldColorIdx],
                  backgroundColor: _boldBgIdx == 0 ? null : boldBgs[_boldBgIdx],
                ),
                highlightStyle: TextStyle(
                  backgroundColor: highlightColors[_highlightIdx],
                ),
                onLinkTap: (url, _) => _launchUrl(url),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: const Textf(
                    '**bold text** and ==highlighted==',
                    textAlign: TextAlign.center,
                  ),
                ),
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
    final cs = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Wrap(
          spacing: 8,
          children: List.generate(segments.length, (i) {
            final isSelected = i == selected;
            final swatchColor = colors[i];
            final isNone = (swatchColor.a * 255.0).round().clamp(0, 255) == 0;
            final onSwatch = isNone
                ? cs.outline
                : ThemeData.estimateBrightnessForColor(swatchColor) == Brightness.dark
                    ? Colors.white
                    : Colors.black87;
            return Tooltip(
              message: segments[i],
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isNone ? cs.surface : swatchColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? cs.onSurface
                          : isNone
                              ? cs.outline.withValues(alpha: 0.5)
                              : cs.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected && !isNone
                        ? [
                            BoxShadow(
                              color: swatchColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 14, color: onSwatch)
                      : isNone
                          ? Icon(Icons.block, size: 14, color: cs.outline)
                          : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ChipControl extends StatelessWidget {
  const _ChipControl({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Wrap(
          spacing: 8,
          children: List.generate(options.length, (i) {
            return ChoiceChip(
              label: Text(options[i]),
              selected: i == selected,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onSelect(i),
            );
          }),
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
