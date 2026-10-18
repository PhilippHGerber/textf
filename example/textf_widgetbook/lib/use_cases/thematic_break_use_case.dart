// ignore_for_file: no-magic-number

import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Thematic Breaks',
  type: Textf,
)
Widget thematicBreakUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: 'Formatted Text',
    initialValue:
        'Section one with **bold** text.\n'
        '---\n'
        'Section two with *italic* text.\n'
        '***\n'
        'Section three with `code`.\n'
        '___\n'
        'Two dashes -- stay plain text.',
    description: 'Three or more -, * or _ on a line of their own',
    maxLines: 10,
  );

  final useColor = context.knobs.boolean(
    label: 'Custom thematicBreakColor',
    description: 'Recolor the built-in rule (the default follows the theme)',
  );

  final ruleColor = context.knobs.color(
    label: 'Rule Color',
    initialValue: Colors.teal,
  );

  final useBuilder = context.knobs.boolean(
    label: 'Custom thematicBreakBuilder',
    description: 'Replace the rule with your own widget; takes precedence over the color',
  );

  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextfOptions(
            thematicBreakColor: useColor ? ruleColor : null,
            thematicBreakBuilder: useBuilder ? _dottedBreak : null,
            child: Textf(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _dottedBreak(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      '•   •   •',
      textAlign: TextAlign.center,
      style: TextStyle(letterSpacing: 4),
    ),
  );
}
