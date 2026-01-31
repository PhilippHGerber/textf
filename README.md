# Text*f*

[![pub package](https://img.shields.io/pub/v/textf.svg?label=pub.dev&labelColor=333940&logo=flutter&color=00589B)](https://pub.dev/packages/textf) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![style: very good analysis](https://img.shields.io/badge/Style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis) [![tests](https://github.com/PhilippHGerber/textf/actions/workflows/package.yaml/badge.svg)](https://github.com/PhilippHGerber/textf/actions/workflows/package.yaml) [![coverage](https://raw.githubusercontent.com/PhilippHGerber/textf/badges/coverage.svg)](https://github.com/PhilippHGerber/textf/actions/workflows/package.yaml)

Markdown-like text styling for inline text — fully compatible with Flutter's `Text` widget.

## What Textf Is

✅ Inline text formatting only
✅ Works like `Text`, but supports inline styles
✅ Ideal for i18n / ARB / JSON localized strings
✅ Zero dependencies, minimal footprint

## From Text to Textf

Replace `Text` with `Textf` to add simple formatting:

```dart
Textf('Hello **Flutter**. Build for ==any screen==!');
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/textf.png)

> **⚠️ Important:**
> Textf is designed for inline styling only and is not a full Markdown renderer. It doesn't support block elements like lists, headings, or images.

## Installation

Add Textf to your `pubspec.yaml`:

```yaml
dependencies:
  textf: ^1.1.0
```

Then run:

```bash
flutter pub get
```

## Getting Started

```dart
import 'package:textf/textf.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Textf(
      'Hello **bold** *italic* ~~strikethrough~~ `code` '
      '++underline++ ==highlight== ^super^ ~sub~ '
      '[Flutter](https://flutter.dev)',
      style: TextStyle(fontSize: 16),
    );
  }
}
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/example.png)

## Supported Formatting

| Format        | Syntax                       | Result                         |
| ------------- | ---------------------------- | ------------------------------ |
| Bold          | `**bold**` or `__bold__`     | **bold**                       |
| Italic        | `*italic*` or `_italic_`     | *italic*                       |
| Bold+Italic   | `***both***` or `___both___` | ***both***                     |
| Strikethrough | `~~strikethrough~~`          | ~~strikethrough~~              |
| Underline     | `++underline++`              | <u>underline</u>               |
| Highlight     | `==highlight==`              | <mark>highlight</mark>         |
| Code          | `` `code` ``                 | `code`                         |
| Link          | `[text](url)`                | [Flutter](https://flutter.dev) |
| Superscript   | `^superscript^`              | E = mc²                        |
| Subscript     | `~subscript~`                | H₂O                            |
| Placeholder   | `{key}`                      | (inserted widget)              |

### Escaping Characters

Use backslash to display literal formatting characters:

```dart
Textf(r'Use \*asterisks\* without formatting');
// Output: Use *asterisks* without formatting

Textf(r'Show a placeholder: \{key}');
// Output: Show a placeholder: {key}
```

Escapable characters: `*`, `_`, `~`, `` ` ``, `[`, `]`, `(`, `)`, `{`, `}`, `\`

---

## 🆕 Widget Placeholders

Insert any `InlineSpan` (such as `WidgetSpan` or `TextSpan`) using named placeholders:

```dart
Textf(
  'Built with {flutter} and {dart}. Made with {love}.',
  placeholders: {
    'flutter': WidgetSpan(child: Image.asset('flutter.png', width: 16)),
    'dart': WidgetSpan(child: Image.asset('dart.png', width: 16)),
    'love': WidgetSpan(child: Icon(Icons.favorite, color: Colors.red, size: 16)),
  },
)
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/placeholders.png)

**Key points:**

- Keys must be alphanumeric or underscores: `{icon}`, `{my_image}`, `{step1}`
- Missing keys render as literal text (e.g., `{missing}`) — no crashes
- Works inside formatting: `**{icon}**` and links: `[Click {icon}](url)`
- Escape with backslash: `\{key}` renders as `{key}`

---

## Customization with TextfOptions

Wrap your widgets with `TextfOptions` to customize formatting styles:

