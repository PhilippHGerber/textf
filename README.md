# Textf

A lightweight, high-performance Flutter widget for simple inline text formatting.

## Overview

Textf provides basic text formatting capabilities similar to a subset of Markdown syntax, focusing exclusively on inline styles. It's designed for situations where you need simple text formatting without the overhead of a full Markdown rendering solution.

### About the Name

The name "Textf" is inspired by the C standard library function `printf` (print formatted), which formats text and writes it to standard output. Similarly, Textf (Text formatted) provides simple, efficient text formatting for Flutter applications.

### Why Textf?

- **Lightweight** - Significantly smaller and faster than full Markdown packages
- **Performance-focused** - Optimized for speed and memory efficiency
- **Flutter-friendly** - Familiar API that mirrors Flutter's standard Text widget
- **Minimal dependencies** - No external packages required
- **Link support** - Interactive links with customizable styling and hover effects

Perfect for chat applications, comment sections, UI elements, and any scenario where simple inline formatting is all you need.

## Screenshots

|                 Basic Formatting                 |                 Nested Formatting                  |                  Complex Formatting                  |
| :----------------------------------------------: | :------------------------------------------------: | :--------------------------------------------------: |
| ![Basic Formatting](https://github.com/PhilippHGerber/textf/raw/main/images/basic_formatting.png) | ![Nested Formatting](https://github.com/PhilippHGerber/textf/raw/main/images/nested_formatting.png) | ![Complex Formatting](https://github.com/PhilippHGerber/textf/raw/main/images/complex_formatting.png) |

|             Chat Bubble Example             |             Notification Example              |             Links Example              |
| :-----------------------------------------: | :-------------------------------------------: | :-------------------------------------------: |
| ![Chat Bubble](https://github.com/PhilippHGerber/textf/raw/main/images/chat_bubble.png) | ![Notification](https://github.com/PhilippHGerber/textf/raw/main/images/notification.png) | ![Links](https://github.com/PhilippHGerber/textf/raw/main/images/links.png) |

## Installation

Add Textf to your `pubspec.yaml`:

```yaml
dependencies:
  textf: ^0.2.0
```

Then run:

```bash
flutter pub get
```

## Requirements

- Flutter: >=3.0.0

## Getting Started

Import the package and use it like a regular Text widget:

```dart
import 'package:textf/textf.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Textf(
      'Hello **bold** *italic* ~~strikethrough~~ `code` [link](https://flutter.dev)',
      style: TextStyle(fontSize: 16),
    );
  }
}
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/example.png)

## Supported Formatting

Textf supports the following inline formatting syntax, similar to a subset of Markdown:

| Format        | Syntax                       | Result            |
| ------------- | ---------------------------- | ----------------- |
| Bold          | `**bold**` or `__bold__`     | **bold**          |
| Italic        | `*italic*` or `_italic_`     | *italic*          |
| Bold+Italic   | `***both***` or `___both___` | ***both***        |
| Strikethrough | `~~strikethrough~~`          | ~~strikethrough~~ |
| Code          | `` `code` ``                 | `code`            |
| Link          | `[text](url)`                | [Example Link](https://example.com) |

---

### Links (`[text](url)`)

![image](https://github.com/PhilippHGerber/textf/raw/main/images/link-hover.gif)

- **Syntax:** Enclose the display text in square brackets `[]` and the URL in parentheses `()`.
- **Rendering:** Links are rendered with a distinct style (usually blue and underlined) that can be customized via `TextfOptions`.
- **Interaction:**
  - `Textf` renders links as tappable/clickable elements.
  - To handle taps (e.g., open the URL) or hovers, wrap your `Textf` widget (or a parent widget containing multiple `Textf` widgets) with `TextfOptions` and provide the `onUrlTap` and/or `onUrlHover` callbacks.
  - `TextfOptions` also allows custom styling for links (`urlStyle`, `urlHoverStyle`) and mouse cursor (`urlMouseCursor`).
- **Nested Formatting:** The display text within the square brackets `[ ]` can contain other formatting markers (e.g., `[**bold link**](https://example.com)`).

```dart
// Example using TextfOptions for link interaction and styling
TextfOptions(
  // Optional: Customize link styles globally for descendants
  urlStyle: TextStyle(color: Colors.green),
  urlHoverStyle: TextStyle(fontWeight: FontWeight.bold),
  onUrlTap: (url, rawDisplayText) {
    // Implement URL launching logic (e.g., using url_launcher package)
    print('Tapped URL: $url (Display Text: $rawDisplayText)');
  },
  onUrlHover: (url, rawDisplayText, isHovering) {
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

### Example

```dart
Textf(
  'The **quick** _brown_ fox jumps over '
  'the ~~lazy~~ `dog`. \*Escaped asterisks\*',
  style: TextStyle(fontSize: 18),
  textAlign: TextAlign.center,
)
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/quick_brown_fox.png)

## Customizing with TextfOptions

The `TextfOptions` widget allows you to customize the appearance and behavior of formatted text throughout your app. It uses the InheritedWidget pattern to make configuration available to all descendant `Textf` widgets.

### Basic Usage

```dart
TextfOptions(
  // Styling options
  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
  italicStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
  codeStyle: TextStyle(fontFamily: 'RobotoMono', backgroundColor: Colors.grey.shade200),

  // Link options
  urlStyle: TextStyle(color: Colors.green),
  urlHoverStyle: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
  urlMouseCursor: SystemMouseCursors.click,

  // Link callbacks
  onUrlTap: (url, displayText) {
    launchUrl(Uri.parse(url));
  },
  onUrlHover: (url, displayText, isHovering) {
    print('Hover state changed for $url: $isHovering');
  },

  child: Textf(
    'This text has **bold**, *italic*, `code`, and [links](https://example.com).',
    style: TextStyle(fontSize: 16),
  ),
)
```

### Inheritance

When multiple `TextfOptions` are nested in the widget tree, options are inherited through the hierarchy. If a specific property (e.g., `boldStyle`) is `null` on the nearest ancestor, Textf will automatically look up the widget tree for the next ancestor that defines that property.

```dart
TextfOptions(
  // Root level options (global defaults)
  boldStyle: TextStyle(fontWeight: FontWeight.w900),
  urlStyle: TextStyle(color: Colors.blue),
  onUrlTap: (url, text) => print('Root tap: $url'),
  child: Column(
    children: [
      Textf('This uses blue links and w900 bold.'),

      TextfOptions(
        // Override only URL style for this subtree
        urlStyle: TextStyle(color: Colors.green),
        // boldStyle is inherited from the root
        // onUrlTap is inherited from the root
        child: Textf('This uses green links and w900 bold.'),
      ),
    ],
  ),
)
```

## Properties

Textf supports all the same styling properties as Flutter's standard Text widget:

```dart
Textf(
  'Formatted **text** example',
  style: TextStyle(fontSize: 16),
  strutStyle: StrutStyle(...),
  textAlign: TextAlign.center,
  textDirection: TextDirection.ltr,
  locale: Locale('en', 'US'),
  softWrap: true,
  overflow: TextOverflow.ellipsis,
  textScaler: TextScaler.linear(1.2),
  maxLines: 2,
  semanticsLabel: 'Example text',
)
```

## Performance

Textf is designed with performance in mind:

- **Optimized parsing** - Efficient tokenization algorithm
- **Smart caching** - Automatically caches parse results
- **Fast paths** - Quick handling of plain text without formatting
- **Memory efficient** - Minimal memory overhead

Performance benchmarks show Textf maintains smooth rendering (60+ FPS) even with frequent updates and complex formatting. Memory usage scales linearly with text length.

## Limitations

Textf is intentionally focused on inline formatting only:

- Maximum nesting depth of 2 formatting levels
- No support for block elements (headings, lists, quotes, etc.)
- No support for images
- Designed for inline formatting and links only, not full Markdown rendering

If you need more comprehensive Markdown features, consider a full Markdown package.

## Roadmap

### Implemented Features

- ✅ Bold formatting with `**text**` or `__text__`
- ✅ Italic formatting with `*text*` or `_text_`
- ✅ Combined bold+italic with `***text***` or `___text___`
- ✅ Strikethrough with `~~text~~`
- ✅ Inline code with `` `code` ``
- ✅ Nested formatting (up to 2 levels deep)
- ✅ Escaped characters with backslash
- ✅ Performance optimization with caching
- ✅ Fast paths for plain text
- ✅ Link support with `[text](url)`
- ✅ Custom styles for each formatting type

### Planned Features

- 🔲 Full support for Flutter text properties
- 🔲 Superscript and subscript with `^text^` and `~text~`
- 🔲 Custom tokenizer/parser support
- 🔲 RTL language optimization
- 🔲 Improved accessibility features

## When to Use Textf

- ✅ When you need simple inline text formatting
- ✅ When performance is critical
- ✅ When you want a familiar Flutter Text-like API
- ✅ For chat messages, comments, captions, or UI labels
- ✅ For internationalized text with formatting
- ❌ When you need full Markdown with blocks, links, images
- ❌ When you need HTML rendering
- ❌ For complex document rendering

## Internationalization (i18n)

Textf is particularly valuable for applications requiring internationalization:

### Why Textf is Great for i18n

- **Translator-friendly syntax** - Simple formatting that non-technical translators can understand
- **Consistent across languages** - Maintain formatting regardless of text length or language
- **Error-tolerant** - Gracefully handles formatting mistakes that might occur during translation
- **No HTML required** - Avoid HTML tags that might break during translation workflows

### Example with i18n

```dart
// In your translation file (e.g., app_en.arb)
{
  "welcomeMessage": "Welcome to **Flutter**, the _beautiful_ way to build apps!",
  "errorMessage": "__Oops!__ Something went *wrong*. Please try again."
}

// In your widget
Textf(
  AppLocalizations.of(context)!.welcomeMessage,
  style: Theme.of(context).textTheme.bodyLarge,
)
```

This approach allows translators to focus on the content while preserving formatting instructions as simple text markers rather than complex HTML or widgets.

## Error Handling

Textf handles malformed formatting gracefully:

- Unclosed tags are treated as plain text
- Excessive nesting is prevented
- Escaped characters are properly rendered

## API Documentation

For complete API documentation, see the [API reference](https://pub.dev/documentation/textf/latest/) on pub.dev.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
