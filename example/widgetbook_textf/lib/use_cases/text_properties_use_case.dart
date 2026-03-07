// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Text Properties',
  type: Textf,
)
Widget textPropertiesUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: 'Formatted Text',
    initialValue:
        'This is **bold**, *italic*, ~~strikethrough~~, and `code` text with [link](https://example.com). '
        '__Lorem ipsum__ dolor sit amet, *consetetur* sadipscing elitr, sed diam nonumy '
        'eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. '
        'At vero eos et ~~saccusam~~ et justo duo dolores et ea rebum. Stet clita kasd gubergren, '
        'no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, '
        'consetetur sadipscing elitr, `sed diam nonumy eirmod tempor` invidunt ut labore et '
        'dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo '
        'dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
    description: 'Enter text with Markdown-like formatting',
    maxLines: 10,
  );

  // Create knobs for all standard Text properties
  final textAlign = context.knobs.object.dropdown(
    label: 'Text Align',
    options: [
      (label: 'Left', value: TextAlign.left),
      (label: 'Center', value: TextAlign.center),
      (label: 'Right', value: TextAlign.right),
      (label: 'Justify', value: TextAlign.justify),
      (label: 'Start', value: TextAlign.start),
      (label: 'End', value: TextAlign.end),
    ],
    labelBuilder: (value) => value.label,
    initialOption: (label: 'Left', value: TextAlign.left),
  );

  final textDirection = context.knobs.object.dropdown(
    label: 'Text Direction',
    options: [
      (label: 'LTR', value: TextDirection.ltr),
      (label: 'RTL', value: TextDirection.rtl),
    ],
    labelBuilder: (value) => value.label,
    initialOption: (label: 'LTR', value: TextDirection.ltr),
  );

  final softWrap = context.knobs.boolean(
    label: 'Soft Wrap',
    initialValue: true,
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

  final maxLines = context.knobs.intOrNull.slider(
    label: 'Max Lines',
    min: 1,
    max: 10,
    initialValue: 3,
    description: 'Set to null for unlimited lines',
  );

  final semanticsLabel = context.knobs.string(
    label: 'Semantics Label',
    description: 'Custom accessibility label',
  );

  final textWidthBasis = context.knobs.object.dropdown(
    label: 'Text Width Basis',
    options: [
      (label: 'Parent', value: TextWidthBasis.parent),
      (label: 'Long Lines', value: TextWidthBasis.longestLine),
    ],
    labelBuilder: (value) => value.label,
    initialOption: (label: 'Parent', value: TextWidthBasis.parent),
  );

  final selectionColor = context.knobs.color(
    label: 'Selection Color',
    initialValue: Colors.blueAccent.withValues(alpha: 0.4),
  );

  final hasTextHeightBehavior = context.knobs.boolean(
    label: 'Use Text Height Behavior',
  );

  return Center(
    child: SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Text Properties Test:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              const SizedBox(height: 8),
              Textf(
                text,
                style: const TextStyle(fontSize: 18),
                textAlign: textAlign.value,
                textDirection: textDirection.value,
                softWrap: softWrap,
                overflow: overflow.value,
                maxLines: maxLines,
                semanticsLabel: semanticsLabel.isEmpty ? null : semanticsLabel,
                textWidthBasis: textWidthBasis.value,
                selectionColor: selectionColor,
                textHeightBehavior: hasTextHeightBehavior
                    ? const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
