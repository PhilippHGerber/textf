# TextfEditingController — Critical Audit Task List

> **Package:** textf v1.2.0 (unreleased)
> **Scope:** `TextfEditingController`, `TextfSpanBuilder`, and their interactions with the parsing/pairing pipeline.
> **Audit date:** 2026-03-03
> **Source:** Full codebase analysis of `llms.txt` (v1.1.2 snapshot + v1.2.0 changelog)

---

## Priority Legend

| Priority | Meaning                                                                | Action                                 |
| -------- | ---------------------------------------------------------------------- | -------------------------------------- |
| **P0**   | Correctness bug or misleading behaviour that affects users now         | Fix before v1.2.0 release              |
| **P1**   | Performance issue that causes measurable degradation in real-world use | Fix before v1.2.0 or immediately after |
| **P2**   | Robustness gap or edge-case weakness                                   | Schedule for v1.2.x patch              |
| **P3**   | API design, DX, or future-proofing concern                             | Backlog / next minor                   |

---

## P0 — Correctness

### - [x] P0-1: `TextfSpanBuilder` documents an LRU cache that does not exist

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** Class-level dartdoc (~line 1440 in llms.txt)

**Reasoning:**
The class dartdoc states *"The internal LRU cache (`_cache`) is `static` and shared across all `TextfSpanBuilder` instances."* — but no `_cache` field exists anywhere in the class. Every `buildTextSpan()` invocation runs the full tokenize → pair → validate → build pipeline from scratch. This is both a documentation lie and a performance problem (see P1-1), but the documentation aspect alone is P0 because it misleads contributors into believing caching already exists and skipping optimisation work.

**Solution:**
Two-part fix:

1. **Immediate:** Remove or correct the dartdoc paragraph. Replace with an accurate statement that no caching is currently implemented and each call to `build()` performs a full re-parse.
2. **Follow-up (see P1-1):** Implement the actual cache.

**Commit message:**
```
docs(TextfSpanBuilder): remove incorrect LRU cache documentation

The class dartdoc referenced a `_cache` field that does not exist.
Every `build()` call performs a full re-parse. Corrected the
documentation to reflect the actual behaviour. Caching will be
added in a separate commit.
```

---

### - [x] P0-2: `_processNestedLinkText` allows cross-newline pairing inside link text

**File:** `lib/src/editing/textf_span_builder.dart` and `lib/src/parsing/textf_tokenizer.dart`

**Reasoning:**
The outer `build()` method explicitly passes `allowNewlineCrossing: false` to `PairingResolver.identifyPairs()` — this is a deliberate design decision for the editing controller where cross-line pairing is always accidental. However, links could cross newlines entirely, causing unexpected behavior and styling issues.

**Solution:**
This was addressed by extending `TextfTokenizer.tokenize` with an `allowNewlineCrossing` parameter (defaulting to `true` for display mode). When `TextfSpanBuilder` calls the tokenizer, it explicitly sets `allowNewlineCrossing: false`, strictly blocking any link syntax `[text](url)` from spanning multiple lines. Since links themselves can no longer span newlines in editing mode, the nested styling problem is inherently resolved without needing to pass the flag to the inner `PairingResolver.identifyPairs()` call.

**Commit message:**
```
fix(TextfTokenizer, TextfSpanBuilder): disable cross-newline links in edit mode

Extended Tokenizer with `allowNewlineCrossing` flag and enforced it
for TextfSpanBuilder to prevent links and their nested formatting
from awkwardly bridging across paragraphs.
```

---

### - [x] P0-3: Missing `continue` after `PlaceholderToken` in `_processNestedLinkText`

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** ~2022–2029 in llms.txt

**Reasoning:**
The token processing loop in `_processNestedLinkText` handles `PlaceholderToken` with an `if` block that writes `{key}` to the text buffer — but does not `continue` afterwards. Execution falls through to the subsequent `if (token is EscapeMarkerToken)` check.

Currently this is benign because a `PlaceholderToken` is never an `EscapeMarkerToken`, so the second `if` simply fails. However:

- It breaks the pattern established by every other token handler in the same loop (all use `continue`).
- If a new token subtype or handler is added below the `EscapeMarkerToken` block, the fallthrough will silently reach it.
- It signals a copy-paste oversight that undermines confidence in the surrounding code.

