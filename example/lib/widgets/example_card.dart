// example/lib/widgets/example_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final String code;
  final Widget child;

  const ExampleCard({
    super.key,
    required this.title,
    required this.description,
    required this.code,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme
    final codeStyleBase = theme.textTheme.bodyMedium?.copyWith(
          // Use bodyMedium as base for code
          fontFamily: 'RobotoMono',
          fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
          fontSize: 12,
        ) ??
        const TextStyle(
          // Fallback if bodyMedium is null
          fontFamily: 'RobotoMono',
          fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
          fontSize: 12,
        );

    return Card(
      // Use default Card theme for elevation/shape
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge, // Use theme style
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium, // Use theme style
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align top
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Use theme color for code background
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code.trim(), // Trim code block whitespace
                      // Apply base code style, color will come from theme
                      style: codeStyleBase.copyWith(
                        color: theme.colorScheme.onSurfaceVariant, // Explicit text color
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 4.0), // Adjust padding
                  child: IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18), // Slightly smaller icon
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Result container
            Container(
              width: double.infinity, // Ensure it takes full width
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Use a slightly different theme color for result background
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                // Optional: Add a subtle border
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              // Apply default text style from theme to the child content
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium ?? const TextStyle(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
