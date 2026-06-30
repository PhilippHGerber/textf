# Textf v1.1.1 — Improvement TODO

> Non-breaking fixes and quality improvements identified in the v1.1.1 codebase audit.
> Ordered by severity: 🔴 High → 🟡 Medium → 🟢 Low.

---

## 🔴 High Priority — Bugs & Correctness

---

### Task 1 — Fix cache over-invalidation in `TextfRenderer`

- [ ] Split the instance-level cache check so that layout-only properties no longer trigger a re-parse

> **Commit:** `fix(renderer): exclude layout-only props from parse cache key`

**File:** `lib/src/widgets/internal/textf_renderer.dart`

**Problem:**

The `build()` method compares a wide set of widget properties before deciding whether to call `parse()` again. The check includes properties like `textAlign`, `textDirection`, `softWrap`, `overflow`, `maxLines`, `textWidthBasis`, `textHeightBehavior`, and `locale` — none of which are ever passed to `parse()`. They flow only to `DefaultTextStyle.merge` and `Text.rich`. This means that whenever a parent layout changes (e.g., toggling RTL, changing `maxLines` in a responsive widget), a full re-parse is triggered even though the resulting spans are byte-for-byte identical.

**Reasoning:**

The parse cache exists precisely to avoid redundant work. The span tree depends only on: `data`, `baseStyle`, `textScaler`, `placeholders`, `theme` (color scheme), and `textfOptions`. Any change to layout properties does not alter which spans are produced.

**Solution:**

Introduce a two-level cache check:

1. **Parse-relevant check** — gates whether `parse()` is called. Includes only: `data`, `baseStyle`, `textScaler`, `placeholders`, `theme` (color scheme subset), `optionsHash`.
2. **Layout-relevant tracking** — exists only to detect when the surrounding `DefaultTextStyle.merge` and `Text.rich` need to be rebuilt (which Flutter already handles via normal widget diffing, so no explicit tracking is needed here).

```dart
// BEFORE: one big condition including layout props
if (cachedSpans != null &&
    placeholdersMatch &&
    themeMatch &&
    _lastOptionsHash == currentOptionsHash &&
    _lastData == widget.data &&
    _lastStyle == currentBaseStyle &&
    _lastScaler == effectiveScaler &&
    _lastTextAlign == widget.textAlign &&      // ← not needed for parse
    _lastTextDirection == widget.textDirection && // ← not needed for parse
    _lastSoftWrap == widget.softWrap &&        // ← not needed for parse
    _lastOverflow == widget.overflow &&        // ← not needed for parse
    _lastMaxLines == widget.maxLines &&        // ← not needed for parse
    _lastTextWidthBasis == widget.textWidthBasis && // ← not needed
    _lastTextHeightBehavior == widget.textHeightBehavior && // ← not needed
    _lastLocale == widget.locale) { ...        // ← not needed for parse

// AFTER: parse gate uses only parse-relevant inputs
final bool parseInputsUnchanged =
    cachedSpans != null &&
    placeholdersMatch &&
    themeMatch &&
    _lastOptionsHash == currentOptionsHash &&
    _lastData == widget.data &&
    _lastStyle == currentBaseStyle &&
    _lastScaler == effectiveScaler;

if (parseInputsUnchanged) {
  // Cached spans are still valid — skip parse, build directly
  return DefaultTextStyle.merge(..., child: _buildRichText(cachedSpans!, effectiveScaler));
}
```

Remove the `_lastTextAlign`, `_lastTextDirection`, `_lastSoftWrap`, `_lastOverflow`, `_lastMaxLines`, `_lastTextWidthBasis`, `_lastTextHeightBehavior`, `_lastLocale` state fields entirely — they are not needed.

---

### Task 2 — Propagate `textDirection` and `locale` through `DefaultTextStyle.merge`

- [ ] Add `textDirection` and `locale` to the `DefaultTextStyle.merge` call inside `TextfRenderer.build()`

> **Commit:** `fix(renderer): wrap with Directionality when textDirection is set for WidgetSpan placeholders`

**File:** `lib/src/widgets/internal/textf_renderer.dart`

