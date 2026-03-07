// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'RTL Support',
  type: Textf,
)
Widget rtlUseCase(BuildContext context) {
  // Arabic text with formatting
  const arabicText = 'هذا نص **عريض** و*مائل* و~~مشطوب~~ و`رمز` مع [رابط](https://example.com).';

  // English text with formatting
  const englishText =
      'This is **bold** and *italic* and ~~strikethrough~~ and `code` with [link](https://example.com).';

  final textDirection = context.knobs.object.dropdown(
    label: 'Text Direction',
    options: [
      (label: 'LTR', value: TextDirection.ltr),
      (label: 'RTL', value: TextDirection.rtl),
    ],
    labelBuilder: (value) => value.label,
    initialOption: (label: 'RTL', value: TextDirection.rtl),
  );

  final useArabicText = context.knobs.boolean(
    label: 'Use Arabic Text',
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
                'RTL Support Test:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Textf(
                  useArabicText ? arabicText : englishText,
                  textDirection: textDirection.value,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