**Solution:**
Add `continue` after the placeholder handling block:

```dart
if (token is PlaceholderToken) {
  textBuffer
    ..write('{')
    ..write(token.key)
    ..write('}');
  continue; // ← Add this
}
```

**Commit message:**
```
fix(TextfSpanBuilder): add missing continue after PlaceholderToken in link text

The PlaceholderToken handler in _processNestedLinkText fell through
to the EscapeMarkerToken check instead of continuing to the next
token. No functional change in current code, but prevents future
fallthrough bugs and aligns with the pattern used by all other
token handlers in the same loop.
```

---

### - [ ] P0-4: IME composing underline is lost on super/subscript `WidgetSpan` content

**File:** `lib/src/editing/textf_editing_controller.dart`
**Lines:** ~1385–1388 in llms.txt (composing overlay loop, `WidgetSpan` branch)

**Reasoning:**
When the IME composing region overlaps content rendered as `WidgetSpan` (i.e., super/subscript text in any mode), the composing overlay loop passes the `WidgetSpan` through untouched. The `TextDecoration.underline` that indicates the active composition is never applied.

On Android and iOS with CJK input methods, this means the composition indicator simply vanishes when typing inside `^…^` or `~…~` spans. Users lose visual feedback about what text is being composed, which is a significant usability regression for CJK users.

**Solution:**
Wrap the `WidgetSpan`'s child in a `DecoratedBox` or `Container` with an underline-style bottom border when it falls within the composing region. This requires detecting the overlap and rebuilding the `WidgetSpan`:

```dart
} else if (span is WidgetSpan) {
  if (spanStart >= composing.start && spanEnd <= composing.end) {
    // Wrap in a container that shows composition underline
    children.add(
      WidgetSpan(
        alignment: span.alignment,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1),
            ),
          ),
          child: span.child,
        ),
      ),
    );
  } else {
    children.add(span);
  }
}
```

> **Note:** This is architecturally complex because the underline needs to match the system's IME styling. An alternative MVP approach is to document this as a known limitation and defer until WidgetSpan composition support is more broadly solved in the Flutter ecosystem.

**Commit message:**
```
fix(TextfEditingController): apply IME composing indicator to WidgetSpan content

WidgetSpans (used for super/subscript) were passed through untouched
in the composing overlay loop, causing the IME composition underline
to disappear on script-formatted text. Wrap affected WidgetSpans in
a Container with a bottom border to restore the visual indicator.
```

---

### - [x] P0-5: `mergeTextStyles` composing overlay relies on fragile merge-then-restore pattern

**File:** `lib/src/core/textf_style_utils.dart` (used by `textf_editing_controller.dart` ~line 1366)

**First create regression test** for this issue, and check if we need more tests to be sure not changing existing behavior

**Reasoning:**
When merging the composing `TextDecoration.underline` with an existing span style, the code calls `mergeTextStyles(spanStyle, composingStyle)`. Internally, this first calls `baseStyle.merge(optionsStyle)` (which replaces the decoration), then conditionally restores the original decoration via `copyWith`.

The round-trip `merge → copyWith` is correct today but depends on Flutter's `TextStyle.merge` always replacing (not combining) decorations. If a future Flutter version changes `merge` to combine decorations (which has been discussed in Flutter issues), the `contains` check would produce double-decorations.

**Solution:**
Replaced the fragile `mergeTextStyles` call in the composing overlay with a direct, explicit decoration combination that doesn't depend on the merge-then-restore pattern. Validated via new test `applies composing underline while preserving existing decoration`.

```dart
              // Use explicit TextDecoration combination to prevent fragile merge dependencies.
              final TextStyle mergedStyle;
              if (span.style case final TextStyle spanStyle?) {
                final TextDecoration combined;
                final existingDeco = spanStyle.decoration;
                if (existingDeco != null &&
                    existingDeco != TextDecoration.none &&
                    !existingDeco.contains(TextDecoration.underline)) {
                  combined = TextDecoration.combine([existingDeco, TextDecoration.underline]);
                } else if (existingDeco == null || existingDeco == TextDecoration.none) {
                  combined = TextDecoration.underline;
                } else {
                  combined = existingDeco; // Already contains underline
                }
                mergedStyle = spanStyle.copyWith(decoration: combined);
              } else {
                mergedStyle = composingStyle;
              }
```

