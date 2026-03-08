// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Mock Notifications',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Textf renders formatted notification body text.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _NotificationCard(
              icon: Icons.mail_outline,
              appName: 'Messages',
              title: '**New message from Alice**',
              body: 'She sent you a *photo* — meet at ==5pm== today!',
              time: 'now',
              color: cs.primaryContainer,
              onColor: cs.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            _NotificationCard(
              icon: Icons.code,
              appName: 'GitHub',
              title: '**Pull request merged**',
              body: 'Your PR `fix/textf-rendering` was merged into **main**.',
              time: '2 min ago',
              color: cs.secondaryContainer,
              onColor: cs.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            _NotificationCard(
              icon: Icons.calendar_today_outlined,
              appName: 'Calendar',
              title: '**Upcoming event**',
              body: '~~Team lunch~~ ==Flutter meetup== starts in *30 minutes*.',
              time: '5 min ago',
              color: cs.tertiaryContainer,
              onColor: cs.onTertiaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.appName,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String appName;
  final String title;
  final String body;
  final String time;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: onColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      appName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Textf(title, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Textf(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
