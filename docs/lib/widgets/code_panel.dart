// ignore_for_file: no-magic-number

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A code snippet panel with a copy-to-clipboard button.
///
/// Use [borderRadius] to connect it visually to a result container below:
/// pass top-only corners when paired, or the default full radius for standalone use.
class CodePanel extends StatelessWidget {
  const CodePanel({
    required this.code,
    this.title,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.key,
  });

  final String code;
  final String? title;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title case final titleText?) ...[
          Text(
            titleText,
            style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
        ],
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: borderRadius,
              ),
              child: SelectableText(
                code,
                style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: 'Copy to clipboard',
                onPressed: () {
                  unawaited(Clipboard.setData(ClipboardData(text: code)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
