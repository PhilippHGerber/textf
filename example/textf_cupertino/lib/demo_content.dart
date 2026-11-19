import 'package:flutter/widgets.dart';

// Demo content for the `cupertino_ui` app (`main.dart`). It uses only the widgets layer.

/// Key of the demo `Textf`.
const Key demoTextfKey = ValueKey<String>('demo-textf');

/// Opacity applied to the resolved `systemYellow` for `TextfOptions.highlightColor`, so
/// highlighted text stays readable in light and dark mode.
const double highlightAlpha = 0.35;

/// Markdown rendered by the app: every construct the recipe colors, plus a heading.
const String demoMarkdown = '''
## Textf on Cupertino
**Bold**, *italic*, ~~strike~~, ++underline++ and x^2^ need no setup.
Brand colors come from one builder: a link [a link](https://pub.dev/packages/textf), some `inline code` and ==a highlight==.
---
The rule above uses the separator color.''';
