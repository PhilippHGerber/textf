// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '/widgets/docs_pager.dart';
import '/widgets/section_header.dart';
import '../../router/docs_routes.dart';

/// Overview documentation page — what Textf is and when to use it.
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Overview',
                subtitle: 'What Textf is and when to use it',
              ),
              const SizedBox(height: 32),
              Text(
                'What Textf provides',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _FeatureBullets(),
              const SizedBox(height: 32),
              const _TwoColumnCards(),
              const SizedBox(height: 32),
              Text(
                'Limitations',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _LimitationsTable(),
              const SizedBox(height: 32),
              Text(
                'Textf vs Full Markdown',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _ComparisonTable(),
              const SizedBox(height: 32),
              const _WhenToUse(),
              const SizedBox(height: 48),
              const DocsPager(current: DocsRoutes.overview),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBullets extends StatelessWidget {
  const _FeatureBullets();

  static const _bullets = [
    '**Bold** text with `**markers**`',
    '*Italic* text with `*markers*`',
    '`Inline code` with backtick markers',
    '==Highlight== with `==markers==`',
    '[Links](.) with `[text](url)` syntax',
    '~~Strikethrough~~ with `~~markers~~`',
    '++Underline++ with `++markers++`',
    'x^2^ superscript and H~2~O subscript',
    'Widget placeholders with `{key}` syntax',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _bullets.map((bullet) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Textf(bullet, style: theme.textTheme.bodyMedium)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TwoColumnCards extends StatelessWidget {
  const _TwoColumnCards();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    const cardA = _InfoCard(
      icon: Icons.text_fields,
      title: '`Textf` Widget',
      body: "A drop-in replacement for Flutter's `Text` widget. "
          'Pass any string with inline markers and Textf renders it with '
          '**bold**, *italic*, `code`, ==highlights==, [links](.), and more.',
    );
    const cardB = _InfoCard(
      icon: Icons.edit_outlined,
      title: '`TextfEditingController`',
      body: 'A drop-in replacement for `TextEditingController`. '
          'Renders formatting markers live as the user types in a `TextField` — '
          '_no extra widgets needed_.',
    );

    if (isWide) {
      return const IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cardA),
            SizedBox(width: 16),
            Expanded(child: cardB),
          ],
        ),
      );
    }
    return const Column(
      children: [cardA, SizedBox(height: 16), cardB],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 24),
          const SizedBox(height: 10),
          Textf(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Textf(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LimitationsTable extends StatelessWidget {
  const _LimitationsTable();

  static const _rows = [
    ('No block elements', 'No headings, lists, blockquotes, or tables'),
    ('Max 2 nesting levels', '`**bold _italic_**` works; deeper nesting renders as plain text'),
    ('Inline only', 'Each `Textf` renders a single paragraph / inline span tree'),
    ('No HTML', 'Raw HTML tags are not parsed or rendered'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _rows.indexed.map((entry) {
          final (i, row) = entry;
          return Container(
            decoration: BoxDecoration(
              color: i.isEven ? cs.surfaceContainerLow : null,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    row.$1,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Textf(row.$2, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  static const _rows = [
    ('Inline bold, italic, code', true, true),
    ('Links', true, true),
    ('Highlight, underline, super/sub', true, false),
    ('Widget placeholders', true, false),
    ('Live editing controller', true, false),
    ('Block elements (headings, lists)', false, true),
    ('Tables, blockquotes', false, true),
    ('Zero dependencies', true, false),
    ('O(N) single-pass parser', true, false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Textf',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Full MD',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ..._rows.indexed.map((entry) {
            final (i, row) = entry;
            return Container(
              decoration: BoxDecoration(
                color: i.isEven ? cs.surfaceContainerLow : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row.$1, style: theme.textTheme.bodyMedium),
                  ),
                  SizedBox(
                    width: 80,
                    child: Icon(
                      row.$2 ? Icons.check : Icons.close,
                      size: 18,
                      color: row.$2 ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Icon(
                      row.$3 ? Icons.check : Icons.close,
                      size: 18,
                      color: row.$3 ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WhenToUse extends StatelessWidget {
  const _WhenToUse();

  static const _greatFor = [
    'Chat messages with **bold** names',
    'Notifications with ==highlighted== info',
    'Labels with `inline code` snippets',
    'Live-formatted `TextField` inputs',
    'Captions with [clickable links](https://pub.dev/packages/textf)',
  ];

  static const _notFor = [
    'Full Markdown documents',
    'Headings and list rendering',
    'Complex nested block structures',
    'HTML rendering',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When to use Textf',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (isWide)
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WhenCard(
                    icon: Icons.thumb_up_outlined,
                    title: 'Great for',
                    items: _greatFor,
                    positive: true,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _WhenCard(
                    icon: Icons.thumb_down_outlined,
                    title: 'Not for',
                    items: _notFor,
                    positive: false,
                  ),
                ),
              ],
            ),
          )
        else
          const Column(
            children: [
              _WhenCard(
                icon: Icons.thumb_up_outlined,
                title: 'Great for',
                items: _greatFor,
                positive: true,
              ),
              SizedBox(height: 16),
              _WhenCard(
                icon: Icons.thumb_down_outlined,
                title: 'Not for',
                items: _notFor,
                positive: false,
              ),
            ],
          ),
      ],
    );
  }
}

class _WhenCard extends StatelessWidget {
  const _WhenCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.positive,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: positive ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    positive ? Icons.check : Icons.close,
                    size: 14,
                    color: positive ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Textf(item, style: theme.textTheme.bodySmall)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