**Problem:**

The cache hit branch (and only it) wraps the result in `DefaultTextStyle.merge(textAlign, softWrap, overflow, maxLines, textWidthBasis, ...)`. However, `textDirection` and `locale` are passed directly to `Text.rich` but **not** to `DefaultTextStyle.merge`. Any `WidgetSpan` placeholder inserted into formatted text (e.g., an icon or inline widget that uses `DefaultTextStyle.of(context)`) will inherit the alignment and wrap settings from the parent but will be missing the `locale` and `textDirection` context.

**Reasoning:**

This is inconsistent with how Flutter's own `Text` widget behaves. A placeholder widget inside a `Textf` should see the same ambient text environment as the surrounding text. RTL layouts are especially affected — a placeholder in `[**icon**]({myIcon})` inside an Arabic-language string would not inherit the RTL direction if it reads from `DefaultTextStyle`.

**Solution:**

`DefaultTextStyle.merge` does not have `textDirection` or `locale` parameters (it only accepts the properties on `DefaultTextStyle`). The correct fix is to wrap with a `Directionality` widget if `textDirection` is provided, and pass `locale` down via a `Localizations.override` or simply trust that it reaches `Text.rich` correctly.

More practically — confirm whether `DefaultTextStyle` even carries `textDirection`/`locale`. If not, document explicitly in `TextfRenderer`'s class doc that placeholder widgets will not inherit `textDirection`/`locale` from the parent `Textf` and users should wrap their placeholder widgets directly. At minimum, add a `// Note:` comment at the `DefaultTextStyle.merge` call site explaining this gap.

```dart
// CURRENT — silent omission with no explanation
return DefaultTextStyle.merge(
  textAlign: widget.textAlign,
  softWrap: widget.softWrap,
  overflow: widget.overflow,
  maxLines: widget.maxLines,
  textWidthBasis: widget.textWidthBasis,
  child: _buildRichText(cachedSpans, effectiveScaler),
);

// IMPROVED — add explanatory comment, and wrap with Directionality if set
Widget result = DefaultTextStyle.merge(
  textAlign: widget.textAlign,
  softWrap: widget.softWrap,
  overflow: widget.overflow,
  maxLines: widget.maxLines,
  textWidthBasis: widget.textWidthBasis,
  // Note: textDirection and locale cannot be set via DefaultTextStyle.merge.
  // They are forwarded to Text.rich directly. Placeholder WidgetSpan children
  // that need textDirection should use a Directionality ancestor or set it explicitly.
  child: _buildRichText(cachedSpans, effectiveScaler),
);

if (widget.textDirection != null) {
  result = Directionality(textDirection: widget.textDirection!, child: result);
}
```

---

### Task 3 — Pre-resolve styles once in `TextfStyleResolver` to eliminate repeated tree walks

- [ ] Resolve all `TextfOptions` styles at `TextfStyleResolver` construction time rather than per-token

> **Commit:** `perf(resolver): pre-resolve all TextfOptions styles in single ancestor tree walk`

**Files:** `lib/src/styling/textf_style_resolver.dart`, `lib/src/widgets/textf_options.dart`

**Problem:**

`computeResolvedHash` (used for cache invalidation in `TextfRenderer`) correctly performs a single O(depth) tree walk across all ancestors. But the actual *style resolution* during parsing works differently: each call to `resolveStyle(TokenType.boldMarker, ...)` calls `options.getEffectiveBoldStyle(context, baseStyle)`, which calls `_getMergedStyleFromHierarchy`, which calls `_getAncestorOptions(context)` — a full `visitAncestorElements` tree walk — all over again. For a string with 5 different formatting types, that is 5 independent tree walks.

**Reasoning:**

`TextfStyleResolver` is constructed once per parse call and holds `context` and `_nearestOptions` as final fields. This makes it the ideal place to pre-compute all resolved styles in one pass.

**Solution:**

At construction time, walk the ancestor tree once (mirroring the logic in `computeResolvedHash`) and store resolved styles as final fields:

