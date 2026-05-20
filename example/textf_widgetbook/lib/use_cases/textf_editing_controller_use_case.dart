// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Live Editing',
  type: TextfEditingController,
)
Widget textfEditingControllerUseCase(BuildContext context) {
  final markerVisibility = context.knobs.object.dropdown<MarkerVisibility>(
    label: 'Marker Visibility',
    options: MarkerVisibility.values,
    initialOption: MarkerVisibility.always,
    labelBuilder: (v) => v.name,
  );

  final showCustomStyles = context.knobs.boolean(
    label: 'Custom TextfOptions styles',
    description: 'Wrap the field in TextfOptions with custom colors',
  );

  final showPlainText = context.knobs.boolean(
    label: 'Show plain text preview',
    initialValue: true,
    description: 'Displays the plain text (markers stripped) below the field',
  );

  return TextfEditingControllerUseCase(
    markerVisibility: markerVisibility,
    showCustomStyles: showCustomStyles,
    showPlainText: showPlainText,
  );
}

/// Demo widget for the [TextfEditingController] use case.
class TextfEditingControllerUseCase extends StatefulWidget {
  const TextfEditingControllerUseCase({
    required this.markerVisibility,
    required this.showCustomStyles,
    required this.showPlainText,
    super.key,
  });

  final MarkerVisibility markerVisibility;
  final bool showCustomStyles;
  final bool showPlainText;

  @override
  State<TextfEditingControllerUseCase> createState() => _TextfEditingControllerUseCaseState();
}

class _TextfEditingControllerUseCaseState extends State<TextfEditingControllerUseCase> {
  final TextfEditingController _controller = TextfEditingController(
    text: _initialText,
  );
  String _plainText = '';

  static const _initialText =
      '**Bold**, *italic*, ~~strike~~, `code`, ++underline++, ==highlight==\n'
      'Links: [Flutter](https://flutter.dev)\n'
      'Combined: ***bold italic***, **bold _nested_**';

  @override
  void initState() {
    super.initState();
    _controller
      ..markerVisibility = widget.markerVisibility
      ..addListener(_onTextChanged);
    _plainText = _controller.plainText;
  }

  @override
  void didUpdateWidget(TextfEditingControllerUseCase old) {
    super.didUpdateWidget(old);
    if (old.markerVisibility != widget.markerVisibility) {
      _controller.markerVisibility = widget.markerVisibility;
    }
  }

  void _onTextChanged() {
    final plain = _controller.plainText;
    if (plain != _plainText) {
      setState(() => _plainText = plain);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget field = TextField(
      controller: _controller,
      maxLines: null,
      minLines: 4,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Type **bold**, *italic*, `code`, [link](url)…',
        alignLabelWithHint: true,
      ),
    );

    if (widget.showCustomStyles) {
      field = TextfOptions(
        boldStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        italicStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.secondary,
        ),
        codeStyle: TextStyle(
          fontFamily: 'monospace',
          color: theme.colorScheme.tertiary,
          backgroundColor: theme.colorScheme.tertiaryContainer,
        ),
        linkStyle: TextStyle(
          color: theme.colorScheme.error,
          decoration: TextDecoration.underline,
        ),
        child: field,
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader('TextField with TextfEditingController'),
            const SizedBox(height: 8),
            _FormattingCheatSheet(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: field,
              ),
            ),
            if (widget.showPlainText) ...[
              const SizedBox(height: 16),
              const _SectionHeader('Plain text (markers stripped)'),
              const SizedBox(height: 8),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _plainText.isEmpty ? '(empty)' : _plainText,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: _plainText.isEmpty ? FontStyle.italic : FontStyle.normal,
                      color: _plainText.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _FormattingCheatSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('**bold**', 'Bold'),
      ('*italic*', 'Italic'),
      ('~~strike~~', 'Strikethrough'),
      ('`code`', 'Code'),
      ('++underline++', 'Underline'),
      ('==highlight==', 'Highlight'),
      ('^super^', 'Superscript'),
      ('~sub~', 'Subscript'),
      ('[text](url)', 'Link'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final (syntax, label) in items)
          Chip(
            label: Text(
              '$syntax → $label',
              style: const TextStyle(fontSize: 11),
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
