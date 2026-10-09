---
name: "textf-usage"
description: "textf: inline Markdown-like text formatting for Flutter. Use when writing code with `Textf`, `TextfEditingController` or `TextfOptions`, or when a string needs bold, links or headings without a full Markdown renderer."
---

# textf

`import 'package:textf/textf.dart';` is the whole public API. textf is design-system neutral: it builds on Flutter's `widgets` layer and never reads a `Theme`.

| Goal | Use |
|---|---|
| Display formatted text | `Textf(data, …)`: every `Text` parameter, plus `placeholders`. `'…'.textf(…)` is the same call. |
| Live formatting in a text field | `TextfEditingController` as the `controller` of any `TextField` |
| Styles, colors, link callbacks | a `TextfOptions` ancestor, which configures both of the above |
| Plain text from a formatted string | `'…'.stripFormatting()`, `controller.plainText` |

## Syntax

| Format | Syntax |
|---|---|
| Bold | `**bold**` or `__bold__` |
| Italic | `*italic*` or `_italic_` |
| Bold + italic | `***both***` or `___both___` |
| Strikethrough | `~~strike~~` |
| Underline | `++underline++` |
| Highlight | `==highlight==` |
| Inline code | `` `code` `` |
| Superscript, subscript | `^super^`, `~sub~` |
| Link | `[label](url)`; the label takes formatting, and a URL without a scheme gets `https://` |
| Widget placeholder | `{key}`, with keys of letters, digits and underscores |
| Heading | `# ` through `###### ` at the start of a line |
| Thematic break | a line of three or more `-`, `*` or `_` |

Any other Markdown (lists, blockquotes, tables, images, fenced code, HTML) renders as plain text; a document that needs it calls for a full Markdown package.

- **Flanking**: a marker hugs its text. `*italic*` formats, `* italic *` stays literal, so `2 * 3` and `* item` are safe.
- **Nesting** goes two levels deep (`**bold _italic_**`); a third level renders its markers as plain text.
- **Unpaired** markers render as plain text and the rest of the string still formats.
- **Escape** with a backslash in a raw string: `r'\*literal\* \{not_a_key}'`.

## `Textf`

```dart
Textf(
  'Tap {icon} or read the [docs](https://dart.dev)',
  placeholders: {'icon': WidgetSpan(child: Icon(Icons.star, size: 16))},
)
```

- Links render as `WidgetSpan`s, so a text selection stops at them.
- Parsed spans are cached (LRU) and invalidate on their own; `Textf.clearCache()` frees the memory.

## `TextfEditingController`

```dart
final controller = TextfEditingController(
  text: 'Hello **bold**',
  markerVisibility: MarkerVisibility.whenActive, // default: always
  maxLiveFormattingLength: 5000, // the default; longer text renders plain
);
```

- `controller.text` keeps the raw markers; `controller.plainText` strips them.
- `MarkerVisibility.always` shows every marker dimmed; `whenActive` shows only the markers around the cursor. It is settable at runtime.
- The editor styles text and substitutes nothing: `{key}` stays literal, a link shows its full `[label](url)` and is not tappable, a thematic break stays dimmed marker text.
- Markers pair within one line.
- Headings need a strut that lets a line grow: `strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: false)` on the `TextField`.

## `TextfOptions`

| Group | Properties |
|---|---|
| Style options (`TextStyle?`) | `boldStyle`, `italicStyle`, `boldItalicStyle`, `strikethroughStyle`, `underlineStyle`, `highlightStyle`, `codeStyle`, `superscriptStyle`, `subscriptStyle`, `linkStyle`, `linkHoverStyle`, `h1Style`–`h6Style` |
| Color options (`Color?`) | `linkColor`, `codeBackgroundColor`, `highlightColor`, `thematicBreakColor` |
| Links | `onLinkTap(url, displayText)`, `onLinkHover(url, displayText, {required bool isHovering})`, `linkMouseCursor`, `linkAlignment` |
| Scripts (`double?`) | `scriptFontSizeFactor` (0.6), `superscriptBaselineFactor`, `subscriptBaselineFactor` |
| Other | `strikethroughThickness` (used while `strikethroughStyle` is null), `thematicBreakBuilder(context)` (owns its own width) |

A **style option replaces** the built-in style: a `boldStyle` without a `fontWeight` is not bold, and a `codeStyle` needs its own font family and background. Heading and script styles are the exception and merge onto the built-in size. A **color option tints** the built-in style and keeps its typography, so reach for it to change only a color.

Precedence, highest first: style option (or `thematicBreakBuilder`) → color option → built-in default.

Nested `TextfOptions`: style options **merge** down the tree, so set only the properties that differ. Callbacks, cursors, color options and the builder take the **nearest** ancestor that sets them.

`TextfOptions.of(context)` and `maybeOf` return the merged `TextfOptionsData`.

## Colors and theme

Built-in colors derive from the surrounding text style: links are a fixed `#1A73E8` with an underline, code and highlight backgrounds are tints, code text keeps the surrounding text color. textf infers a dark surface from a light text color, so on mid-tone or gradient backgrounds set `codeBackgroundColor` and `highlightColor` yourself.

To use the app theme's colors (the 1.x behaviour), pass them once below the theme:

```dart
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
)
```

With `material_ui`, import `Theme` from that package: the SDK's `Theme` class is a different one and silently returns the fallback theme.