```dart
class TextfStyleResolver {
  TextfStyleResolver(this.context, TextStyle baseStyle)
      : _theme = Theme.of(context),
        _nearestOptions = TextfOptions.maybeOf(context) {
    // Single tree walk — resolve everything upfront
    final resolved = TextfOptions.resolveAll(context, baseStyle);
    _boldStyle = resolved.boldStyle;
    _italicStyle = resolved.italicStyle;
    // ... etc
  }

  late final TextStyle? _boldStyle;
  late final TextStyle? _italicStyle;
  // ...
}
```

Alternatively, add a `TextfOptions.resolveAll(context, baseStyle)` static method (similar to `computeResolvedHash`) that returns a data class with all resolved values in a single pass, and consume it in the resolver constructor.

This eliminates the O(Properties × Depth) complexity and replaces it with O(Depth) — matching what the hash computation already does.

---

## 🟡 Medium Priority — Code Quality & Consistency

---

### Task 4 — Remove dev-commentary from `link_handler.dart`

- [x] Replace stream-of-consciousness dev notes with a clean, factual code comment

> **Commit:** `refactor(link-handler): replace dev-time commentary with concise explanatory comment`

**File:** `lib/src/parsing/components/link_handler.dart`

**Problem:**

Production code contains internal debugging narration:

```dart
// Actually, token[1] is just "text" or tokens depending on tokenizer.
// Wait, the Tokenizer DOES NOT recursively tokenize inside [].
// RE-CHECKING TOKENIZER: The tokenizer emits ONE text token for the link content.
// So `tokens[index + _linkTextOffset]` will be TokenType.text even if it contains "{icon}".
// The LinkHandler THEN re-tokenizes that string.
// So this logic remains correct:
```

This reads like a commit-time scratchpad. The "Wait" and "RE-CHECKING" phrasing is inappropriate in shipped source code and may undermine confidence in the correctness of the logic.

**Reasoning:**

Comments should explain *why*, not narrate *how the author arrived at* the implementation. The useful insight here — that the tokenizer does not recurse into link text, so re-tokenization happens in `LinkHandler` — should be preserved, but cleanly stated.

**Solution:**

Replace with a concise explanatory comment:

```dart
// The outer tokenizer emits link text as a single TokenType.text token,
// even if it contains placeholders like "{icon}". LinkHandler re-tokenizes
// the link text internally to support nested formatting and placeholders.
```

---

### Task 5 — Replace inline magic number `2` with a named constant in `createScriptSpan`

- [x] Extract the padding multiplier `2` into a documented named constant

> **Commit:** `refactor(resolver): extract script padding multiplier into named constant`

**File:** `lib/src/styling/textf_style_resolver.dart`

**Problem:**

```dart
// ignore: no-magic-number
? EdgeInsets.only(bottom: offsetY.abs() * 2)
// ignore: no-magic-number
: EdgeInsets.only(top: offsetY.abs() * 2);
```

The `2` has a specific geometric meaning that is not obvious: when `PlaceholderAlignment.middle` is used, the widget is centered on the line, so to move it by `x` pixels visually, the padding must be `2x`. This knowledge lives only in a nearby code comment, not in the code itself. The `// ignore` suppression is also a signal that the constant should be extracted.

**Reasoning:**

Named constants serve as documentation at the point of use. Any future reader adjusting script positioning will understand immediately why the factor is 2 — not just that it is 2.

**Solution:**

```dart
// Padding is doubled because PlaceholderAlignment.middle centers the widget
// on the line baseline. To shift the visual center by `offsetY`, the padding
// on the corresponding side must be 2× the desired offset.
const double _scriptMiddleAlignmentPaddingFactor = 2.0;

// ...

final EdgeInsetsGeometry padding = isSuperscript
    ? EdgeInsets.only(bottom: offsetY.abs() * _scriptMiddleAlignmentPaddingFactor)
    : EdgeInsets.only(top: offsetY.abs() * _scriptMiddleAlignmentPaddingFactor);
```

This is a two-line change that eliminates both `// ignore` suppressions and makes the code self-documenting.

---

### Task 6 — Audit `computeResolvedHash` for property parity with `hasSameStyle`