**Commit message:**
```
fix(TextfEditingController): use explicit decoration merge for IME composing

Replaced the mergeTextStyles call in the composing overlay with
direct TextDecoration.combine logic. The previous approach relied
on TextStyle.merge replacing (not combining) decorations, then
restoring the original — a pattern that is correct today but
fragile against future Flutter changes.
```

---

## P1 — Performance

### - [x] P1-1: Full re-parse on every cursor blink frame (no span caching)

**File:** `lib/src/editing/textf_span_builder.dart`, `lib/src/editing/textf_editing_controller.dart`

**Reasoning:**
Flutter's `EditableText` calls `buildTextSpan()` on **every animation frame** while the text field is focused — approximately 60 calls per second just for the blinking cursor, even when no text changes.

Currently, each call runs the complete pipeline:
1. `TextfTokenizer.tokenize()` — O(N) string scan
2. `PairingResolver.identifyPairs()` — O(T) pairing + O(T × P) newline scan
3. `NestingValidator.validatePairs()` — O(T) validation
4. `TextfSpanBuilder.build()` — O(T) span construction with string allocations

For a 2000-character input with ~50 tokens, this means ~300 tokenizations per second, ~300 pairing passes, and ~300 span tree constructions — all producing identical output. The read-only `TextfRendererState` avoids this via its `_cachedSpans` / `_lastKey` memoisation; the editing controller has no equivalent.

**Solution:**
Add instance-level memoisation to `TextfEditingController`. Cache the `fullSpans` list, keyed on the inputs that affect the output:

```dart
// In TextfEditingController:
List<InlineSpan>? _cachedSpans;
String? _lastText;
int? _lastCursorPos;
MarkerVisibility? _lastVisibility;

// In buildTextSpan(), before calling _spanBuilder.build():
final int? cursorPos = /* existing resolution logic */;
if (_cachedSpans != null &&
    _lastText == text &&
    _lastCursorPos == cursorPos &&
    _lastVisibility == _markerVisibility) {
  fullSpans = _cachedSpans!;
} else {
  fullSpans = _spanBuilder.build(text, context, effectiveStyle, cursorPosition: cursorPos);
  _cachedSpans = fullSpans;
  _lastText = text;
  _lastCursorPos = cursorPos;
  _lastVisibility = _markerVisibility;
}
```

The composing overlay must still run on every call (composing region changes independently), but the expensive parsing step is eliminated for all blink frames.

> **Impact estimate:** Eliminates ~98% of redundant parse work during idle cursor blink. On a 2000-char input, this saves ~15ms of CPU time per second on a mid-range phone.

**Commit message:**
```
perf(TextfEditingController): add span caching to avoid re-parse on cursor blink

buildTextSpan is called ~60×/sec by EditableText for cursor blink
animation. Added instance-level memoisation keyed on (text,
cursorPosition, markerVisibility) to skip the full tokenize → pair
→ validate → build pipeline when inputs haven't changed. The
composing overlay still runs on every call as composing regions
change independently.
```

---

### - [x] P1-2: `TextfStyleResolver` is reconstructed on every `buildTextSpan` call

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** ~1524 in llms.txt

**Reasoning:**
`TextfStyleResolver(context)` is constructed inside `build()`, which triggers `Theme.of(context)` and `TextfOptions.maybeOf(context)` — both `InheritedWidget` lookups that walk up the element tree. While Flutter optimises these lookups, they still have non-zero cost and register dependencies that cause rebuild notifications.

The read-only `TextfRendererState` caches the theme reference and options hash across builds, only re-resolving when they change. The editing path does not.

**Solution:**
Cache the `TextfStyleResolver` (or its inputs: `ThemeData` + `TextfOptions?`) at the controller or span-builder level. Invalidate when the context's inherited widgets change:

