// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/widgets/docs_pager.dart';
import '/widgets/section_header.dart';
import '../../router/docs_routes.dart';

/// Quickstart documentation page — up and running in 3 steps.
class QuickstartPage extends StatelessWidget {
  const QuickstartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Quickstart',
                subtitle: 'Up and running in 3 steps',
              ),
              SizedBox(height: 32),
              _Step(
                number: '1',
                title: 'Add the dependency',
                description: 'Run the following command in your project directory:',
                code: 'flutter pub add textf',
                language: 'shell',
              ),
              SizedBox(height: 24),
              _Step(
                number: '2',
                title: 'Import the package',
                description: 'Add the import to your Dart file:',
                code: "import 'package:textf/textf.dart';",
                language: 'dart',
              ),
              SizedBox(height: 24),
              _Step(
                number: '3',
                title: 'Use it',
                description:
                    'Replace Text with Textf, or use TextfEditingController in a TextField:',
                code: '''
// Display formatted text
Textf('**Bold**, *italic*, `code` and ==highlight==')

// Live formatting in a text field
TextField(
  controller: TextfEditingController(
    text: '**Hello** *world*',
  ),
)''',
                language: 'dart',
              ),
              SizedBox(height: 48),
              DocsPager(current: DocsRoutes.quickstart),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.description,
    required this.code,
    required this.language,
  });

  final String number;
  final String title;
  final String description;
  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _CodeBlock(code: code),
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: 'Copy',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: code));
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
