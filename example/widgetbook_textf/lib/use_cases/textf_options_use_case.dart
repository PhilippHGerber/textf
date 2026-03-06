import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'TextfOptions Customization',
  type: Textf,
)
Widget textfOptionsUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: 'Formatted Text',
    initialValue:
        'This is **bold**, *italic*, ~~strikethrough~~, `code`, and [link](https://example.com).',
    description: 'Enter text with Markdown-like formatting',
    maxLines: 5,
  );

  // Bold style options
  final boldColor = context.knobs.color(
    label: 'Bold Color',
    initialValue: Colors.red,
  );

  final boldWeight = context.knobs.object.dropdown(
    label: 'Bold Weight',
    options: [
      (label: 'Normal', value: FontWeight.normal),
      (label: 'Bold', value: FontWeight.bold),
      (label: 'W900', value: FontWeight.w900),
    ],
    labelBuilder: (value) => value.toString().split('.').last,
    initialOption: (label: 'W900', value: FontWeight.w900),
  );

  // Italic style options
  final italicColor = context.knobs.color(
    label: 'Italic Color',
    initialValue: Colors.blue,
  );

  final italicBackgroundColor = context.knobs.color(
    label: 'Italic Background',
    initialValue: Colors.yellow.withValues(alpha: .3),
  );

  // Strikethrough style options
  final strikethroughColor = context.knobs.color(
    label: 'Strikethrough Color',
    initialValue: Colors.orange,
  );

  final strikethroughThickness = context.knobs.double.slider(
    label: 'Strikethrough Thickness',
    initialValue: 2.0,
    min: 0.5,
    max: 5.0,
  );

  // Code style options
  final codeBackgroundColor = context.knobs.color(
    label: 'Code Background',
    initialValue: Colors.grey.shade200,
  );

  final codeTextColor = context.knobs.color(
    label: 'Code Text Color',
    initialValue: Colors.purple,
  );

  // Link style options
  final linkColor = context.knobs.color(
    label: 'Link Color',
    initialValue: Colors.green,
  );

  final linkDecoration = context.knobs.object.dropdown(
    label: 'Link Decoration',
    options: [
      (label: 'None', value: TextDecoration.none),
      (label: 'Underline', value: TextDecoration.underline),
      (label: 'Overline', value: TextDecoration.overline),
      (label: 'Line Through', value: TextDecoration.lineThrough),
    ],
    labelBuilder: (value) => value.toString().split('.').last,
    initialOption: (label: 'Underline', value: TextDecoration.underline),
  );

  final linkHoverColor = context.knobs.color(
    label: 'Link Hover Color',
    initialValue: Colors.blue,
  );

  final linkMouseCursor = context.knobs.object.dropdown(
    label: 'Link Mouse Cursor',
    options: [
      (label: 'Click', value: SystemMouseCursors.click),
      (label: 'Basic', value: SystemMouseCursors.basic),
      (label: 'Text', value: SystemMouseCursors.text),
      (label: 'Forbidden', value: SystemMouseCursors.forbidden),
      (label: 'Help', value: SystemMouseCursors.help),
    ],
    labelBuilder: (value) => value.toString().split('.').last,
    initialOption: (label: 'Click', value: SystemMouseCursors.click),
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TextfOptions Customization:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextfOptions(
                boldStyle: TextStyle(
                  fontWeight: boldWeight.value,
                  color: boldColor,
                ),
                italicStyle: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: italicColor,
                  backgroundColor: italicBackgroundColor,
                ),
                strikethroughStyle: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: strikethroughColor,
                  decorationThickness: strikethroughThickness,
                ),
                codeStyle: TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: codeBackgroundColor,
                  color: codeTextColor,
                ),
                linkStyle: TextStyle(
                  color: linkColor,
                  decoration: linkDecoration.value,
                ),
                linkHoverStyle: TextStyle(
                  color: linkHoverColor,
                  fontWeight: FontWeight.bold,
                ),
                linkMouseCursor: linkMouseCursor.value,
                onLinkTap: (url, displayText) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tapped: $url'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onLinkHover: (url, displayText, {required isHovering}) {
                  if (isHovering) {
                    debugPrint('Hovering: $url');
                  }
                },
                child: Textf(
                  text,
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