- [ ] Verify that every property in `hasSameStyle` is also hashed in `computeResolvedHash`, and add a shared property list or test to enforce this going forward

> **Commit:** `fix(options): ensure computeResolvedHash covers all fields present in hasSameStyle`

**File:** `lib/src/widgets/textf_options.dart`

**Problem:**

`hasSameStyle` is used by `updateShouldNotify` to decide if the `InheritedWidget` should push updates. `computeResolvedHash` is used by `TextfRenderer` to decide if a re-parse is needed. Both enumerate all `TextfOptions` fields. They are separate implementations with no shared source of truth. If a new property is added (e.g., `highlightBorderRadius`), a developer updating `hasSameStyle` can easily forget to update `computeResolvedHash`, causing silent cache staleness: the renderer wouldn't notice the change and would serve outdated spans.

Specifically check: `strikethroughThickness` is explicitly in `hasSameStyle` — confirm it is included in `computeResolvedHash`'s hash computation.

**Reasoning:**

Two parallel implementations of "what are all the fields of this class" is a maintenance footgun. This has caused real bugs in other projects when one list grows and the other doesn't.

**Solution (preferred):** Extract a `_hashAllFields()` method that both `hasSameStyle` and `computeResolvedHash` delegate to, or use a single `hashCode` override on `TextfOptions`:

```dart
@override
int get hashCode => Object.hashAll([
  onLinkTap, onLinkHover, linkMouseCursor, linkStyle, linkAlignment,
  linkHoverStyle, boldStyle, italicStyle, boldItalicStyle,
  strikethroughStyle, strikethroughThickness, codeStyle,
  underlineStyle, highlightStyle, superscriptStyle, subscriptStyle,
  superscriptBaselineFactor, subscriptBaselineFactor, scriptFontSizeFactor,
]);

@override
bool operator ==(Object other) =>
    identical(this, other) ||
    (other is TextfOptions && other.hashCode == hashCode && hasSameStyle(other));
```

Then `computeResolvedHash` can use `options.hashCode` in its accumulation loop instead of re-enumerating fields.

**Solution (minimal):** Add a single `// SYNC WITH hasSameStyle` comment block above both methods, and add a unit test that creates a `TextfOptions` with every field set and asserts that `computeResolvedHash` changes when each individual field changes.

---

### Task 7 — Fix Javadoc-style doc comments in `nesting_validator.dart`

- [ ] Replace `@param`/`@return` Javadoc tags with standard Dart doc style

> **Commit:** `docs(nesting-validator): replace @param/@return Javadoc tags with Dart doc style`

**File:** `lib/src/parsing/components/nesting_validator.dart`

**Problem:**

```dart
/// @param tokens The list of tokens to validate
/// @param candidatePairs The initial pairs identified by the pairing resolver
/// @return A map of validated pairs with invalid ones removed
```

Dart's `dart doc` tool does not process Javadoc `@param` / `@return` tags. These will render on pub.dev as literal text (including the `@` signs) rather than being parsed as parameter documentation. The Dart documentation style uses `[paramName]` for inline references.

**Reasoning:**

This is a correctness issue for the API documentation that pub.dev users will read. Very good analysis (the linter you use) likely flags this too under the `comment_references` rule.

**Solution:**

```dart
// BEFORE
/// @param tokens The list of tokens to validate
/// @param candidatePairs The initial pairs identified by the pairing resolver
/// @return A map of validated pairs with invalid ones removed

// AFTER
/// - [tokens]: The list of tokens to validate.
/// - [candidatePairs]: The initial candidate pairs identified by [PairingResolver].
///
/// Returns a map of valid pairs with improperly nested or over-depth pairs removed.
```

---

### Task 8 — Remove commented-out dead code in `textf_style_resolver.dart`

- [ ] Delete the commented-out `textTheme` line, or convert to a proper `// TODO` with a GitHub issue reference

> **Commit:** `refactor(resolver): remove commented-out textTheme dead code`

**File:** `lib/src/styling/textf_style_resolver.dart`

**Problem:**

