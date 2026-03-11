// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '/widgets/code_panel.dart';
import '/widgets/docs_pager.dart';
import '/widgets/section_header.dart';
import '../../router/docs_routes.dart';

/// TextfEditingController documentation page.
class EditingControllerPage extends StatefulWidget {
  const EditingControllerPage({super.key});

  @override
  State<EditingControllerPage> createState() => _EditingControllerPageState();
}

class _EditingControllerPageState extends State<EditingControllerPage> {
  MarkerVisibility _visibility = MarkerVisibility.always;
  late final TextfEditingController _demoController;

  @override
  void initState() {
    super.initState();
    _demoController = TextfEditingController(
      text:
          '**Bold**, *italic*, `code`, and ~~strike~~. \n[Flutter](https://flutter.dev) is ==awesome==!',
    );
  }

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'TextfEditingController',
                subtitle: 'Live formatting in text fields as the user types',
              ),
              const SizedBox(height: 16),
              Textf(
                'A drop-in replacement for `TextEditingController`. Attach it to any `TextField` '
                'or `TextFormField` to render live formatting as the user types. '
                'The underlying text is always plain — the controller adds visual styling on top '
                'without affecting the stored value.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              // Basic usage
              const CodePanel(
                title: 'Basic Usage',
                code:
                    'final controller = TextfEditingController();\n\nTextField(controller: controller)',
              ),
              const SizedBox(height: 12),
              const CodePanel(
                title: 'With initial content',
                code: "TextfEditingController(text: 'Hello **bold**')",
              ),
              const SizedBox(height: 32),

              // MarkerVisibility
              const SectionHeader(
                title: 'Marker Visibility',
                subtitle: 'Control how formatting markers appear during editing',
              ),
              const SizedBox(height: 16),
              _InfoCard(
                theme: theme,
                cs: cs,
                children: [
                  _VisibilityRow(
                    label: 'MarkerVisibility.always',
                    description:
                        'Markers always visible with dimmed styling. Predictable cursor behavior, works well on all platforms.',
                    isDefault: true,
                    theme: theme,
                    cs: cs,
                  ),
                  const SizedBox(height: 12),
                  _VisibilityRow(
                    label: 'MarkerVisibility.whenActive',
                    description:
                        'Markers hide when the cursor leaves the span, giving a clean live-preview effect.',
                    isDefault: false,
                    theme: theme,
                    cs: cs,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Live demo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Live demo', style: theme.textTheme.labelMedium),
                        const Spacer(),
                        SegmentedButton<MarkerVisibility>(
                          segments: const [
                            ButtonSegment(
                              value: MarkerVisibility.always,
                              label: Text('always'),
                            ),
                            ButtonSegment(
                              value: MarkerVisibility.whenActive,
                              label: Text('whenActive'),
                            ),
                          ],
                          selected: {_visibility},
                          onSelectionChanged: (s) => setState(() {
                            _visibility = s.first;
                            _demoController.markerVisibility = s.first;
                          }),
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _demoController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Try **bold**, *italic*, `code`…',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: theme.brightness == Brightness.light
                            ? cs.surface
                            : cs.surfaceContainerLowest,
                        hoverColor: theme.brightness == Brightness.light
                            ? cs.surfaceDim.withValues(alpha: 0.4)
                            : cs.surfaceContainerLow.withValues(alpha: 0.85),
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const CodePanel(
                title: 'Change mode at runtime',
                code: 'controller.markerVisibility = MarkerVisibility.whenActive;',
              ),
              const SizedBox(height: 32),

              // Custom styles
              const SectionHeader(
                title: 'Custom Styles via TextfOptions',
                subtitle:
                    'Wrap any TextField with TextfOptions to override how each format is rendered.',
              ),
              const SizedBox(height: 12),
              _CustomStylesDemo(theme: theme),
              const SizedBox(height: 32),

              // TextFormField integration
              const SectionHeader(
                title: 'TextFormField Integration',
                subtitle: 'Works seamlessly with TextFormField for form validation.',
              ),
              const SizedBox(height: 12),
              const _FormFieldDemo(),
              const SizedBox(height: 32),

              // Side-by-side comparison
              const SectionHeader(
                title: 'Side-by-Side Comparison',
                subtitle:
                    'Type in the field — same text shown as editable (TextfEditingController) and read-only (Textf).',
              ),
              const SizedBox(height: 12),
              const _SideBySideComparison(),
              const SizedBox(height: 32),

              // Large text protection
              const SectionHeader(
                title: 'Large Text Protection',
                subtitle: 'Automatically disables formatting on very long inputs',
              ),
              const SizedBox(height: 12),
              Textf(
                'When text exceeds `maxLiveFormattingLength` characters, formatting is automatically '
                'disabled and the field renders as plain text. This prevents UI freezes on very long inputs.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              const CodePanel(
                code: 'TextfEditingController(maxLiveFormattingLength: 2500) // default: 5000',
              ),
              const SizedBox(height: 32),

              // Custom styles
              const SectionHeader(
                title: 'Custom Styles',
                subtitle: 'Wrap the TextField with TextfOptions to control formatting appearance',
              ),
              const SizedBox(height: 12),
              const CodePanel(
                code: 'TextfOptions(\n'
                    '  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.deepOrange),\n'
                    "  codeStyle: TextStyle(fontFamily: 'monospace', color: Colors.pink),\n"
                    '  child: TextField(\n'
                    '    controller: TextfEditingController(),\n'
                    '  ),\n'
                    ')',
              ),
              const SizedBox(height: 32),

              // Limitations
              const SectionHeader(
                title: 'Limitations',
                subtitle: 'Known constraints of the editing controller',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                theme: theme,
                cs: cs,
                children: [
                  _LimitationRow(
                    label: 'Widget placeholders',
                    description:
                        '{key} renders as literal text — no widget substitution in editable fields.',
                    theme: theme,
                    cs: cs,
                  ),
                  const Divider(height: 24),
                  _LimitationRow(
                    label: 'Links',
                    description:
                        'Display the full [text](url) syntax while editing — styled but not tappable.',
                    theme: theme,
                    cs: cs,
                  ),
                  const Divider(height: 24),
                  _LimitationRow(
                    label: 'Cross-line markers',
                    description:
                        'Markers never pair across newlines — a marker on line 1 cannot format content on line 2.',
                    theme: theme,
                    cs: cs,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const DocsPager(current: DocsRoutes.textField),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children, required this.theme, required this.cs});

  final List<Widget> children;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({
    required this.label,
    required this.description,
    required this.isDefault,
    required this.theme,
    required this.cs,
  });

  final String label;
  final String description;
  final bool isDefault;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'default',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Custom Styles Demo ──────────────────────────────────────────────────────

class _CustomStylesDemo extends StatelessWidget {
  const _CustomStylesDemo({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CodePanel(
          code: 'TextfOptions(\n'
              '  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: primary),\n'
              '  italicStyle: TextStyle(fontStyle: italic, color: tertiary),\n'
              "  codeStyle: TextStyle(fontFamily: 'RobotoMono', color: primary),\n"
              '  highlightStyle: TextStyle(backgroundColor: amber),\n'
              '  child: TextField(controller: TextfEditingController()),\n'
              ')',
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.all(12),
          child: TextfOptions(
            boldStyle: TextStyle(fontWeight: FontWeight.w900, color: cs.primary),
            italicStyle: TextStyle(fontStyle: FontStyle.italic, color: cs.tertiary),
            codeStyle: TextStyle(
              fontFamily: 'RobotoMono',
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.35),
              color: cs.primary,
            ),
            highlightStyle: const TextStyle(backgroundColor: Color(0x55FFD700)),
            child: TextField(
              controller: TextfEditingController(
                text: '**Bold** with *italic* and `code` and ==highlight==',
              ),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Result',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.brightness == Brightness.light
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceContainerLowest,
                hoverColor: theme.brightness == Brightness.light
                    ? theme.colorScheme.surfaceDim.withValues(alpha: 0.4)
                    : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.85),
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

// ── TextFormField Demo ───────────────────────────────────────────────────────

class _FormFieldDemo extends StatefulWidget {
  const _FormFieldDemo();

  @override
  State<_FormFieldDemo> createState() => _FormFieldDemoState();
}

class _FormFieldDemoState extends State<_FormFieldDemo> {
  final _formKey = GlobalKey<FormState>();
  final TextfEditingController _bioController = TextfEditingController(
    text: 'Flutter dev. Building apps with **Dart** and *Flutter* for ==any screen==.',
  );
  bool _submitted = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bioController,
            decoration: InputDecoration(
              labelText: 'Bio',
              helperText: 'Supports **bold**, *italic*, `code`, and more',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.brightness == Brightness.light
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerLowest,
              hoverColor: theme.brightness == Brightness.light
                  ? theme.colorScheme.surfaceDim.withValues(alpha: 0.4)
                  : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.85),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            style: theme.textTheme.bodyLarge,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Bio is required';
              if (value.trim().length < 10) return 'Bio must be at least 10 characters';

              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  setState(() => _submitted = true);
                  if (_formKey.currentState?.validate() ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Form submitted successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
              const SizedBox(width: 12),
              if (_submitted)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _submitted = false;
                      _bioController.text =
                          'Flutter dev. Building apps with **Dart** and *Flutter* for ==any screen==.';
                    });
                    _formKey.currentState?.reset();
                  },
                  child: const Text('Reset'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Side-by-Side Comparison ──────────────────────────────────────────────────

class _SideBySideComparison extends StatefulWidget {
  const _SideBySideComparison();

  @override
  State<_SideBySideComparison> createState() => _SideBySideComparisonState();
}

class _SideBySideComparisonState extends State<_SideBySideComparison> {
  final TextfEditingController _controller = TextfEditingController(
    text: '**Bold**, *italic*, `code`, and ==highlight==',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final editable = TextField(
          controller: _controller,
          maxLines: 3,
          minLines: 3,
          decoration: InputDecoration(
            labelText: 'TextField - Edit to see live formatting',
            // helperText: 'Edit to see live formatting',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: theme.brightness == Brightness.light
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerLowest,
            hoverColor: theme.brightness == Brightness.light
                ? theme.colorScheme.surfaceDim.withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.85),
          ),
          style: theme.textTheme.bodyLarge,
        );

        final readOnly = Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Textf (read-only)',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Textf(_controller.text, style: theme.textTheme.bodyLarge),
            ],
          ),
        );

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: editable),
                const SizedBox(width: 12),
                Expanded(child: readOnly),
              ],
            ),
          );
        }

        return Column(
          children: [
            editable,
            const SizedBox(height: 12),
            readOnly,
          ],
        );
      },
    );
  }
}

// ── Limitation Row ────────────────────────────────────────────────────────────

class _LimitationRow extends StatelessWidget {
  const _LimitationRow({
    required this.label,
    required this.description,
    required this.theme,
    required this.cs,
  });

  final String label;
  final String description;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
