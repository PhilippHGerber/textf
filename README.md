# Text*f*

[![pub package](https://img.shields.io/pub/v/textf.svg)](https://pub.dev/packages/textf) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter widget for inline text formatting — fully compatible with Flutter’s `Text` widget.
Easily replace `Text` with `Textf` to add simple formatting:

```dart
Textf('Hello **Flutter**. Build for ==any screen== !');
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/textf.png)

> **⚠️ Important:**
> Textf is designed for inline styling only and is not a full Markdown renderer. It doesn't support block elements like lists, headings, or images.

## Overview

Textf provides basic text formatting capabilities similar to a subset of Markdown, focusing exclusively on inline styles. It's designed for situations where you need simple text formatting without the overhead of a full Markdown rendering solution.

### About the Name

The name "Textf" is inspired by the C standard library function `printf` (print formatted), which formats text and writes it to standard output. Similarly, `Textf` (Text formatted) provides simple, efficient text formatting for Flutter applications.

### Why Text*f*?

* **Lightweight** – Significantly smaller and faster than full Markdown packages
* **Performance-focused** – Optimized linear O(N) parsing loop and memory efficiency
* **Flutter-native** – Uses the familiar Text API for seamless integration
* **Zero dependencies** – No external packages required
* **Interactive links** – Built-in link support with customizable styles and hover effects
* **Widget Interpolation** – Insert any widget into text using named placeholders

Perfect for chat applications, comment sections, UI elements, and any scenario where simple inline formatting is all you need.

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

## Requirements

* Flutter: >=3.0.0

## Getting Started

Import the package and use it like a regular Text widget:

```dart
import 'package:textf/textf.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Textf(
      'Hello **bold** *italic* ~~strikethrough~~ '
      'Code: `this is code` '
      '++underline++ ==highlight=='
      '^super^ ~sub~ '
      '[link](https://flutter.dev)',
      style: TextStyle(fontSize: 16),
    );
  }
}
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/example.png)

## Supported Formatting

Textf supports the following inline formatting syntax, similar to a subset of Markdown:

