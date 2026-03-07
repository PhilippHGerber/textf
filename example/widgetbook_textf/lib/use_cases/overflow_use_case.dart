// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Overflow Handling',
  type: Textf,
)
Widget overflowUseCase(BuildContext context) {
  const longText =
      'This is a **very long text** with multiple formatting styles including *italic*, ~~strikethrough~~, `code blocks`, and even [links](https://example.com) that will definitely overflow the container if not properly handled with wrapping, ellipsis, or other overflow techniques. The purpose of this example is to test how Textf handles long text with various formatting applied to different parts of the text.';

  final containerWidth = context.knobs.double.slider(
    label: 'Container Width',
    initialValue: 300,
    min: 100,
    max: 500,
  );

  final maxLines = context.knobs.int.slider(
    label: 'Max Lines',
    initialValue: 2,
    min: 1,
    max: 10,
  );

  final overflow = context.knobs.object.dropdown(
    label: 'Overflow',
    options: [
      (label: 'Clip', value: TextOverflow.clip),
      (label: 'Ellipsis', value: TextOverflow.ellipsis),
      (label: 'Fade', value: TextOverflow.fade),
      (label: 'Visible', value: TextOverflow.visible),
    ],
    labelBuilder: (value) => value.label,
    initialOption: (label: 'Ellipsis', value: TextOverflow.ellipsis),
  );

  final softWrap = context.knobs.boolean(
    label: 'Soft Wrap',
    initialValue: true,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overflow Handling Test:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Container width: ${containerWidth.toStringAsFixed(0)}px, Max lines: $maxLines',
              ),
              const SizedBox(height: 8),
              Container(
                width: containerWidth,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Textf(
                  longText,
                  style: const TextStyle(fontSize: 16),
                  maxLines: maxLines,
                  overflow: overflow.value,
                  softWrap: softWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
