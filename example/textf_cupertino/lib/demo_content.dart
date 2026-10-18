import 'package:flutter/widgets.dart';

// Content shared by the `cupertino_ui` app (`main.dart`) and the SDK Cupertino app
// (`sdk_cupertino_textf_app.dart`). It uses only the widgets layer, so both can import it.

/// Key of the demo `Textf` in both apps.
const Key demoTextfKey = ValueKey<String>('demo-textf');

/// Opacity applied to the resolved `systemYellow` for `TextfOptions.highlightColor`, so
/// highlighted text stays readable in light and dark mode.
const double highlightAlpha = 0.35;

/// Markdown rendered by both apps: every construct the recipe colors, plus a heading.
const String demoMarkdown = '''
## Textf on Cupertino
**Bold**, *italic*, ~~strike~~, ++underline++ and x^2^ need no setup.
Brand colors come from one builder: a link [a link](https://pub.dev/packages/textf), some `inline code` and ==a highlight==.
---
The rule above uses the separator color.''';
