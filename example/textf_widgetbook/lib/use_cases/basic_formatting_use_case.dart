// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Basic Formatting',
  type: Textf,
  designLink: 'https://www.example.com',
)
Widget basicFormattingUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: 'Formatted Text',
    initialValue: 'This is **bold**, *italic*, ~~strikethrough~~, and `code` text.',
    description: 'Enter text with Markdown-like formatting',
    maxLines: 5,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Textf(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    ),
  );
}