```dart
// In TextfSpanBuilder or TextfEditingController:
TextfStyleResolver? _cachedResolver;
ThemeData? _lastTheme;
int? _lastOptionsHash;

TextfStyleResolver _getResolver(BuildContext context, TextStyle baseStyle) {
  final theme = Theme.of(context);
  final optionsHash = TextfOptions.computeResolvedHash(context, baseStyle);
  if (_cachedResolver != null &&
      _lastTheme == theme &&
      _lastOptionsHash == optionsHash) {
    return _cachedResolver!;
  }
  _cachedResolver = TextfStyleResolver(context);
  _lastTheme = theme;
  _lastOptionsHash = optionsHash;
  return _cachedResolver!;
}
```

> **Note:** Since `_spanBuilder` is `static`, this cache must live on the controller instance or be keyed per-context.

**Commit message:**
```
perf(TextfSpanBuilder): cache TextfStyleResolver across buildTextSpan calls

TextfStyleResolver was reconstructed on every buildTextSpan call,
triggering InheritedWidget lookups ~60×/sec during cursor blink.
Cache the resolver and invalidate only when Theme or TextfOptions
actually change.
```

---

### - [x] P1-3: Fresh `TextfTokenizer` allocated per link per frame

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** ~1914 in llms.txt

**Reasoning:**
`_processLinkAsText` creates a new `TextfTokenizer()` instance for every link encountered, on every `buildTextSpan()` call. The outer `_spanBuilder` reuses its `_tokenizer` field, but the inner link-text re-tokenisation path does not.

For text with 5 links and a focused cursor: 5 allocations × 60 frames/sec = 300 throwaway `TextfTokenizer` objects per second. While the GC handles this, it contributes to allocation pressure and minor GC pauses on lower-end devices.

**Solution:**
Reuse the `_spanBuilder`'s existing `_tokenizer` instance. Pass it as a parameter to `_processLinkAsText`, or make the method non-static and access `_tokenizer` directly:

```dart
// Change from:
final innerTokens = TextfTokenizer().tokenize(linkText);

// To:
final innerTokens = tokenizer.tokenize(linkText);
// Where `tokenizer` is passed from the caller or accessed via `this._tokenizer`
```

This requires making `_processLinkAsText` either non-static or adding a `tokenizer` parameter.

**Commit message:**
```
perf(TextfSpanBuilder): reuse tokenizer for link text re-tokenisation

_processLinkAsText allocated a new TextfTokenizer per link per
buildTextSpan call. Reuse the span builder's existing _tokenizer
instance to eliminate unnecessary allocations during cursor blink.
```

---

## P2 — Robustness & Edge Cases

### - [ ] P2-1: Hidden marker style relies on undocumented 0.01px font rendering

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** `_resolveHiddenMarkerStyle()` (~line 1851 in llms.txt)

**Reasoning:**
The "hidden" marker style uses `fontSize: 0.01` with `letterSpacing: -0.02` to collapse marker characters to near-zero visual width. This works empirically on Skia and Impeller backends, but is an **undocumented rendering assumption**:

- Web (HTML backend): The browser's minimum font size setting may clamp to a visible size.
- Web (CanvasKit): Subpixel rendering may produce faint but visible dots.
- Future engines: No guarantee that 0.01px will render identically.
- Accessibility: Screen readers may still announce the "hidden" text at normal cadence.

**Solution:**
Add a dartdoc comment documenting the platform assumption, and add a golden test that verifies the rendered width of hidden markers is < 1px on the target platform. For a more robust long-term approach, investigate using `Unicode zero-width space` (U+200B) as the marker text in hidden mode, or `fontSize: 0` if the engine supports it without assertion errors.

```dart
/// Creates a fully-hidden style for inactive markers.
///
/// **Platform assumption:** A font size of 0.01 with negative letter
/// spacing produces near-zero visual width on Skia and Impeller
/// backends. Verify on web/HTML backend if targeting browser deployment.
TextStyle _resolveHiddenMarkerStyle() { ... }
```

**Commit message:**
```
docs(TextfSpanBuilder): document platform assumption in hidden marker style

_resolveHiddenMarkerStyle relies on 0.01px font size producing
near-zero visual width. Added documentation noting this is a
platform-specific rendering assumption that should be verified
when targeting web/HTML backends.
```

---