| Format        | Syntax                       | Result                              |
| ------------- | ---------------------------- | ----------------------------------- |
| Bold          | `**bold**` or `__bold__`     | **bold**                            |
| Italic        | `*italic*` or `_italic_`     | *italic*                            |
| Bold+Italic   | `***both***` or `___both___` | ***both***                          |
| Strikethrough | `~~strikethrough~~`          | ~~strikethrough~~                   |
| Underline     | `++underline++`              | ++underline++                       |
| Highlight     | `==highlight==`              | ==highlight==                       |
| Code          | `` `code` ``                 | `code`                              |
| Link          | `[text](url)`                | [Example Link](https://example.com) |
| Superscript   | `^superscript^`              | ^superscript^                       |
| Subscript     | `~subscript~`                | ~subscript~                         |
| Placeholder   | `{key}`                      | Inserted Widgets/Spans              |

---

### Widget Placeholders

You can insert any `InlineSpan` (such as a `WidgetSpan` or `TextSpan`) into your text using named placeholders `{key}`. This acts like string interpolation but for UI components.

```dart
Textf(
  'Built with {flutter} and {dart}. Made with {love}.',
  placeholders: {
    'flutter': WidgetSpan(child: Image.asset('flutter.png')),
    'dart':    WidgetSpan(child: Image.asset('dart.png')),
    'love':    WidgetSpan(child: Icon(Icons.favorite, color: Colors.red)),
  },
)
```

* **Syntax:** Use curly braces with an alphanumeric key: `{icon}`, `{my_image}`, `{step1}`.
* **Safety:** If a key is missing from the `placeholders` map, the literal text (e.g., `"{missing}"`) is displayed instead of crashing.
* **Nesting:** Placeholders work inside formatting (e.g., `**{icon}**`) and inside links (e.g., `[Click {icon}](url)`).
* **Escaping:** To display a literal `{key}`, escape the opening brace: `\{key}`.

> **⚠️ Important:**
> For optimal performance with placeholders, **define your InlineSpans as const or final variables outside the build method** to ensure cache hits.
---

### Links `[text](url)`

![image](https://github.com/PhilippHGerber/textf/raw/main/images/link-hover.gif)

* **Syntax:** Enclose the display text in square brackets `[]` and the URL in parentheses `()`.
* **Rendering:** Links are rendered with a distinct style (usually blue and underlined) that can be customized via `TextfOptions`.
* **Interaction:**
  * `Textf` renders links as tappable/clickable elements.
  * To handle taps (e.g., open the URL) or hovers, wrap your `Textf` widget (or a parent widget containing multiple `Textf` widgets) with `TextfOptions` and provide the `onLinkTap` and/or `onLinkHover` callbacks.
  * `TextfOptions` also allows custom styling for links (`linkStyle`, `linkHoverStyle`) and mouse cursor (`linkMouseCursor`).
* **Protocols:** URLs are automatically normalized. If you provide `[Google](google.com)`, Textf treats it as `https://google.com`. Specialized schemes like `mailto:`, `tel:`, and `https:` are respected and preserved.
* **Nested Formatting:** The display text within the square brackets `[ ]` can contain other formatting markers (e.g., `[**bold link**](https://example.com)`).

```dart
// Example using TextfOptions for link interaction and styling
TextfOptions(
  // Optional: Customize link styles globally for descendants
  linkStyle: TextStyle(color: Colors.green),
  linkHoverStyle: TextStyle(fontWeight: FontWeight.bold),
  onLinkTap: (url, rawDisplayText) {
    // Implement URL launching logic (e.g., using url_launcher package)
    print('Tapped URL: $url (Display Text: $rawDisplayText)');
  },
  onLinkHover: (url, rawDisplayText, isHovering) {
    // Handle hover effects (e.g., change cursor, update UI state)
    print('Hovering over $url: $isHovering');
  },
  child: Textf(
    'Visit [**Flutter website**](https://flutter.dev) or [this link](https://example.com).',
    style: TextStyle(fontSize: 16),
  ),
)
```

### Nesting Formatting

When nesting formatting, use different marker types (asterisks vs underscores) to ensure proper parsing:

| Format            | Correct                  | Incorrect                |
| ----------------- | ------------------------ | ------------------------ |
| Nested formatting | `**Bold with _italic_**` | `**Bold with *italic***` |

Using the same marker type for nested formatting may result in unexpected rendering.

## Customizing with TextfOptions

The `TextfOptions` widget allows you to customize the appearance and behavior of formatted text throughout your app. It uses the InheritedWidget pattern to make configuration available to all descendant `Textf` widgets.

When resolving styles or callbacks, Textf searches up the widget tree for the nearest `TextfOptions` ancestor that defines the specific property. If no ancestor defines it, theme-based defaults (for code/links) or package defaults (for bold, italic, strikethrough) are used.

### Basic Usage

```dart

TextfOptions(
  // Styling options (merged onto the base style)
  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
  italicStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
  codeStyle: TextStyle(fontFamily: 'RobotoMono', backgroundColor: Colors.grey.shade200),

  // Link options
  linkStyle: TextStyle(color: Colors.green),
  linkHoverStyle: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
  linkMouseCursor: SystemMouseCursors.click,

  // Link callbacks
  onLinkTap: (url, displayText) {
    print('Tapped URL: $url (Display Text: $displayText)');
  },
  onLinkHover: (url, displayText, isHovering) {
    print('Hover state changed for $url: $isHovering');
  },

  child: Textf(
    'This text has **bold**, *italic*, and [links](https://example.com).',
    style: TextStyle(fontSize: 16),
  ),
)
```

**Available `TextfOptions` Properties:**

* **`linkStyle`**: `TextStyle?` for link text (`[text](url)`) in its normal (non-hovered) state.
* **`linkHoverStyle`**: `TextStyle?` for link text when hovered. Merged on top of `linkStyle`.
* **`linkMouseCursor`**: `MouseCursor?` The cursor to display when hovering over links.
* **`onLinkTap`**: Callback `Function(String url, String rawDisplayText)?` triggered when a link is tapped.
* **`onLinkHover`**: Callback `Function(String url, String rawDisplayText, bool isHovering)?` triggered on mouse enter/exit.
* **`boldStyle`**: `TextStyle?` for bold text (`**bold**`).
* **`italicStyle`**: `TextStyle?` for italic text (`*italic*`).
* **`boldItalicStyle`**: `TextStyle?` for bold and italic text (`***both***`).
* **`strikethroughStyle`**: `TextStyle?` for strikethrough text (`~~strike~~`).
* **`strikethroughThickness`**: `double?` Specifies the thickness of the strikethrough line (used if `strikethroughStyle` is null).
* **`underlineStyle`**: `TextStyle?` for underlined text (`++underline++`).
* **`highlightStyle`**: `TextStyle?` for highlighted text (`==highlight==`).
* **`codeStyle`**: `TextStyle?` for inline code text (`` `code` ``).
* **`superscriptStyle`**: `TextStyle?` for superscript text (`^text^`).
* **`subscriptStyle`**: `TextStyle?` for subscript text (`~text~`).

### Inheritance

When multiple `TextfOptions` are nested in the widget tree, options are inherited through the hierarchy. Styles are **merged** downwards. For example, if a parent `TextfOptions` defines a red color for bold text, and a child `TextfOptions` defines a specific font weight for bold text, the resulting text will be **both** red and have the specific font weight.

## Accessibility

Textf is built to respect Flutter's accessibility standards:

1. **Text Scaling:** The widget fully respects the system's `TextScaler` settings (Dynamic Type on iOS / Display Size on Android).
2. **Screen Readers:** Interactive links are wrapped in `Semantics` widgets to ensure they are correctly announced as links by TalkBack and VoiceOver.

## Performance

Textf is designed with performance in mind:

* **Linear O(N) Parsing:** The single-pass parsing loop ensures performance scales linearly with text length, avoiding exponential complexity even with nested styles.
* **Fast Paths:** Quick handling of plain text without formatting.
* **Memory Efficient:** Minimal memory overhead by avoiding unnecessary object allocations during tokenization.

Performance benchmarks show Textf maintains smooth rendering (60+ FPS) even with frequent updates and complex formatting.

## Limitations

* **Text Selection & Links:** Interactive links (`[text](url)`) are rendered as `WidgetSpan` elements to enable hover effects and custom cursors. Consequently, **native text selection does not span across interactive links**. You cannot drag-select text that starts before a link and ends after it.
* **Nesting Depth:** Maximum nesting depth of 2 formatting levels (e.g., `**bold _italic_**` is supported, deeper nesting is treated as plain text).
* **Block Elements:** No support for block elements (headings, lists, quotes) or images.

## Roadmap & Features

* ✅ Bold, Italic, Bold+Italic
* ✅ Strikethrough, Underline, Highlight
* ✅ Inline Code, Superscript, Subscript
* ✅ Link support with `[text](url)` and auto-normalization
* ✅ Nested formatting (up to 2 levels)
* ✅ Interactive styling with `TextfOptions`
* ✅ RTL language support
* ✅ Theme-aware defaults
* ✅ Widget Placeholders `{key}`

## When to Use Text*f*

* ✅ When you need simple inline text formatting
* ✅ When performance is critical
* ✅ When you want a familiar Flutter Text-like API
* ✅ For chat messages, comments, captions, or UI labels
* ✅ For internationalized text with formatting
* ❌ When you need full Markdown with blocks, lists, headers
* ❌ When you need HTML rendering
* ❌ For complex document rendering requiring text selection across links

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
