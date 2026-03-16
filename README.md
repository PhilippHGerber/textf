# Text*f*

[![pub package](https://img.shields.io/pub/v/textf.svg?label=pub.dev&labelColor=333940&logo=flutter&color=00589B)](https://pub.dev/packages/textf) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![style: very good analysis](https://img.shields.io/badge/Style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis) [![tests](https://github.com/PhilippHGerber/textf/actions/workflows/package.yaml/badge.svg)](https://github.com/PhilippHGerber/textf/actions/workflows/package.yaml) [![coverage](https://raw.githubusercontent.com/PhilippHGerber/textf/badges/coverage.svg)](https://github.com/PhilippHGerber/textf/actions/workflows/package.yaml)
[![AI Skills](https://img.shields.io/badge/AI-SKILL.md-blueviolet?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDI0IDI0IiBoZWlnaHQ9IjI0cHgiIHZpZXdCb3g9IjAgMCAyNCAyNCIgd2lkdGg9IjI0cHgiIGZpbGw9IiNmZmZmZmYiPjxnPjxyZWN0IGZpbGw9Im5vbmUiIGhlaWdodD0iMjQiIHdpZHRoPSIyNCIgeD0iMCIvPjwvZz48Zz48Zz48cG9seWdvbiBwb2ludHM9IjE5LDkgMjAuMjUsNi4yNSAyMyw1IDIwLjI1LDMuNzUgMTksMSAxNy43NSwzLjc1IDE1LDUgMTcuNzUsNi4yNSIvPjxwb2x5Z29uIHBvaW50cz0iMTksMTUgMTcuNzUsMTcuNzUgMTUsMTkgMTcuNzUsMjAuMjUgMTksMjMgMjAuMjUsMjAuMjUgMjMsMTkgMjAuMjUsMTcuNzUiLz48cGF0aCBkPSJNMTEuNSw5LjVMOSw0TDYuNSw5LjVMMSwxMmw1LjUsMi41TDksMjBsMi41LTUuNUwxNywxMkwxMS41LDkuNXogTTkuOTksMTIuOTlMOSwxNS4xN2wtMC45OS0yLjE4TDUuODMsMTJsMi4xOC0wLjk5IEw5LDguODNsMC45OSwyLjE4TDEyLjE3LDEyTDkuOTksMTIuOTl6Ii8+PC9nPjwvZz48L3N2Zz4=&logoColor=white)](./skills/textf-usage/SKILL.md)

[Website](https://textf.philippgerber.li/) • [Quickstart](https://textf.philippgerber.li/docs/quickstart) • [Documentation](https://textf.philippgerber.li/docs/overview) • [Playground](https://textf.philippgerber.li/editor)

Inline Markdown-like formatting for Flutter — as drop-in replacements for `Text` and `TextEditingController`. Zero dependencies. **Bold**, *italic*, `code`, [URL Link](.), <mark>highlights</mark>, super²/subscript₂.

---

> ⚠️ **Upgrading from 1.1.x?** Version 1.2.0 introduces strict flanking rules for formatting markers. Markers with surrounding whitespace — such as `* spaced *` — no longer trigger formatting. Update these to `*not-spaced*`. See [Flanking Rules](#flanking-rules) for details.

---

## Two Drop-in Replacements

### `Textf` — Formatted display text

Replace `Text` with `Textf` and your strings render with **bold**, *italic*, `code`, highlights, links, and more.

```dart
Textf('Hello **Flutter**. Build for ==any screen==!');
```

![Textf widget screenshot](https://github.com/PhilippHGerber/textf/raw/main/images/textf.png)

### `TextfEditingController` — Live formatting in text fields

Replace `TextEditingController` with `TextfEditingController` to render formatting live in `TextField` as the user types — no extra widgets needed.

```dart
final controller = TextfEditingController();
TextField(controller: controller);
```

![TextfEditingController screenshot](https://github.com/PhilippHGerber/textf/raw/main/images/textf_editing_controller.gif)

---

## Quick Start

**1. Add the dependency:**

```sh
flutter pub add textf
```

**2. Import the package:**

```dart
import 'package:textf/textf.dart';
```

**3. Use it — that's it:**

```dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

class MyWidget extends StatelessWidget {
  final _controller = TextfEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drop-in for Text
        Textf(
          '**Bold**, *italic*, `code`, and [links](https://flutter.dev)',
          style: TextStyle(fontSize: 16),
        ),

        // Drop-in for TextEditingController
        TextField(controller: _controller),
      ],
    );
  }
}
```

Both widgets share the same formatting syntax and can be configured together with `TextfOptions`.

---

## Limitations

| Limitation                 | Reason                                                                           |
| -------------------------- | -------------------------------------------------------------------------------- |
| **No block elements**      | Textf is for inline formatting only — no headings, lists, quotes, or images      |
| **Max 2 nesting levels**   | `**bold _italic_**` works, deeper nesting renders as plain text                  |
| **Selection across links** | Links use `WidgetSpan`, so selection can't span across them (Flutter limitation) |
| **Widget placeholders**    | `{key}` placeholders render as literal text in `TextfEditingController`          |

---

## When to Use Textf

Textf is intentionally limited to **inline formatting only**. It is not a Markdown renderer.

**✅ Great for:**

- Chat messages and comment sections
- UI labels, captions, and tooltips
- Internationalized strings with inline emphasis
- User-generated content with simple formatting
- Performance-critical lists with many text widgets

**❌ Not designed for:**

- Full Markdown documents with headings, lists, or tables
- HTML rendering
- Block-level structure of any kind

---

## Formatting Markers

Both `Textf` and `TextfEditingController` use the same syntax:

![Formatting markers showcase](https://github.com/PhilippHGerber/textf/raw/main/images/formatting_markers.png)

| Format        | Syntax              | Alternate            | Result                         |
| ------------- | ------------------- | -------------------- | ------------------------------ |
| Bold          | `**bold**`          | `__bold__`           | **bold**                       |
| Italic        | `*italic*`          | `_italic_`           | *italic*                       |
| Bold + Italic | `***bold italic***` | `___bold italic___`  | ***both***                     |
| Strikethrough | `~~strike~~`        |                      | ~~strikethrough~~              |
| Underline     | `++underline++`     |                      | <u>underline</u>               |
| Highlight     | `==highlight==`     |                      | <mark>highlight</mark>         |
| Inline code   | `` `code` ``        |                      | `code`                         |
| Superscript   | `^super^`           |                      | E = mc²                        |
| Subscript     | `~sub~`             |                      | H₂O                            |
| Link          | `[label](url)`      |                      | [Flutter](https://flutter.dev) |
| Placeholder   | `{key}`             |                      | (inserted widget)              |

### Flanking Rules

Formatting markers follow CommonMark-style flanking rules. Openers must not be followed by whitespace, and closers must not be preceded by whitespace:

```
*italic*    ✅    * italic *   ❌
**bold**    ✅    ** bold **   ❌
```

This prevents accidental formatting of bullet points (`* Item`) and math expressions (`2 * 3`).

### Nesting

Up to **2 levels** of nesting are supported. A third level renders as plain text — it never crashes or corrupts the surrounding output.

```dart
Textf('**Bold with _italic_ inside.**')   // ✅ two levels — works
Textf('**_`three levels`_**')             // ⚠️ third level renders as literal `three levels`
```

### Malformed or Unclosed Markers

Textf is forgiving. If a marker has no matching closer, it renders as plain text — it never crashes, and the rest of the string continues to format normally.

```dart
Textf('**unclosed and *italic*')
// renders: **unclosed and italic  (italic still applies correctly)
```

### Escaping

Use a backslash to render any marker literally. You can escape formatting markers as well as placeholders:

```dart
Textf(r'\**not bold\** and \{not_a_placeholder}')
// renders: **not bold** and {not_a_placeholder}
```

---

## `Textf` Widget

A drop-in replacement for Flutter's `Text` widget. All `Text` parameters are supported identically — `style`, `textAlign`, `maxLines`, `overflow`, `textScaler`, `locale`, `textDirection`, `strutStyle`, `semanticsLabel`, and more.

### Basic Usage

```dart
Textf(
  '**Bold**, *italic*, ~~strike~~, ++underline++, ==highlight==, '
  '`code`, ^super^, ~sub~, [link](https://flutter.dev)',
  style: TextStyle(fontSize: 16),
  textAlign: TextAlign.center,
  maxLines: 3,
  overflow: TextOverflow.ellipsis,
)
```

### String Extensions

The `.textf()` extension lets you write formatting inline wherever you'd naturally write a string — useful in widget trees, i18n, and ARB-based localization:

```dart
// Directly in a widget tree
'**Status:** All systems operational'.textf()

// With style parameters
'Hello, **$username**!'.textf(style: TextStyle(fontSize: 18))

// From a localized string
AppLocalizations.of(context).welcomeMessage.textf()
```

All `Textf` constructor parameters are available on `.textf()`.

To extract clean, plain text from a formatted string (e.g., for search, analytics, or `Semantics` labels), use `.stripFormatting()`:

```dart
'**Hello** [Flutter](.)!'.stripFormatting() // Returns: "Hello Flutter!"
```

### Widget Placeholders

Embed arbitrary Flutter widgets inline using `{key}` syntax:

```dart
Textf(
  'Made with {heart} using {flutter}',
  placeholders: {
    'heart': WidgetSpan(child: Icon(Icons.favorite, color: Colors.red)),
    'flutter': WidgetSpan(child: FlutterLogo(size: 16)),
  },
)
```

Keys must be alphanumeric or underscores. Placeholders are not substituted in `TextfEditingController` — they render as literal `{key}` text there.

### Links

Links are rendered as tappable `WidgetSpan` elements. Handle taps by wrapping with `TextfOptions` (see [TextfOptions](#textfoptions) for full configuration):

```dart
TextfOptions(
  onLinkTap: (url, displayText) {
    // Open in browser, push a route, or handle internally
    debugPrint('Tapped: $url');
  },
  child: Textf('Visit [Flutter](https://flutter.dev)'),
)
```

> **Note:** Because links are `WidgetSpan` elements, text selection cannot span across them. This is a Flutter platform limitation, not a Textf bug.

### SelectionArea Support

```dart
SelectionArea(
  child: Textf('Select **this** formatted text!'),
)
```

### Performance

`Textf` caches parsed span trees using an LRU cache. Re-renders skip re-parsing when text, style, theme, and `TextfOptions` are unchanged — important for animated lists or chat feeds with many items. The cache invalidates automatically on changes.

To free memory in low-memory situations:

```dart
Textf.clearCache();
```

---

## `TextfEditingController`

A drop-in replacement for `TextEditingController`. Attach it to any `TextField` or `TextFormField` to render live formatting as the user types. The underlying text is always plain — the controller adds visual styling on top without affecting the stored value. Supports full IME (Input Method Editor) composing for seamless text entry in all languages.

### Limitations

Before building with this controller, be aware of the following constraints:

- **Widget placeholders** (`{key}`) render as literal text — no widget substitution in editable fields
- **Links** display the full `[text](url)` syntax while editing — styled, but not tappable
- **Cross-line markers** never pair across newlines — a marker on line 1 cannot accidentally format content on line 2

### Basic Usage

```dart
final controller = TextfEditingController();

TextField(controller: controller)
```

With initial content:

```dart
TextfEditingController(text: 'Hello **bold**')
```

### Marker Visibility

`MarkerVisibility` controls how formatting markers appear while the user edits.

`MarkerVisibility.always` *(default)* — markers are always visible with dimmed styling. Predictable cursor behavior, works well on all platforms.

`MarkerVisibility.whenActive` — markers hide instantly when the cursor leaves the formatted span, giving a cleaner live-preview effect. During non-collapsed selection (e.g. drag-select on mobile), all markers hide automatically to prevent layout jumps that would shift selection handles.

```dart
TextfEditingController(markerVisibility: MarkerVisibility.whenActive)
```

Change the mode at runtime and the field re-renders immediately:

```dart
controller.markerVisibility = MarkerVisibility.always;
```

### Large Text Protection

When text exceeds `maxLiveFormattingLength` characters, formatting is automatically disabled and the field renders as plain text. This prevents UI freezes on very long inputs.

```dart
TextfEditingController(maxLiveFormattingLength: 2500) // default: 5000
```

### Custom Styles

Wrap the `TextField` with `TextfOptions` to control how formatted spans appear:

```dart
TextfOptions(
  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.deepOrange),
  codeStyle: TextStyle(fontFamily: 'monospace', color: Colors.pink),
  child: TextField(
    controller: TextfEditingController(),
    decoration: InputDecoration(labelText: 'Formatted input'),
  ),
)
```

---

## `TextfOptions`

`TextfOptions` is an `InheritedWidget` that configures all descendant `Textf` widgets and `TextfEditingController` instances. Place it once near the top of a screen — or at app level — to apply consistent formatting throughout.

```dart
TextfOptions(
  boldStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.deepOrange),
  codeStyle: TextStyle(fontFamily: 'monospace', color: Colors.pink),
  onLinkTap: (url, _) => debugPrint('Link tapped: $url'),
  child: YourWidget(),
)
```

![TextfOptions screenshot](https://github.com/PhilippHGerber/textf/raw/main/images/textfoptions.png)

### Style Options

| Property             | Applies to                  |
| -------------------- | --------------------------- |
| `boldStyle`          | `**bold**` / `__bold__`     |
| `italicStyle`        | `*italic*` / `_italic_`     |
| `boldItalicStyle`    | `***bold italic***`         |
| `strikethroughStyle` | `~~strike~~`                |
| `underlineStyle`     | `++underline++`             |
| `highlightStyle`     | `==highlight==`             |
| `codeStyle`          | `` `code` ``                |
| `superscriptStyle`   | `^super^`                   |
| `subscriptStyle`     | `~sub~`                     |
| `linkStyle`          | Links — normal state        |
| `linkHoverStyle`     | Links — hover state         |

### Link Options

| Property          | Type / Description                                                                   |
| ----------------- | ------------------------------------------------------------------------------------ |
| `onLinkTap`       | `(String url, String displayText) → void`                                            |
| `onLinkHover`     | `(String url, String displayText, {required bool isHovering}) → void`                |
| `linkMouseCursor` | `MouseCursor` — shown over links (default: `SystemMouseCursors.click`)               |
| `linkAlignment`   | `PlaceholderAlignment` — vertical alignment of link spans (default: `baseline`)      |

### Script Options

| Property                    | Description                               | Default |
| --------------------------- | ----------------------------------------- | ------- |
| `scriptFontSizeFactor`      | Font size multiplier for super/subscripts | `0.6`   |
| `superscriptBaselineFactor` | Vertical offset factor for superscripts   | `-0.4`  |
| `subscriptBaselineFactor`   | Vertical offset factor for subscripts     | `0.2`   |

### How Inheritance Works

`TextfOptions` uses two different strategies depending on the property type.

**Style properties merge down the tree.** A parent's color and a child's font weight both apply — neither is discarded. This mirrors how `TextStyle.merge` works across `DefaultTextStyle` in Flutter, and means you can define broad styles at a high level and refine them locally without losing the parent context.

```dart
TextfOptions(
  boldStyle: TextStyle(color: Colors.red),              // parent: red color
  child: TextfOptions(
    boldStyle: TextStyle(fontWeight: FontWeight.w900),  // child: heavy weight
    child: Textf('**Red AND heavy**'),                  // both apply ✅
  ),
)
```

**Callback and cursor properties use nearest-ancestor-wins.** The closest `TextfOptions` in the tree takes effect. This prevents double-firing when options are nested — only one handler should respond to a tap.

```dart
TextfOptions(
  onLinkTap: (url, _) => debugPrint('root handler'),
  child: TextfOptions(
    onLinkTap: (url, _) => debugPrint('inner handler'), // this one wins
    child: Textf('[tap me](https://example.com)'),
  ),
)
```

---

## Theme Integration

`Textf` automatically adapts to the active `ThemeData` — no configuration needed:

- **Links** use `colorScheme.primary`
- **Code background** uses `colorScheme.surfaceContainer`
- **Code text** uses `colorScheme.onSurfaceVariant`

Override any theme default with `TextfOptions`:

```dart
TextfOptions(
  linkStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
  child: Textf('A [custom colored](https://example.com) link.'),
)
```

---

## Accessibility

- **Text Scaling** — Respects `MediaQuery.textScalerOf(context)` and system font scaling settings
- **Screen Readers** — Links are wrapped in `Semantics(link: true)` for TalkBack and VoiceOver
- **RTL Support** — Bidirectional text and RTL languages work correctly throughout

---

## Comparison

| Feature           | Textf               | Full Markdown Packages |
| ----------------- | ------------------- | ---------------------- |
| Bundle size       | Tiny                | Large                  |
| Dependencies      | Zero                | Multiple               |
| Parse complexity  | O(N)                | Often O(N²) or worse   |
| API familiarity   | Identical to `Text` | Custom widgets         |
| Live editing      | ✅                  | Rarely                 |
| Block elements    | ❌                  | ✅                     |
| Best for          | Inline formatting   | Document rendering     |

---

## API Reference

Full documentation on [pub.dev](https://pub.dev/documentation/textf/latest/).

## AI Agent Skill

Textf ships with an [AI agent skill](https://pub.dev/packages/skills). Once you have `textf` as a dependency, run:

```sh
dart pub global activate skills
skills get
```

This installs Textf's skill into your project, giving AI coding agents (Claude Code, Cursor, Cline, and others) full knowledge of the API, formatting syntax, and best practices — enabling accurate, idiomatic suggestions without needing to read the docs.

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

> **About the name:** Textf is inspired by C's `printf` (print formatted). `Textf` (Text formatted) brings the same idea to Flutter — simple, efficient, and unsurprising.