### - [x] P2-3: `_isCompleteLink` does not validate non-empty link text

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** `_isCompleteLink()` (~line 1938 in llms.txt)

**Reasoning:**
The completeness check verifies token types but not content. An input like `[](https://example.com)` passes validation — the `TextToken` at the link-text position has `value: ""`. The code then emits `[`, an empty styled span, `](`, the URL, and `)`.

While this renders without crashing (the empty span is simply invisible), it produces a degenerate link structure that:

- Shows `[](url)` with marker styling where the `[]` are adjacent (looks like a rendering bug).
- In `MarkerVisibility.whenActive`, the empty content means the cursor can never be "inside" the link text, so the active zone only covers the URL portion.

**Solution:**
Add an empty-text guard to `_isCompleteLink`:

```dart
static bool _isCompleteLink(List<TextfToken> tokens, int index) {
  if (index + _linkEndOffset >= tokens.length) return false;

  return tokens[index] is LinkStartToken &&
      tokens[index + _linkTextOffset] is TextToken &&
      (tokens[index + _linkTextOffset] as TextToken).value.isNotEmpty && // ← Guard
      tokens[index + _linkSeparatorOffset] is LinkSeparatorToken &&
      tokens[index + _linkUrlOffset] is TextToken &&
      tokens[index + _linkEndOffset] is LinkEndToken;
}
```

Empty-text links will fall through to plain text rendering, showing `[](url)` as literal characters.

**Commit message:**
```
fix(TextfSpanBuilder): reject empty-text links in _isCompleteLink

[](url) passed the completeness check, producing a degenerate
link with adjacent [] markers and no visible content. Added a
non-empty guard on the link text token so empty links render as
literal text instead.
```

---

### - [x] P2-4: Format stack uses `List` with `removeAt` — violates stack abstraction

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** ~1752–1761 in llms.txt

**Reasoning:**
The `formatStack` is used as a stack (push on open, pop on close) but closing markers search the list linearly and remove at an arbitrary index via `removeAt(stackIndexToRemove)`. With the current max nesting depth of 2, this is always O(1) in practice. However:

- It breaks the LIFO invariant: after removing from the middle, entries above it shift down, so subsequent pops operate on a reordered stack.
- If `maxNestingDepth` increases, this becomes a correctness concern — the format stack order determines style resolution via `currentStyle()`.
- The linear search + `removeAt` pattern signals that the nesting may not always be well-ordered, which contradicts the assumption that `NestingValidator` guarantees proper nesting.

**Solution:**
If `NestingValidator` truly guarantees proper nesting (it should), then the closing marker should always match the top of the stack. Assert this and use `removeLast()`:

```dart
// Closing marker: expected to match stack top (nesting is validated).
assert(
  formatStack.isNotEmpty && formatStack.last.index == matchingIndex,
  'Closing marker does not match stack top — nesting validation failed',
);
formatStack.removeLast();
```

If there are legitimate cases where the closing marker doesn't match the top (e.g., overlapping markers that pass validation), the current linear search is correct but should be documented with a comment explaining why.

**Commit message:**
```
refactor(TextfSpanBuilder): assert stack-top match on closing marker

The format stack used linear search + removeAt for closing markers,
which breaks the LIFO invariant. Since NestingValidator guarantees
proper nesting, the closing marker should always match the stack
top. Added an assertion and simplified to removeLast().
```

---

## P3 — API Design & Future-Proofing

### - [ ] P3-1: Static `_spanBuilder` prevents per-controller customisation

**File:** `lib/src/editing/textf_editing_controller.dart`
**Lines:** ~1219 in llms.txt

**Reasoning:**
`TextfSpanBuilder` is declared as `static final` on the controller class. This means:

- All controller instances share one builder (and its tokenizer).
- There is no way to inject a custom `TextfSpanBuilder` or `TextfTokenizer` into a specific controller.
- The planned "custom formatting markers" feature would require users to subclass the controller or use a global tokenizer override.

**Solution:**
Make the builder instance-level with an optional constructor parameter, defaulting to a shared static instance for backward compatibility:

```dart
class TextfEditingController extends TextEditingController {
  TextfEditingController({
    super.text,
    MarkerVisibility markerVisibility = MarkerVisibility.always,
    int maxLiveFormattingLength = TextfLimits.maxLiveFormattingLength,
    TextfSpanBuilder? spanBuilder,
  })  : _markerVisibility = markerVisibility,
        _maxLiveFormattingLength = maxLiveFormattingLength,
        _spanBuilder = spanBuilder ?? _defaultSpanBuilder;

  static final TextfSpanBuilder _defaultSpanBuilder = TextfSpanBuilder();
  final TextfSpanBuilder _spanBuilder;
```

> **Note:** If P1-1 caching is implemented at the controller level, this change has no interaction. If caching is implemented inside `TextfSpanBuilder`, the static-to-instance migration changes cache sharing semantics.

**Commit message:**
```
refactor(TextfEditingController): make TextfSpanBuilder injectable

Changed _spanBuilder from static final to instance-level with a
default fallback. Enables future custom tokenizer/builder injection
without requiring controller subclassing. No behavioural change
for existing users.
```

---

### - [ ] P3-2: `maxLiveFormattingLength` circuit breaker causes abrupt visual jump

**File:** `lib/src/editing/textf_editing_controller.dart`
**Lines:** ~1281–1282 in llms.txt

**Reasoning:**
When text length crosses `maxLiveFormattingLength`, the circuit breaker instantly switches from fully-formatted `TextSpan` tree to `[TextSpan(text: text)]` — a single unformatted span. This causes:

1. **Visual jump:** All marker dimming, syntax coloring, and script formatting disappear in a single frame.
2. **No user feedback:** The user doesn't know formatting was disabled or why.
3. **Hysteresis gap:** If the user deletes one character to go back under the limit, formatting snaps back instantly, creating a flicker zone around the threshold.

**Solution:**
Two improvements:

**A. Hysteresis band** to prevent flicker at the boundary:
```dart
// Disable at maxLength, re-enable at maxLength - 200 (configurable)
static const int _hysteresisMargin = 200;
bool _formattingDisabled = false;

// In buildTextSpan:
if (text.length > _maxLiveFormattingLength) {
  _formattingDisabled = true;
} else if (text.length < _maxLiveFormattingLength - _hysteresisMargin) {
  _formattingDisabled = false;
}
```

**B. Notification callback** so the app can show a UI indicator:
```dart
/// Called when live formatting is enabled or disabled due to text
/// length crossing the [maxLiveFormattingLength] threshold.
final ValueChanged<bool>? onFormattingEnabledChanged;
```

**Commit message:**
```
feat(TextfEditingController): add hysteresis and callback for formatting threshold

The maxLiveFormattingLength circuit breaker caused an abrupt visual
jump when text crossed the threshold. Added a hysteresis margin to
prevent flicker at the boundary, and an onFormattingEnabledChanged
callback so apps can show a "formatting disabled" indicator.
```

---

### - [x] P3-3: `_hasNewlineBetween` causes O(T²) worst-case in pairing resolution

**File:** `lib/src/parsing/components/pairing_resolver.dart`
**Lines:** ~4668–4674 in llms.txt

**Reasoning:**
For each candidate pair, `_hasNewlineBetween` scans all tokens between the opener and closer looking for newlines in `TextToken` values. In the worst case — many markers with few actual pairs — this is O(T²) total across all pairs (each pair scans up to T tokens).

With the current `maxLiveFormattingLength` of 5000 characters and typical inline formatting density, T is usually < 100 and this is negligible. However, it's a latent performance cliff:

- A 5000-character input that is mostly formatting markers (e.g., `**a** **b** **c**` repeated) could produce ~1600 tokens.
- Pathological input could push pairing into visible stutter territory.

**Solution:**
Pre-compute a `Set<int>` of token indices that contain newlines in a single O(T) pass before the pairing loop. Then `_hasNewlineBetween` becomes a range check against the set:

```dart
// Pre-compute: O(T) single pass
final Set<int> newlineTokenIndices = {};
for (int i = 0; i < tokens.length; i++) {
  if (tokens[i] is TextToken && (tokens[i] as TextToken).value.contains('\n')) {
    newlineTokenIndices.add(i);
  }
}

// In _hasNewlineBetween: O(N) where N is newline count (usually tiny)
static bool _hasNewlineBetween(Set<int> newlineIndices, int open, int close) {
  return newlineIndices.any((i) => i > open && i < close);
}
```