```dart
TextfOptions(
  // Style overrides
  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange),
  italicStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.purple),
  codeStyle: TextStyle(fontFamily: 'JetBrains Mono', backgroundColor: Colors.grey.shade200),

  // Link behavior
  linkStyle: TextStyle(color: Colors.teal, decoration: TextDecoration.none),
  linkHoverStyle: TextStyle(color: Colors.teal, decoration: TextDecoration.underline),
  onLinkTap: (url, displayText) => launchUrl(Uri.parse(url)),
  onLinkHover: (url, displayText, {required isHovering}) => debugPrint('Hover: $isHovering'),

  child: Textf('**Bold** *italic* `code` [link](https://example.com)'),
)
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/textfoptions.png)

### Available Style Options

| Option               | Description                        |
| -------------------- | ---------------------------------- |
| `boldStyle`          | Style for `**bold**` text          |
| `italicStyle`        | Style for `*italic*` text          |
| `boldItalicStyle`    | Style for `***bold italic***` text |
| `strikethroughStyle` | Style for `~~strikethrough~~` text |
| `underlineStyle`     | Style for `++underline++` text     |
| `highlightStyle`     | Style for `==highlight==` text     |
| `codeStyle`          | Style for `` `code` `` text        |
| `superscriptStyle`   | Style for `^super^` text           |
| `subscriptStyle`     | Style for `~sub~` text             |
| `linkStyle`          | Style for links (normal state)     |
| `linkHoverStyle`     | Style for links (hover state)      |

### Link Options

| Option            | Description                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| `onLinkTap`       | Callback when a link is tapped: `(String url, String displayText)`                             |
| `onLinkHover`     | Callback on hover state change: `(String url, String displayText, {required bool isHovering})` |
| `linkMouseCursor` | Mouse cursor for links (default: `SystemMouseCursors.click`)                                   |
| `linkAlignment`   | Vertical alignment of link widgets (default: `PlaceholderAlignment.baseline`)                  |

### Script Options

| Option                      | Description                               | Default |
| --------------------------- | ----------------------------------------- | ------- |
| `scriptFontSizeFactor`      | Font size multiplier for super/subscripts | `0.6`   |
| `superscriptBaselineFactor` | Vertical offset factor for superscripts   | `-0.4`  |
| `subscriptBaselineFactor`   | Vertical offset factor for subscripts     | `0.2`   |

### Inheritance

`TextfOptions` inherits through the widget tree. Styles are **merged** — a parent's color combines with a child's font weight:

```dart
TextfOptions(
  boldStyle: TextStyle(color: Colors.red),  // Parent: red color
  child: TextfOptions(
    boldStyle: TextStyle(fontWeight: FontWeight.w900),  // Child: heavy weight
    child: Textf('**This is red AND heavy**'),
  ),
)
```

---

## SelectionArea Support

Textf works with Flutter's `SelectionArea` for text selection:

```dart
SelectionArea(
  child: Textf('Select **this** text!'),
)
```

**Note:** Due to links being rendered as `WidgetSpan` elements, text selection cannot span across interactive links. This is a Flutter limitation, not a Textf bug.

---

## Performance

Textf is designed for performance:

- **O(N) Linear Parsing** — Single-pass tokenization scales linearly with text length
- **Smart Caching** — Parsed results are cached and reused across rebuilds
- **Intelligent Invalidation** — Cache only clears when text, style, theme, or options actually change
- **Memory Efficient** — LRU cache with configurable limits prevents memory bloat

### Cache Management

For advanced use cases, you can manually clear the global parse cache:

```dart
// Clear all cached parse results
Textf.clearCache();
```

This is rarely needed — the cache automatically manages itself using LRU eviction.

---

## Accessibility

Textf respects Flutter's accessibility standards:

1. **Text Scaling** — Fully respects `MediaQuery.textScalerOf(context)` and system accessibility settings
2. **Screen Readers** — Links are wrapped in `Semantics` widgets with `link: true` for TalkBack/VoiceOver
3. **RTL Support** — Bidirectional text and RTL languages work correctly

---

## Why Text*f*?

| Feature          | Textf               | Full Markdown Packages |
| ---------------- | ------------------- | ---------------------- |
| Bundle size      | Tiny                | Large                  |
| Dependencies     | Zero                | Multiple               |
| Parse complexity | O(N)                | Often O(N²) or worse   |
| API familiarity  | Identical to `Text` | Custom widgets         |
| Block elements   | ❌                  | ✅                     |
| Use case         | Inline formatting   | Document rendering     |

### About the Name

The name "Textf" is inspired by C's `printf` (print formatted). Similarly, `Textf` (Text formatted) provides simple, efficient text formatting for Flutter.

---

## Features

- ✅ Bold, Italic, Bold+Italic
- ✅ Strikethrough, Underline, Highlight
- ✅ Inline Code with theme-aware styling
- ✅ Superscript and Subscript
- ✅ Links with hover effects and callbacks
- ✅ Widget Placeholders via `{key}` syntax
- ✅ Nested formatting (up to 2 levels)
- ✅ Customizable styles via `TextfOptions`
- ✅ Theme-aware defaults
- ✅ RTL language support
- ✅ Smart caching for performance
- ✅ Full `Text` widget API compatibility

---

## Limitations

| Limitation                 | Reason                                                                           |
| -------------------------- | -------------------------------------------------------------------------------- |
| **No block elements**      | Textf is for inline formatting only — no headings, lists, quotes, or images      |
| **Max 2 nesting levels**   | `**bold _italic_**` works, deeper nesting renders as plain text                  |
| **Selection across links** | Links use `WidgetSpan`, so selection can't span across them (Flutter limitation) |

---

## When to Use Text*f*

**✅ Use Textf for:**

- Chat messages and comments
- UI labels and captions
- Internationalized strings with formatting
- Performance-critical text rendering
- Simple inline formatting needs

**❌ Don't use Textf for:**

- Full Markdown documents
- HTML rendering
- Content with headings, lists, or tables
- Documents requiring text selection across links

---

## API Reference

See the full [API documentation on pub.dev](https://pub.dev/documentation/textf/latest/).

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
