# textf Example

Drop-in replacement for Flutter's `Text` widget with inline Markdown-like formatting.

##

## Quick Start

```dart
import 'package:textf/textf.dart';

Textf(
  '**Bold**, *italic*, `code`, and [links](https://flutter.dev)',
  style: TextStyle(fontSize: 16),
)
```

## Formatting

| Format        | Syntax          |
| ------------- | --------------- |
| Bold          | `**bold**`      |
| Italic        | `*italic*`      |
| Bold + Italic | `***both***`    |
| Strikethrough | `~~strike~~`    |
| Underline     | `++underline++` |
| Highlight     | `==highlight==` |
| Inline code   | `` `code` ``    |
| Superscript   | `^super^`       |
| Subscript     | `~sub~`         |
| Link          | `[label](url)`  |

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

### Links with Callbacks

```dart
TextfOptions(
  onLinkTap: (url, displayText) => launchUrl(Uri.parse(url)),
  linkStyle: TextStyle(color: Colors.blue),
  child: Textf('[Tap me](https://example.com)'),
)
```

### Custom Styles

```dart
TextfOptions(
  boldStyle: TextStyle(fontWeight: FontWeight.w900),
  codeStyle: TextStyle(fontFamily: 'monospace'),
  highlightStyle: TextStyle(backgroundColor: Colors.yellow),
  child: Textf('Style **everything** your way'),
)
```

### Widget Placeholders

```dart
Textf(
  'Rate this app {star}',
  placeholders: {
    'star': WidgetSpan(child: Icon(Icons.star, color: Colors.amber)),
  },
)
```

### Live Formatting in Text Fields

```dart
final controller = TextfEditingController();

TextField(
  controller: controller,
  decoration: InputDecoration(hintText: 'Try **bold** or *italic*'),
)
```

## Features

✓ **Zero dependencies** — pure Dart
✓ **Max 2-level nesting** — safe and predictable
✓ **Escape with backslash** — `\*not italic\*`
✓ **Fully customizable** — styles and callbacks via TextfOptions
✓ **Efficient** — LRU caching and single-pass tokenization

See [pub.dev](https://pub.dev/packages/textf) for full documentation.
