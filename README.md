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

Perfect for chat applications, comment sections, UI elements, and any scenario where simple inline formatting is all you need.

## Screenshots

|                 Basic Formatting                 |                 Nested Formatting                  |                  Complex Formatting                  |
| :----------------------------------------------: | :------------------------------------------------: | :--------------------------------------------------: |
| ![Basic Formatting](https://github.com/PhilippHGerber/textf/raw/main/images/basic_formatting.png) | ![Nested Formatting](https://github.com/PhilippHGerber/textf/raw/main/images/nested_formatting.png) | ![Complex Formatting](https://github.com/PhilippHGerber/textf/raw/main/images/complex_formatting.png) |

|             Chat Bubble Example             |             Notification Example              |
| :-----------------------------------------: | :-------------------------------------------: |
| ![Chat Bubble](https://github.com/PhilippHGerber/textf/raw/main/images/chat_bubble.png) | ![Notification](https://github.com/PhilippHGerber/textf/raw/main/images/notification.png) |

## Installation

Add Textf to your `pubspec.yaml`:

```yaml
dependencies:
  textf: ^0.1.0
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
      'Hello **bold** *italic* ~~strikethrough~~ `code`',
      style: TextStyle(fontSize: 16),
    );
  }
}
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/example.png)

## Supported Formatting

Textf supports the following formatting syntax:

| Format        | Syntax                       | Result            |
| ------------- | ---------------------------- | ----------------- |
| Bold          | `**bold**` or `__bold__`     | **bold**          |
| Italic        | `*italic*` or `_italic_`     | *italic*          |
| Bold+Italic   | `***both***` or `___both___` | ***both***        |
| Strikethrough | `~~strikethrough~~`          | ~~strikethrough~~ |
| Code          | `` `code` ``                 | `code`            |

To escape formatting characters, use a backslash: `\*not italic\*`

### Nesting Formatting

When nesting formatting, use different marker types (asterisks vs underscores) to ensure proper parsing:

| Format            | Correct                  | Incorrect                |
| ----------------- | ------------------------ | ------------------------ |
| Nested formatting | `**Bold with _italic_**` | `**Bold with *italic***` |

Using the same marker type for nested formatting may result in unexpected rendering.

### Example

```dart
Textf(
  'The **quick** _brown_ fox jumps over the ~~lazy~~ `dog`. \*Escaped asterisks\*',
  style: TextStyle(fontSize: 18),
  textAlign: TextAlign.center,
)
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/quick_brown_fox.png)

### Real-world Examples

#### Chat Bubble

```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.blue.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Textf(
    'Hey! Did you read that **important** article I sent you about _Flutter performance_?',
    style: TextStyle(fontSize: 16),
  ),
)
```

#### Notification

```dart
ListTile(
  leading: Icon(Icons.notifications),
  title: Text('System Update'),
  subtitle: Textf(
    'Your device will restart in **5 minutes**. Save your work ~~or else~~!',
    style: TextStyle(fontSize: 14),
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
- No support for links or images
- Designed for inline formatting only, not full Markdown rendering

If you need more comprehensive Markdown features, consider a full Markdown package.

## Roadmap

### Implemented Features

- [x] Bold formatting with `**text**` or `__text__`
- [x] Italic formatting with `*text*` or `_text_`
- [x] Combined bold+italic with `***text***` or `___text___`
- [x] Strikethrough with `~~text~~`
- [x] Inline code with `` `code` ``
- [x] Nested formatting (up to 2 levels deep)
- [x] Escaped characters with backslash
- [x] Performance optimization with caching
- [x] Fast paths for plain text

### Planned Features

- [ ] Full support for Flutter text properties
- [ ] Link support with `[text](url)`
- [ ] Custom styles for each formatting type
- [ ] Superscript and subscript with `^text^` and `~text~`
- [ ] Highlighting/background color
- [ ] Color text formatting
- [ ] Custom tokenizer/parser support
- [ ] RTL language optimization
- [ ] Improved accessibility features

## When to Use Textf

✅ When you need simple inline text formatting

✅ When performance is critical

✅ When you want a familiar Flutter Text-like API

✅ For chat messages, comments, captions, or UI labels

✅ For internationalized text with formatting

❌ When you need full Markdown with blocks, links, images

❌ When you need HTML rendering

❌ For complex document rendering

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
