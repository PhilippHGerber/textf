import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Nested Formatting',
  type: Textf,
)
Widget nestedFormattingUseCase(BuildContext context) {
  final examples = [
    '**Bold text with _italic_ inside**',
    '*Italic text with __bold__ inside*',
    '**Bold text with ~~strikethrough~~ inside**',
    '*Italic text with `code` inside*',
    '~~Strikethrough with **bold** and *italic* inside~~',
    '[**Bold link** with *italic*](https://example.com)',
  ];

  final selectedExample = context.knobs.object.dropdown(
    label: 'Nested Format Example',
    options: examples.map((e) => (label: e, value: e)).toList(),
    labelBuilder: (value) => value.label,
    initialOption: (label: examples.first, value: examples.first),
  );

  final customText = context.knobs.string(
    label: 'Custom Nested Format',
    description:
        'Enter your own nested formatting example (leave empty to use the selected example)',
  );

  final textToUse = customText.isEmpty ? selectedExample.value : customText;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nested Formatting Example:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  textToUse,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rendered Result:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Textf(
                textToUse,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