```dart
final Color codeBackgroundColor = colorScheme.surfaceContainer;
final Color codeForegroundColor = colorScheme.onSurfaceVariant;
// final TextTheme textTheme = _theme.textTheme; // Potentially use textTheme for font details
```

Commented-out code is ambiguous: it might be a work-in-progress, an abandoned idea, or something that broke. Readers can't tell which.

**Reasoning:**

If this is a future improvement, it belongs in a GitHub issue or a `// TODO(#issue): Consider using textTheme for font size details` comment. If it's abandoned, it should be deleted. Either way, the current form communicates nothing useful.

**Solution:**

Option A — if it's a planned improvement:

```dart
// TODO(#42): Consider also using theme.textTheme for font size/height defaults
// to better align with the host app's typography scale.
```

Option B — if it's just noise:

```dart
// Delete the line entirely.
```

---

## 🟢 Low Priority — Documentation & Housekeeping

---

### Task 9 — Update installation version in `README.md`

- [ ] Change `^1.1.0` to `^1.1.1` in the installation code block

> **Commit:** `docs(readme): update install snippet version to ^1.1.1`

**File:** `README.md`

**Problem:**

```yaml
# Current README
dependencies:
  textf: ^1.1.0
```

The package is at v1.1.1. New users copying the install snippet from the README will pin to `^1.1.0`, which technically resolves correctly due to semver, but it's imprecise and creates confusion when checking `pubspec.lock`.

**Solution:**

```yaml
dependencies:
  textf: ^1.1.1
```

One-line change. Should be updated automatically as part of the release checklist for every future version.

---

### Task 10 — Remove or fill the empty `## Next Release` section in `CHANGELOG.md`

- [ ] Delete the empty `## Next Release` heading, or document it as a future release placeholder with a placeholder entry

> **Commit:** `docs(changelog): remove empty Next Release section`

**File:** `CHANGELOG.md`

**Problem:**

```markdown
## Next Release

## 1.1.1
```

An empty `## Next Release` section above the current latest release looks like either a formatting error or an accidental leftover from pre-release editing. pub.dev renders the full CHANGELOG, so users will see this empty heading.

**Solution:**

If you maintain a `## Next Release` section as a development convention (to accumulate changes before tagging), that's fine — but add a placeholder so it's clearly intentional:

```markdown
## Next Release

_No changes yet._

## 1.1.1
```

Or remove it entirely until the next development cycle begins.

---

### Task 11 — Expand the `lib/textf.dart` library doc comment

- [x] Update the library-level dartdoc to mention both `Textf` and `TextfOptions`

> **Commit:** `docs(lib): expand library dartdoc to cover both Textf and TextfOptions exports`

**File:** `lib/textf.dart`

**Problem:**

```dart
/// A lightweight text widget library for simple inline formatting.
///
/// This library provides the Textf widget which supports basic
/// markdown-like formatting for text in Flutter applications.
library;

export 'src/widgets/textf.dart';
export 'src/widgets/textf_options.dart';
```

The library exports two public symbols — `Textf` and `TextfOptions` — but the doc comment only mentions `Textf`. Users discovering the package via `dart doc` or IDE quick-docs will not see that `TextfOptions` exists until they notice the export.

**Reasoning:**

The library doc is the first thing a developer reads when they hover over `import 'package:textf/textf.dart'` in their IDE. It should give a complete picture of the package's public surface.

**Solution:**

```dart
/// A lightweight text widget library for simple inline Markdown-like formatting.
///
/// ## Exports
///
/// - [Textf]: A drop-in replacement for Flutter's [Text] widget that supports
///   inline formatting markers for bold, italic, code, links, highlights,
///   superscript, subscript, and widget placeholders.
///
/// - [TextfOptions]: An [InheritedWidget] for configuring formatting styles,
///   link callbacks, and script geometry for all descendant [Textf] widgets.
///
/// ## Example
///
/// ```dart
/// import 'package:textf/textf.dart';
///
/// Textf('Hello **bold** *italic* `code` [link](https://example.com)');
/// ```
library;
```

---

Generated from Textf v1.1.1 codebase audit · February 2026
