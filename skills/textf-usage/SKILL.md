---
name: "textf-usage"
description: "pkg:textf - Inline Markdown-like text formatting for Flutter (drop-in replacements for Text and TextEditingController)"
metadata:
  version: "1.2.0"
---

## Core Concepts

`textf` provides drop-in replacements for `Text` and `TextEditingController` with inline formatting.

- **Zero dependencies**
- **O(1) style resolution** via `TextfOptions`
- **Single-pass O(N) parsing** with LRU caching
- **CommonMark-style flanking rules** for markers (no leading/trailing whitespace inside markers)

## Formatting Syntax

| Format        | Syntax          | Alternate     | Note                          |
| ------------- | --------------- | ------------- | ----------------------------- |
| Bold          | `**bold**`      | `__bold__`    |                               |
| Italic        | `*italic*`      | `_italic_`    |                               |
| Bold + Italic | `***both***`    | `___both___`  |                               |
| Strikethrough | `~~strike~~`    |               |                               |
| Underline     | `++underline++` |               |                               |
| Highlight     | `==highlight==` |               | `<mark>` style                |
| Inline code   | `` `code` ``    |               |                               |
| Superscript   | `^super^`       |               | `E = mc²`                     |
| Subscript     | `~sub~`         |               | `H₂O`                         |
| Link          | `[label](url)`  |               | Supports nested formatting    |
| Placeholder   | `{key}`         |               | Injects `InlineSpan`          |

### Validation Rules
- **Flanking:** `*italic*` is valid; `* italic *` is plain text.
- **Nesting:** Max 2 levels (e.g., `**_bold italic_**`). 3rd level renders as literal text.
- **Parsing:** Unclosed markers render as plain text. Escaping: `r'\**literal\**'`.

## Primary Components

### `Textf` Widget
Drop-in for `Text`. Supports all standard `Text` properties (`maxLines`, `overflow`, etc.).
```dart
Textf(
  '**Bold**, [link](https://dart.dev), {icon}',
  style: TextStyle(fontSize: 16),
  placeholders: {'icon': WidgetSpan(child: Icon(Icons.star))},
)
```

### `TextfEditingController`
Drop-in replacement for `TextEditingController`. Renders styles live in `TextField` as user types.
Note: `{key}` placeholders render as literal text in editor.
```dart
final controller = TextfEditingController();

TextField(
  controller: controller, // styles render as user types
  maxLines: null,
)
```

### `TextfOptions`
InheritedWidget for scoped style configuration (e.g., `boldStyle`, `onLinkTap`).
- **Styles:** Merged hierarchically (nearest overrides property, keeps others).
- **Callbacks:** Nearest ancestor wins (no merging).
```dart
TextfOptions(
  onLinkTap: (url, text) => print('Tapped $url'),
  boldStyle: const TextStyle(fontWeight: FontWeight.w900),
  italicStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
  child: Column(
    children: [
      Textf('**Bold** and _italic_ inherit styles'),
      TextfOptions(
        boldStyle: const TextStyle(color: Colors.red), // overrides only color
        child: Textf('**Red Bold**'),
      ),
    ],
  ),
)
```

## Extensions
- `String.textf(...)`: Creates a `Textf` widget.
- `String.stripFormatting()`: Returns plain text without markers.

## Best Practices
- Use `TextfOptions` at the app root or feature level to avoid repeating styles.
- Prefer `TextfEditingController` for rich-text input without complex state management.
- For performance, `Textf` uses a dual-bounded LRU cache for parsed results.
