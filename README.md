# Text*f*

[![pub package](https://img.shields.io/pub/v/textf.svg)](https://pub.dev/packages/textf) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter widget for inline text formatting — fully compatible with Flutter’s `Text` widget.
Easily replace `Text` with `Textf` to add simple formatting:

```dart
Textf('Hello **Flutter**. Build for ==any screen== !');
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/textf.png)

## Overview

Textf provides basic text formatting capabilities similar to a subset of Markdown syntax, focusing exclusively on inline styles. It's designed for situations where you need simple text formatting without the overhead of a full Markdown rendering solution.

### About the Name

The name "Textf" is inspired by the C standard library function `printf` (print formatted), which formats text and writes it to standard output. Similarly, `Textf` (Text formatted) provides simple, efficient text formatting for Flutter applications.

### Why Text*f*?

* **Lightweight** – Significantly smaller and faster than full Markdown packages
* **Performance-focused** – Optimized for speed and memory efficiency
* **Flutter-native** – Uses the familiar Text API for seamless integration
* **Zero dependencies** – No external packages required
* **Interactive links** – Built-in link support with customizable styles and hover effects

Perfect for chat applications, comment sections, UI elements, and any scenario where simple inline formatting is all you need.

## Installation

Add Textf to your `pubspec.yaml`:

```yaml
dependencies:
  textf: ^0.5.0
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
      'Hello **bold** *italic* ~~strikethrough~~ `code` '
      '++underline++ ==highlight== '
      '[link](https://flutter.dev)',
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
| Underline     | `++underline++`              | ++underline++     |
| Highlight     | `==highlight==`              | ==highlight==     |
| Code          | `` `code` ``                 | `code`            |
| Link          | `[text](url)`                | [Example Link](https://example.com) |

---

### Links `[text](url)`

![image](https://github.com/PhilippHGerber/textf/raw/main/images/link-hover.gif)

* **Syntax:** Enclose the display text in square brackets `[]` and the URL in parentheses `()`.
* **Rendering:** Links are rendered with a distinct style (usually blue and underlined) that can be customized via `TextfOptions`.
* **Interaction:**
  * `Textf` renders links as tappable/clickable elements.
  * To handle taps (e.g., open the URL) or hovers, wrap your `Textf` widget (or a parent widget containing multiple `Textf` widgets) with `TextfOptions` and provide the `onUrlTap` and/or `onUrlHover` callbacks.
  * `TextfOptions` also allows custom styling for links (`urlStyle`, `urlHoverStyle`) and mouse cursor (`urlMouseCursor`).
* **Nested Formatting:** The display text within the square brackets `[ ]` can contain other formatting markers (e.g., `[**bold link**](https://example.com)`).

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
  'The **quick** _brown_ fox jumps over \n'
  'the ~~lazy~~ ++wily++ ==alert== `dog`. \*Escaped asterisks\*',
  style: TextStyle(fontSize: 18),
  textAlign: TextAlign.center,
)
```

![image](https://github.com/PhilippHGerber/textf/raw/main/images/quick_brown_fox.png)

## Customizing with TextfOptions

The `TextfOptions` widget allows you to customize the appearance and behavior of formatted text throughout your app. It uses the InheritedWidget pattern to make configuration available to all descendant `Textf` widgets.

When resolving styles or callbacks, Textf searches up the widget tree for the nearest `TextfOptions` ancestor that defines the specific property (e.g., `boldStyle`, `onUrlTap`). If no ancestor defines it, theme-based defaults (for code/links) or package defaults (for bold, italic, strikethrough) are used.

### Basic Usage

```dart
// Import url_launcher if you need it for the tap callback
// import 'package:url_launcher/url_launcher.dart';

TextfOptions(
  // Styling options (merged onto the base style)
  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
  italicStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
  codeStyle: TextStyle(fontFamily: 'RobotoMono', backgroundColor: Colors.grey.shade200),

  strikethroughStyle: TextStyle(decorationColor: Colors.orange, decorationThickness: 3.0),

  underlineStyle: TextStyle(decoration: TextDecoration.underline, decorationColor: Colors.purple, decorationStyle: TextDecorationStyle.wavy),
  highlightStyle: TextStyle(backgroundColor: Colors.greenAccent.withOpacity(0.5), color: Colors.black),

  // Link options
  urlStyle: TextStyle(color: Colors.green),
  urlHoverStyle: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
  urlMouseCursor: SystemMouseCursors.click,

  // Link callbacks
  onUrlTap: (url, displayText) {
    // Example using url_launcher:
    // final uri = Uri.tryParse(url);
    // if (uri != null) {
    //   launchUrl(uri);
    // }
    print('Tapped URL: $url (Display Text: $displayText)');
  },
  onUrlHover: (url, displayText, isHovering) {
    print('Hover state changed for $url: $isHovering');
  },

  child: Textf(
    'This text has **bold**, *italic*, ~~strikethrough~~, `code`, '
    '++underline++, ==highlight==, '
    'and [links](https://example.com).',
    style: TextStyle(fontSize: 16),
  ),
)
```

**Available `TextfOptions` Properties:**

* **`boldStyle`**: `TextStyle?` for bold text (`**bold**` or `__bold__`).
  * Merged **onto** the base text style if provided.
  * If `null`, `DefaultStyles.boldStyle` (adds `FontWeight.bold`) is used as a fallback.
* **`italicStyle`**: `TextStyle?` for italic text (`*italic*` or `_italic_`).
  * Merged **onto** the base text style if provided.
  * If `null`, `DefaultStyles.italicStyle` (adds `FontStyle.italic`) is used as a fallback.
* **`boldItalicStyle`**: `TextStyle?` for bold and italic text (`***both***` or `___both___`).
  * Merged **onto** the base text style if provided.
  * If `null`, `DefaultStyles.boldItalicStyle` (adds `FontWeight.bold` and `FontStyle.italic`) is used as a fallback.
* **`strikethroughStyle`**: `TextStyle?` for strikethrough text (`~~strike~~`).
  * Merged **onto** the base text style if provided.
  * If `null`, the default strikethrough effect is applied using the resolved `strikethroughThickness`. Providing this overrides `strikethroughThickness`.
* **`strikethroughThickness`**: `double?` Specifies the thickness of the strikethrough line.
  * This property is **only used if `strikethroughStyle` is `null`**.
  * If both `strikethroughStyle` and `strikethroughThickness` are `null` in the entire ancestor chain, `DefaultStyles.defaultStrikethroughThickness` (`1.5`) is used.
* **`underlineStyle`**: `TextStyle?` for underlined text (`++underline++`).
  * Merged **onto** the base text style if provided.
  * If `null`, `DefaultStyles.underlineStyle` (adds `TextDecoration.underline`) is used as a fallback. The decoration color and thickness are derived from the base style or package defaults.
* **`highlightStyle`**: `TextStyle?` for highlighted text (`==highlight==`).
  * Merged **onto** the base text style if provided.
  * If `null`, a theme-aware default highlight style (e.g., using `Theme.of(context).colorScheme.tertiaryContainer` as background) is applied.
* **`codeStyle`**: `TextStyle?` for inline code text (`` `code` ``).
  * Merged **onto** the base text style if provided.
  * Overrides the default theme-based styling for code if specified.
* **`urlStyle`**: `TextStyle?` for link text (`[text](url)`) in its normal (non-hovered) state.
  * Merged **onto** the base text style if provided.
  * Overrides the default theme-based styling for links if specified.
* **`urlHoverStyle`**: `TextStyle?` for link text when hovered.
  * Merged **onto** the final *normal* link style (which includes base style and `urlStyle` if provided).
  * Allows defining specific hover appearances.
* **`urlMouseCursor`**: `MouseCursor?` The cursor to display when hovering over links.
  * Searches up the widget tree for the first non-null value.
  * If none found, defaults to `DefaultStyles.urlMouseCursor` (`SystemMouseCursors.click`).
* **`onUrlTap`**: Callback `Function(String url, String rawDisplayText)?` triggered when a link is tapped or clicked.
  * Searches up the widget tree for the first non-null callback.
  * Provides the resolved URL and the original, unparsed display text (e.g., `**bold** link`).
* **`onUrlHover`**: Callback `Function(String url, String rawDisplayText, bool isHovering)?` triggered when the mouse pointer enters or exits the bounds of a link.
  * Searches up the widget tree for the first non-null callback.
  * Provides the resolved URL, the raw display text, and the current hover state (`true` on enter, `false` on exit).

### Inheritance

When multiple `TextfOptions` are nested in the widget tree, options are inherited through the hierarchy. If a specific property (e.g., `boldStyle`, `strikethroughThickness`, `onUrlTap`) is `null` on the nearest ancestor `TextfOptions` widget, Textf automatically searches further up the widget tree for the first ancestor that *does* define that property. This allows for global defaults with specific overrides in subtrees.

```dart
TextfOptions(
  // Root level options (global defaults)
  boldStyle: TextStyle(fontWeight: FontWeight.w900),
  strikethroughThickness: 2.0, // Use thickness here, applies if style is null below
  urlStyle: TextStyle(color: Colors.blue),
  onUrlTap: (url, text) => print('Root tap: $url'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, // Align text left for readability
    children: [
      Textf('This uses **blue links**, w900 bold, and ~~thickness 2.0~~.'),

      SizedBox(height: 16), // Add some spacing

      TextfOptions(
        // Override only URL style and strikethrough appearance for this subtree
        urlStyle: TextStyle(color: Colors.green),
        strikethroughStyle: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red, decorationThickness: 1.0), // Use full style here

        // boldStyle is inherited from the root
        // onUrlTap is inherited from the root
        // strikethroughThickness from root is IGNORED because strikethroughStyle is set here
        child: Textf('This uses **green links**, w900 bold, and ~~red line thickness 1.0~~.'),
      ),

      SizedBox(height: 16),

      TextfOptions(
         // Override only thickness, inherit bold/url/tap from root
         strikethroughThickness: 0.5,
         child: Textf('This uses **blue links**, w900 bold, and ~~very thin thickness 0.5~~.'),
      ),
    ],
  ),
)
```

## Styling Recommendations

To effectively style your `Textf` widgets and leverage the theme-aware defaults and customization options, follow these recommendations:

1. **Use `DefaultTextStyle` for Base Styles:**
    * **What:** Apply base styling like font size, default text color, or font family by wrapping `Textf` (or a common ancestor) with `DefaultTextStyle`.
    * **Why:** This is the standard Flutter approach for inherited text styles. It ensures that `Textf`'s theme-aware defaults (for code and links) and relative format styles (bold, italic) are correctly merged onto a consistent base style provided by your app's theme or your explicit `DefaultTextStyle`.

    ```dart
    // Good: Set base style via DefaultTextStyle
    DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.deepPurple),
      child: Textf(
        'This text uses the default style. **Bold** inherits it, and `code` uses theme colors based on it.',
      ),
    )
    ```

2. **Use `TextfOptions` for Format-Specific Styles:**
    * **What:** Use `TextfOptions` to customize the appearance of specific formatting types (e.g., making bold text blue, changing link underlines, setting a custom code background).
    * **Why:** `TextfOptions` provides targeted overrides for how formatted segments look, taking precedence over theme and package defaults for those specific formats. See the "Customizing with TextfOptions" section for details.

3. **Use `Textf`'s `style` Parameter Cautiously:**
    * **What:** The `style` parameter directly on the `Textf` widget.
    * **Why:** Use this primarily for one-off style overrides on a specific `Textf` instance *where you don't want it to inherit from `DefaultTextStyle`*. Be aware that providing an explicit `style` here **replaces** the `DefaultTextStyle` when the parser calculates its internal base style. If this explicit `style` is incomplete (e.g., only sets `fontSize`), it can interfere with the correct application of theme-based defaults (like code background/color) for that specific instance. Prefer `DefaultTextStyle` for setting the base.

    ```dart
    // Use with caution: Might interfere with theme defaults for code/links within this Textf
    Textf(
      'Specific override `code`.',
      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic), // Overrides DefaultTextStyle here
    )
    ```

4. **Understand Styling Precedence:**
    * `Textf` resolves styles in this order (highest priority first):
        1. **`TextfOptions`:** Specific style defined for the format type (e.g., `boldStyle`, `urlStyle`) found in the nearest ancestor `TextfOptions`.
        2. **Theme/Package Defaults (if no Option):**
            * For `code`, links, and `highlight`: Theme-aware defaults derived from `ThemeData` (e.g., `colorScheme.primary` for links).
            * For `bold`, `italic`, `strikethrough`, `underline`: Relative styles applied to the base style (e.g., adding `FontWeight.bold`).
        3. **Base Style:** The style inherited from `DefaultTextStyle` or provided directly via `Textf`'s `style` parameter.

By following these guidelines, you can ensure predictable styling that integrates well with your application's theme while retaining full control over specific formatting appearances via `TextfOptions`.

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

* **Optimized parsing** - Efficient tokenization algorithm
* **Smart caching** - Automatically caches parse results
* **Fast paths** - Quick handling of plain text without formatting
* **Memory efficient** - Minimal memory overhead

Performance benchmarks show Textf maintains smooth rendering (60+ FPS) even with frequent updates and complex formatting. Memory usage scales linearly with text length.

## Limitations

Textf is intentionally focused on inline formatting only:

* **Maximum nesting depth of 2 formatting levels**
* No support for block elements (headings, lists, quotes, etc.)
* No support for images
* Designed for inline formatting and links only, not full Markdown rendering

If you need more comprehensive Markdown features, consider a full Markdown package.

## Roadmap

### Implemented Features

* ✅ Bold formatting with `**text**` or `__text__`
* ✅ Italic formatting with `*text*` or `_text_`
* ✅ Combined bold+italic with `***text***` or `___text___`
* ✅ Strikethrough with `~~text~~`
* ✅ Inline code with `` `code` ``
* ✅ Underline with `++underline++`
* ✅ Highlight with `==highlight==`
* ✅ Nested formatting (up to 2 levels deep)
* ✅ Escaped characters with backslash
* ✅ Fast paths for plain text
* ✅ Link support with `[text](url)`
* ✅ Custom styles for each formatting type
* ✅ Full support for Flutter text properties

### Planned Features

* 🔲 Superscript and subscript with `^text^` and `~text~`: Textf('E = mc^2^ and H~2~O')
* 🔲 RTL language optimization
* 🔲 Improved accessibility features

## When to Use Text*f*

* ✅ When you need simple inline text formatting
* ✅ When performance is critical
* ✅ When you want a familiar Flutter Text-like API
* ✅ For chat messages, comments, captions, or UI labels
* ✅ For internationalized text with formatting
* ❌ When you need full Markdown with blocks, links, images
* ❌ When you need HTML rendering
* ❌ For complex document rendering

## Internationalization (i18n)

Text*f* is particularly valuable for applications requiring internationalization:

### Why Text*f* is Great for i18n

* **Translator-friendly syntax** - Simple formatting that non-technical translators can understand
* **Consistent across languages** - Maintain formatting regardless of text length or language
* **Error-tolerant** - Gracefully handles formatting mistakes that might occur during translation
* **No HTML required** - Avoid HTML tags that might break during translation workflows

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

* Unclosed tags are treated as plain text
* Excessive nesting is prevented
* Escaped characters are properly rendered

## API Documentation

For complete API documentation, see the [API reference](https://pub.dev/documentation/textf/latest/) on pub.dev.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
