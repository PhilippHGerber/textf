import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Link Formatting',
  type: Textf,
)
Widget linkFormattingUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: 'Text with Links',
    initialValue:
        'Visit the [Flutter website](https://flutter.dev) or check out [**bold link**](https://dart.dev).',
    description: 'Enter text with links using [text](url) syntax',
  );

  final showUrlTapSnackbar = context.knobs.boolean(
    label: 'Show URL Tap Snackbar',
    initialValue: true,
  );

  final showHoverText = context.knobs.boolean(
    label: 'Show Hover Text',
    initialValue: true,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextfOptions(
            onLinkTap: showUrlTapSnackbar
                ? (url, displayText) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped: $url (Text: $displayText)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            onLinkHover: showHoverText
                ? (url, displayText, {required isHovering}) {
                    if (isHovering) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hovering: $url'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                : null,
            child: Textf(
              text,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    ),
  );
}
