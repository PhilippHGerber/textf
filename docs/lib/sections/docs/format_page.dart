import 'package:flutter/material.dart';

import '/sections/formats/advanced_formatting_tab.dart';
import '/sections/formats/basic_formatting_tab.dart';
import '/sections/links_widgets/links_tab.dart';
import '/widgets/docs_pager.dart';
import '../../router/docs_routes.dart';

/// Formatting reference page — Basic, Advanced, and Links stacked as sections.
class FormatPage extends StatelessWidget {
  const FormatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionDivider(label: 'Basic Formatting', theme: theme, cs: cs),
              const BasicFormattingTab(),
              _SectionDivider(label: 'Advanced Formatting', theme: theme, cs: cs),
              const AdvancedFormattingTab(),
              _SectionDivider(label: 'Links', theme: theme, cs: cs),
              const LinksTab(),
              const SizedBox(height: 48),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: DocsPager(current: DocsRoutes.formatting),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.label,
    required this.theme,
    required this.cs,
  });

  final String label;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