> **Alternative:** Since newlines in typical chat inputs are rare, an even simpler approach is to find the min/max newline indices and do a range overlap check in O(1).

**Commit message:**
```
perf(PairingResolver): pre-compute newline positions for O(T) pairing

_hasNewlineBetween scanned all tokens between each candidate pair,
causing O(T²) worst-case for dense formatting inputs. Pre-compute
newline-containing token indices in a single pass, reducing the
newline check to a set lookup.
```

---

### - [ ] P3-4: Link text with nested formatting produces garbled output on partial structure

**File:** `lib/src/editing/textf_span_builder.dart`
**Lines:** `_processLinkAsText()` dartdoc (~line 1864 in llms.txt)

**Reasoning:**
The dartdoc for `_processLinkAsText` explicitly documents a known limitation:

> *"A link like `[*italic* text](url)` or `[text {placeholder}](url)` fails the completeness check and falls through to individual token rendering, producing garbled output with stray `[](` characters."*

This occurs because `_isCompleteLink` requires `tokens[index + 1]` to be a single `TextToken`. When the link text contains formatting, the tokenizer produces multiple tokens (e.g., `FormatMarkerToken` + `TextToken` + `FormatMarkerToken`), so the check fails.

The outer code then renders each link token individually — `[` as text, then the inner tokens, then `](` as text, then the URL as text, then `)` as text. The result is visually garbled.

**Solution:**
Extend `_isCompleteLink` to accept multi-token link text. Instead of requiring exactly one `TextToken` at position `index + 1`, check for a `LinkSeparatorToken` anywhere after the `LinkStartToken`:

```dart
static (bool isComplete, int separatorIndex, int endIndex)
    _findCompleteLinkStructure(List<TextfToken> tokens, int index) {
  if (tokens[index] is! LinkStartToken) return (false, -1, -1);

  // Scan forward for LinkSeparatorToken
  for (int i = index + 1; i < tokens.length; i++) {
    if (tokens[i] is LinkSeparatorToken) {
      // Check for TextToken (URL) + LinkEndToken after separator
      if (i + 2 < tokens.length &&
          tokens[i + 1] is TextToken &&
          tokens[i + 2] is LinkEndToken) {
        return (true, i, i + 2);
      }
      return (false, -1, -1);
    }
  }
  return (false, -1, -1);
}
```

> **Note:** This is a larger change that affects the link rendering pipeline. Consider whether v1.2.0 should ship with the current documented limitation or whether this warrants a fix.

**Commit message:**
```
fix(TextfSpanBuilder): support multi-token link text in editing controller

Links with nested formatting (e.g. [*italic* text](url)) failed
the completeness check and produced garbled output with stray
bracket characters. Extended _isCompleteLink to scan for the
LinkSeparatorToken instead of requiring a single TextToken,
enabling proper styled rendering of formatted link text.
```

---

## Cross-Cutting Concerns

### - [x] CC-1: Add integration test for `buildTextSpan` frame-budget compliance

**Reasoning:**
Several P1 items relate to per-frame performance. A benchmark test that calls `buildTextSpan` 60 times with varying input sizes and asserts total duration < 16ms (one frame budget) would catch future regressions and validate P1 fixes.

**Commit message:**
```
test(TextfEditingController): add frame-budget benchmark for buildTextSpan

Verify that 60 consecutive buildTextSpan calls complete within
one frame budget (16ms) for inputs up to maxLiveFormattingLength.
```

---

### - [ ] CC-2: Add regression tests for known P0 bugs before fixing

**Reasoning:**
Following the test-driven fix pattern: write failing tests that demonstrate each P0 bug before implementing the fix. This ensures the bugs are actually reproducible and prevents future regressions.

**Commit message:**
```
test(TextfEditingController): add failing tests for P0 editing controller bugs

Add test cases for cross-newline pairing in link text (P0-2),
PlaceholderToken fallthrough (P0-3), IME composing on WidgetSpan
(P0-4), and empty-text link handling (P2-3). All tests currently
fail and will pass after corresponding fixes.
```
