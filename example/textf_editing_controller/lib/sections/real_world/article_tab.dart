// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleTab extends StatelessWidget {
  const ArticleTab({super.key});

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Article Layout',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Formatted content in a blog-style layout.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextfOptions(
              onLinkTap: (url, _) => _launchUrl(url),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Textf(
                        '**Flutter 4.0 Released**',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Textf(
                        '*By the Flutter Team  ·  March 2026*',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Divider(height: 32, color: cs.outlineVariant.withValues(alpha: 0.5)),
                      Textf(
                        'The **Impeller** renderer now delivers `60fps` on all supported '
                        'platforms, bringing smooth animations to even the most complex UIs.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Textf(
                        'This ==major milestone== comes after two years of development. '
                        'The team also improved the ~~build pipeline~~ **tooling** significantly, '
                        'cutting compile times by *40%*.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        children: [
                          Textf(
                            '[Release notes](https://pub.dev/packages/textf)',
                            style: TextStyle(color: cs.primary),
                          ),
                          Textf(
                            '[Migration guide](https://pub.dev/packages/textf)',
                            style: TextStyle(color: cs.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
