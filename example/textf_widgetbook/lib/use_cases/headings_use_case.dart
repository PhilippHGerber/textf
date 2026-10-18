// ignore_for_file: no-magic-number

import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Headings',
  type: Textf,
)
Widget headingsUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: 'Formatted Text',
    initialValue:
        '# Heading 1\n'
        '## Heading 2 with **bold**\n'
        '### Heading 3 with `code`\n'
        '#### Heading 4\n'
        '##### Heading 5\n'
        '###### Heading 6\n'
        'Body text after the headings.\n'
        '####### Seven hashes stay plain text',
    description: 'ATX headings: one to six # followed by a space',
    maxLines: 10,
  );

  final useCustomStyles = context.knobs.boolean(
    label: 'Custom h1Style–h6Style',
    description: 'Override the built-in per-level heading styles via TextfOptions',
  );

  final headingColor = context.knobs.color(
    label: 'Heading Color (custom styles)',
    initialValue: Colors.deepPurple,
  );

  Widget child = Textf(
    text,
    style: const TextStyle(fontSize: 16),
  );

  if (useCustomStyles) {
    child = TextfOptions(
      h1Style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: headingColor),
      h2Style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: headingColor),
      h3Style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: headingColor),
      h4Style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: headingColor),
      h5Style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: headingColor),
      h6Style: TextStyle(
        fontSize: 16,
        letterSpacing: 1.5,
        color: headingColor.withValues(alpha: 0.7),
      ),
      child: child,
    );
  }

  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}
