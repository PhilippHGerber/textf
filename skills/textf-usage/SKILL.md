---
name: "textf-usage"
description: "pkg:textf - Inline Markdown-like text formatting for Flutter (drop-in replacements for Text and TextEditingController)"
user-invocable: false
metadata:
  version: "1.2.3"
---

## When to use this skill

Load when:
- Adding formatted text display to a Flutter UI (bold, italic, links, code, highlights, etc.)
- Implementing a rich-text input field where formatting renders live as the user types
- Configuring scoped styles or a link tap handler via `TextfOptions`
- Extracting plain text from a formatted string with `stripFormatting()`

## Decision: which component?

| Goal | Use |
|---|---|
| Display formatted text (read-only) | `Textf` |
| Rich-text input (formatting as user types) | `TextfEditingController` + `TextField` |
| Scoped styles or link callbacks | `TextfOptions` ancestor |
| Plain text from a formatted string | `String.stripFormatting()` |

## Syntax reference

| Format | Syntax | Alternate | Pitfall |
|---|---|---|---|
| Bold | `**bold**` | `__bold__` | |
| Italic | `*italic*` | `_italic_` | |
| Bold + Italic | `***both***` | `___both___` | |
| Strikethrough | `~~strike~~` | | |
| Underline | `++underline++` | | |
| Highlight | `==highlight==` | | |
| Inline code | `` `code` `` | | |
| Superscript | `^super^` | | |
| Subscript | `~sub~` | | |
| Link | `[label](url)` | | nested formatting supported |
| Placeholder | `{key}` | | literal text inside `TextfEditingController` |

## Common recipes

### Display text with formatting
```dart
Textf(
  '**Bold**, *italic*, `code`, and ~~strike~~',
  style: const TextStyle(fontSize: 16),
)
```

### Link with tap handler
```dart
TextfOptions(
  onLinkTap: (url, text) => launchUrl(Uri.parse(url)),
  child: const Textf('[Open docs](https://dart.dev)'),
)
```

### Widget placeholder (icon, badge, etc.)
```dart
Textf(
  'Tap {icon} to continue',
  placeholders: {'icon': const WidgetSpan(child: Icon(Icons.star))},
)
```

### Rich-text input field
```dart
final controller = TextfEditingController();

TextField(
  controller: controller,
  maxLines: null,
)
```

### Scoped style overrides
```dart
TextfOptions(
  boldStyle: const TextStyle(fontWeight: FontWeight.w900),
  onLinkTap: (url, _) => launchUrl(Uri.parse(url)),
  child: Column(
    children: [
      const Textf('**Inherits bold style**'),
      TextfOptions(
        boldStyle: const TextStyle(color: Colors.red), // overrides only color; weight inherited
        child: const Textf('**Red bold**'),
      ),
    ],
  ),
)
```

### Strip formatting for plain text
```dart
final plain = '**Hello** *world*'.stripFormatting(); // → 'Hello world'
```

## Pitfalls

**Flanking rule — spaces break markers:**
`*italic*` → italic ✓
`* italic *` → literal `* italic *` ✗

**Nesting cap — max 2 levels:**
`**_bold italic_**` ✓
`**_~~third level~~_**` → `~~third level~~` renders as plain text, no error ✗

**Placeholders don't work in the editor:**
`{key}` renders as the literal string `{key}` inside `TextfEditingController`. Widget injection only works in `Textf`.

**Callback vs style inheritance — different rules:**
- `onLinkTap`, `onLinkHover`: nearest `TextfOptions` ancestor wins — no merging.
- Style properties (`boldStyle`, `italicStyle`, …): merged property-by-property up the tree — only set the properties you want to override.

**Escaping markers:**
Use a raw string: `r'\**not bold\**'`

## `TextfOptions` API

**Style properties** (all `TextStyle?`):
`boldStyle`, `italicStyle`, `boldItalicStyle`, `strikethroughStyle`, `underlineStyle`, `highlightStyle`, `codeStyle`, `superscriptStyle`, `subscriptStyle`, `linkStyle`, `linkHoverStyle`

**Callbacks:**
`onLinkTap(String url, String text)`, `onLinkHover(String? url, String? text)`
