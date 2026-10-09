# textf Example

Drop-in replacements for Flutter's `Text` and `TextEditingController` with inline Markdown-like formatting.

Textf is design-system neutral: it builds on Flutter's `widgets` layer only, so the same code works under Material, `material_ui`, Cupertino, `cupertino_ui`, a custom design system or a bare `WidgetsApp`.

## Quick Start

```dart
import 'package:flutter/widgets.dart';
import 'package:textf/textf.dart';

Textf(
  '# Release notes\n'
  '**Bold**, *italic*, `code`, and [links](https://flutter.dev)\n'
  '---\n'
  'Water is H~2~O and E = mc^2^.',
  style: TextStyle(fontSize: 16),
)
```

## Formatting

| Format         | Syntax                 |
| -------------- | ---------------------- |
| Bold           | `**bold**`             |
| Italic         | `*italic*`             |
| Bold + Italic  | `***both***`           |
| Strikethrough  | `~~strike~~`           |
| Underline      | `++underline++`        |
| Highlight      | `==highlight==`        |
| Inline code    | `` `code` ``           |
| Superscript    | `^super^`              |
| Subscript      | `~sub~`                |
| Link           | `[label](url)`         |
| Heading        | `# H1` to `###### H6`  |
| Thematic break | `---`, `***`, or `___` |

**Note:** No spaces around markers — `*italic*` works, `* italic *` doesn't.

## Examples

### Basic Usage

```dart
Textf('Hello **World**!')
```

### String Extension

```dart
'**Bold** text'.textf(style: TextStyle(fontSize: 18))
```

### Headings

One to six `#` at the start of a line, followed by a space. Inline formatting works inside a heading, and the style ends with the line.

```dart
Textf(
  '# Heading 1\n'
  '## Heading with **bold** and *italic*\n'
  'Body text again. C# and #hashtags stay plain text.',
  '#hashtag on its own line is not a heading.',
)
```

Heading styles merge onto the built-in size and weight, so a color alone keeps the heading size:

```dart
TextfOptions(
  h1Style: TextStyle(color: Color(0xFF4527A0)),
  h2Style: TextStyle(fontSize: 22),
  child: Textf('# Custom H1\n## Custom H2'),
)
```

### Thematic Breaks

A line of three or more `-`, `*` or `_` renders as a full-width rule.

```dart
Textf('Above\n---\nBelow')
```

Tint the default rule with `thematicBreakColor`, or replace it with any widget:

```dart
TextfOptions(
  thematicBreakBuilder: (context) => Container(
    height: 2,
    color: Color(0xFF00796B),
  ),
  child: Textf('Above\n---\nBelow'),
)
```

### Links with Callbacks

```dart
TextfOptions(
  onLinkTap: (url, displayText) => launchUrl(Uri.parse(url)),
  linkColor: Color(0xFF00796B), // keeps the default underline
  child: Textf('[Tap me](https://example.com)'),
)
```

### Colors

Built-in colors derive from the surrounding text, not from a theme. Color options tint a default and keep its typography, such as the link underline or the monospace code font:

```dart
TextfOptions(
  linkColor: Color(0xFF00796B),
  codeBackgroundColor: Color(0x1A00796B),
  highlightColor: Color(0x66FFD54F),
  thematicBreakColor: Color(0x33000000),
  child: Textf('A [link](https://example.com), `code` and a ==highlight==.'),
)
```

### Using Your App's Theme Colors

Read your theme once in the app's `builder` and pass its colors down. Every `Textf` then follows scheme and light/dark changes.

**Material**, with `material_ui` or SDK Material:

```dart
import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';

MaterialApp(
  builder: (context, child) {
    final theme = Theme.of(context);
    return TextfOptions(
      linkColor: theme.colorScheme.primary,
      codeBackgroundColor: theme.colorScheme.surfaceContainer,
      thematicBreakColor: theme.dividerColor,
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: const HomeScreen(),
)
```

Import `Theme` from the library your app is built on. `material_ui` and SDK Material define different `Theme` classes, and a lookup through the wrong one returns the fallback theme.

**Cupertino**, with `cupertino_ui` or SDK Cupertino:

```dart
import 'package:cupertino_ui/cupertino_ui.dart'; 
import 'package:textf/textf.dart';

CupertinoApp(
  builder: (context, child) {
    return TextfOptions(
      linkColor: CupertinoTheme.of(context).primaryColor,
      codeBackgroundColor: CupertinoColors.tertiarySystemFill.resolveFrom(context),
      thematicBreakColor: CupertinoColors.separator.resolveFrom(context),
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: const HomePage(),
)
```

### Custom Styles

A style option replaces the built-in style for its marker.

```dart
TextfOptions(
  boldStyle: TextStyle(fontWeight: FontWeight.w900),
  codeStyle: TextStyle(fontFamily: 'monospace'),
  highlightStyle: TextStyle(backgroundColor: Color(0xFFFFEB3B)),
  child: Textf('Style **everything** your way'),
)
```

### Widget Placeholders

```dart
Textf(
  'Built with {logo} Flutter',
  placeholders: {
    'logo': WidgetSpan(
      child: Image.asset('assets/flutter.png', width: 18, height: 18),
    ),
  },
)
```

### Live Formatting in Text Fields

`TextfEditingController` works with any text field that takes a `TextEditingController`, such as Material's `TextField` or `CupertinoTextField`.

```dart
final controller = TextfEditingController();

TextField(controller: controller)
```

For headings in an editable field, disable forced strut height so larger lines can own their line height:

```dart
TextField(
  controller: controller,
  style: style,
  strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: false),
)
```

## Features

✓ **Zero dependencies** — pure Dart

✓ **Design-system neutral** — no Material or Cupertino import

✓ **Max 2-level nesting** — safe and predictable

✓ **Escape with backslash** — `\*not italic\*`

✓ **Fully customizable** — styles, colors and callbacks via TextfOptions

✓ **Efficient** — LRU caching and single-pass tokenization

## Runnable Example Apps

The [repository](https://github.com/PhilippHGerber/textf/tree/main/example) holds full apps:

- [`basic`](https://github.com/PhilippHGerber/textf/tree/main/example/basic): every feature in one file, as a code reference
- [`advanced`](https://github.com/PhilippHGerber/textf/tree/main/example/advanced): chat, notifications, links, placeholders and the editing controller
- [`textf_flex`](https://github.com/PhilippHGerber/textf/tree/main/example/textf_flex): `material_ui` with `flex_color_scheme`
- [`textf_cupertino`](https://github.com/PhilippHGerber/textf/tree/main/example/textf_cupertino): `cupertino_ui` and SDK Cupertino
- [`textf_bare`](https://github.com/PhilippHGerber/textf/tree/main/example/textf_bare): a bare `WidgetsApp`

See [pub.dev](https://pub.dev/packages/textf) for full documentation.
