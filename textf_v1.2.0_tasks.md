# Textf v1.2.0 — Release Readiness Task List (Revised)

> Critical analysis of the full codebase (`llms.txt` snapshot, v1.1.2 base).
> Prioritised by release-blocking severity.
>
> **Revision note:** Six items from the initial analysis were invalidated after
> code-level verification. The original P0-2 (stored `BuildContext` in
> `TextfStyleResolver`) was downgraded to P3 after tracing that `buildTextSpan`
> is only invoked during `EditableTextState.build()`, guaranteeing the Element
> remains mounted and the ancestor walk produces correct results. See
> *Retracted Items* at the end for the full rationale.

---

## P1 — Performance (High impact, should fix for release)

### P1-1: `TextfSpanBuilder.build()` re-tokenizes and re-pairs on every cache miss

**Problem:** Unlike `TextfParser` which has a static LRU cache keyed by text
string, `TextfSpanBuilder` always calls `_tokenizer.tokenize()` and
`PairingResolver.identifyPairs()` fresh on every invocation. In the editing
controller path, this means every text change triggers full re-tokenization.

`TextfSpanBuilder` cannot reuse `TextfParser._cache` because it passes
`allowNewlineCrossing: false` to both the tokenizer and the pairing resolver,
producing different results from the display widget path.

The key insight is that cursor movement only changes marker visibility (not the
token/pair structure), so caching tokenize + pair results separately from the
final styled spans would yield a very high hit rate.

**Solution:** Add a parallel static LRU cache inside `TextfSpanBuilder` keyed
on the raw text string, storing `(tokens, validPairs)` tuples. Use the same
`TextfLimits.maxCacheEntries` and `TextfLimits.maxCacheKeyLength` bounds.
Also expose a `static void clearCache()` method and wire it into
`Textf.clearCache()`.

**Commit:** `perf(TextfSpanBuilder): add static LRU cache for tokenize and pairing results`

---

### P1-2: `computeOptionsResolvedHash` walks the full ancestor tree on every `TextfRendererState.build()`

**Problem:** In `TextfRendererState.build()`, the options hash is computed
**before** the cache check:

```dart
final int currentOptionsHash = TextfOptions.computeResolvedHash(context, currentBaseStyle);
```

`computeResolvedHash` → `getAncestorOptions(context)` →
`context.visitAncestorElements(...)`, which is O(TreeDepth). This runs on
every single build — including full cache hits where the result is discarded.

In contrast, `TextfEditingController.buildTextSpan()` uses an O(1) identity
comparison (`_lastNearestOptions == nearestOptions`) on the `TextfOptions?`
from `maybeOf`, and never computes the expensive hash at all. That's the right
pattern.

**Solution:** In `TextfRendererState`, check `TextfOptions` identity first.
Only fall through to the full hash computation if identity changed:

```dart
final TextfOptions? currentOptions = TextfOptions.maybeOf(context);
final bool optionsIdentityMatch = identical(_lastOptions, currentOptions);
final int currentOptionsHash = optionsIdentityMatch
    ? _lastOptionsHash
    : TextfOptions.computeResolvedHash(context, currentBaseStyle);
```

This makes the hot path (no options change) O(1) instead of O(Depth).

**Commit:** `perf(TextfRendererState): skip O(Depth) hash computation when TextfOptions identity unchanged`

---

### P1-3: `_processLinkAsText` re-tokenizes link text on every call

**Problem:** Inside `TextfSpanBuilder.build()`, each link encountered calls
`_tokenizer.tokenize(linkText)` on the inner link text for nested formatting
support. This is uncached and repeats on every cache miss for the parent text.

**Risk Assessment:** Medium — only affects texts with links. For link-heavy
content (reference sections, documentation), this multiplies the tokenization
cost.

**Solution:** If P1-1's span-level cache is implemented, the entire `build()`
output (including link processing) is cached for unchanged text. This becomes
a non-issue on the hot path. Flag for profiling follow-up only if link-heavy
texts show regressions.

**Commit:** `perf(TextfSpanBuilder): cache inner link text tokenization (follow-up to P1-1)`

---

## P2 — Robustness & Edge Cases (Should fix, not blocking)

### P2-1: No validation of `maxLiveFormattingLength` — allows negative values

**Problem:** The `maxLiveFormattingLength` setter accepts any `int`, including
zero and negative values. A negative value makes
`text.length > _maxLiveFormattingLength` always true, permanently disabling
formatting with no visible error. Zero disables formatting for all non-empty
text.

**Solution:** Add an assert in both the constructor and setter:

```dart
set maxLiveFormattingLength(int value) {
  assert(value > 0, 'maxLiveFormattingLength must be positive');
  if (_maxLiveFormattingLength == value) return;
  _maxLiveFormattingLength = value;
  notifyListeners();
}
```

**Commit:** `fix(TextfEditingController): assert maxLiveFormattingLength is positive`

---

### P2-2: `TextfParser._cache` lacks memory-aware eviction

**Problem:** Cache keys are raw text strings up to `maxCacheKeyLength` (1000
chars). Each entry stores the full token list and pair map. With 200 entries
at near-max key length, worst case is ~100K tokens + pair maps in memory.

LRU eviction fires on entry count only, not memory pressure. For a mobile app
with a long scrollable list of distinct `Textf` widgets, this could accumulate
non-trivially.

**Solution:** Consider adding a total-character-count budget alongside the
entry-count limit, or reducing `maxCacheKeyLength` for the editing controller
path (where strings change frequently). This is a tuning decision — profile
before changing defaults.

**Commit:** `perf(TextfParser): consider memory-aware cache eviction policy`

---

### P2-3: Composing underline uses manual decoration merge instead of shared utility

**Problem:** In `buildTextSpan` step 6, the composing underline is applied
with manual `TextDecoration.combine` logic that duplicates the same
decoration-merge pattern already handled by `mergeTextStyles()` in
`textf_style_utils.dart`.

```dart
if (existingDeco != null &&
    existingDeco != TextDecoration.none &&
    !existingDeco.contains(TextDecoration.underline)) {
  combined = TextDecoration.combine([existingDeco, TextDecoration.underline]);
}
```

This is the same merge logic, just inlined. Any future fix to the decoration
merge logic would need to be applied in two places.

**Solution:** Extract the composing underline application to use the shared
utility, or factor out the decoration-combining portion into a small helper
that both call.

**Commit:** `refactor(TextfEditingController): use shared decoration merge utility for composing underline`

---

### P2-4: Example project SDK constraint doesn't match main package

**Problem:** The `textf_editing_controller` example project declares
`environment: sdk: ^3.11.0`. The main package uses `sdk: >=3.5.0` /
`flutter: >=3.27.0`. Contributors cloning the example may hit SDK resolution
failures if they're on the stable channel matching the main package constraint.

**Solution:** Lower the example's SDK constraint to match or reasonably
approach the main package's minimum.

**Commit:** `chore(example): align SDK constraint with main package`

---

## P3 — API, Documentation & Future-Proofing

### P3-1: Duplicate import in `textf_limits.dart`

**Problem:** Two imports resolve to the same class:

```dart
import '../../textf.dart' show TextfEditingController;
import '../editing/textf_editing_controller.dart' show TextfEditingController;
```

The barrel export already re-exports the direct file. Redundant and some
linters flag it.

**Solution:** Remove one. Pick a convention (barrel vs. direct) and be
consistent across the codebase.

**Commit:** `chore(textf_limits): remove duplicate import`

---

### P3-2: No public API to strip formatting markers from text

**Problem:** Users who adopt `TextfEditingController` need a way to extract
clean text (markers stripped) for saving to a backend, building search indices,
character-count validation, notification previews, etc. Currently
`controller.text` returns raw text with markers (`**bold**`). There's no
built-in way to get `bold`.

**Solution:** Add a `String` extension as the primary API (mirrors the existing
`TextfExt.textf()` pattern), plus a convenience getter on the controller:

```dart
// String extension — works anywhere, no controller needed
extension TextfStringExt on String {
  String stripFormatting() => FormattingUtils.stripMarkers(this);
}

// Controller convenience getter
String get plainText => text.stripFormatting();
```

The implementation uses the existing tokenizer + `PairingResolver` to only
strip *valid paired* markers, leaving unpaired markers (like `*` in `2 * 3`)
untouched.

**Commit:** `feat: add stripFormatting extension and plainText getter`

---

### P3-3: `TextfSpanBuilder` and `TextfParser` have divergent link-validation logic

**Problem:** Both `TextfSpanBuilder._processLinkAsText` and
`LinkHandler._isCompleteLink` independently validate the 5-token link
structure. If link syntax rules change, both must be updated in lockstep.

**Solution:** Extract a shared `LinkValidator.isCompleteLink(tokens, index)`
static method usable by both paths.

**Commit:** `refactor(link): extract shared link structure validation`

---

### P3-4: Consider `MarkerVisibility` default via `TextfOptions`

**Problem:** `MarkerVisibility` is set per-controller. If a user wants all text
fields in their app to use `whenActive` mode, they must set it on every
controller. There's no way to configure an app-wide default via the widget
tree.

**Solution:** Add an optional `defaultMarkerVisibility` property to
`TextfOptions`. The controller's `buildTextSpan` would check
`TextfOptions.maybeOf(context)?.defaultMarkerVisibility` as a fallback when no
explicit value is set. This aligns with the existing `InheritedWidget` config
pattern.

**Commit:** `feat(TextfOptions): add defaultMarkerVisibility for app-wide controller defaults`

---

### P3-5: Demo `initText` contains preview disclaimer

**Problem:** The web demo's initial text says
`⚠️ *This is a preview — not released yet.*` — needs updating for the v1.2.0
release.

**Solution:** Remove or rephrase the preview warning.

**Commit:** `chore(example): update demo text for v1.2.0 release`

---

### P3-6: `TextfSpanBuilder.build()` is ~300 lines with 8 nested closures

**Problem:** The `build()` method defines `currentStyle`, `isScriptPreviewMode`,
`inScriptZone`, `inScriptPreviewZone`, `flushText`, `markerStyleForPair`,
`emitMarker`, and the link processing call — all as inner closures capturing
mutable local state. This makes the method hard to test in isolation and
fragile to modify.

**Solution:** Extract a `_SpanBuildState` mutable object (analogous to
`ParserState`) that holds the processing state and promotes the closures to
methods. Pure refactor, no behavioral change.

**Commit:** `refactor(TextfSpanBuilder): extract build state into dedicated class`

---

### P3-7: `TextfStyleResolver` stores `BuildContext` — defensive design smell

**Problem:** `TextfStyleResolver` stores `final BuildContext context` and the
controller caches the resolver instance across frames via `_cachedResolver`.
The stored context is from a previous `buildTextSpan` invocation.

**Why this is NOT a practical bug:** `buildTextSpan` is only called during
`EditableTextState.build()`. The context belongs to the same `Element`, which
is guaranteed mounted (otherwise `build()` wouldn't run). The cache
invalidation guards (`themeMatch`, `optionsMatch`) ensure a new resolver is
created whenever the tree changes in any way that affects style resolution. The
ancestor walk on the "stale" context produces identical results.

**Why it's still worth addressing:** Storing `BuildContext` as a field is
discouraged in Flutter's documentation. A future refactor could accidentally
use the cached resolver outside the build phase. Making the resolver
context-free eliminates this class of risk entirely.

**Solution (low priority):** Accept `ThemeData` and `TextfOptions?` directly
instead of `BuildContext`. The `getEffective...` methods on `TextfOptions`
already accept `context` as a parameter — they'd need to accept the resolver's
pre-resolved hierarchy instead. This is a non-trivial refactor touching
`TextfOptions`, `TextfStyleResolver`, and the resolver utilities.

**Commit:** `refactor(TextfStyleResolver): accept resolved theme/options instead of BuildContext`

---

## Summary

| Priority | Count | Description |
|----------|-------|-------------|
| **P1**   | 3     | Performance — missing span cache, redundant tree walks, link re-tokenization |
| **P2**   | 4     | Robustness — input validation, cache tuning, code dedup, example hygiene |
| **P3**   | 7     | API, docs, refactoring — `stripFormatting`, shared validators, demo text, design smell |
| **Total**| **14** | |

**No P0 correctness bugs found.** The codebase is in solid shape for release.

---

## Retracted Items

The following items from the initial analysis were removed after code-level
verification:

| Original ID | Title | Why Retracted |
|-------------|-------|---------------|
| P0-1 | `dispose()` override needed | Dart GC handles all instance fields when the controller becomes unreachable. Static `_spanBuilder` is stateless and holds no back-reference. Not a memory leak. |
| P0-3 | Composing WidgetSpan offset drift | The code correctly uses `span is TextSpan ? (span.text?.length ?? 0) : 1`, advancing by exactly 1 for WidgetSpans. Multi-byte emojis are already padded with `SizedBox.shrink` WidgetSpans by `TextfSpanBuilder`. No offset drift. |
| P0-4 | `_isSameTheme` misses `textTheme` | `TextfStyleResolver._getThemeBasedCodeStyle` does not use `textTheme` — it uses hardcoded `DefaultStyles.defaultCodeFontFamilyFallback`. The 4-property comparison covers exactly what's consumed. |
| P2-1 (orig) | Static `_spanBuilder` shared risk | Stateless static builder is the correct Dart pattern. Global-level cache bounding (if added) is architecturally superior to per-instance allocation. |
| P2-4 (orig) | `TextfOptions` identity check unsafe | `InheritedWidget` instances are immutable by contract. Configuration changes create new instances. Identity comparison is canonical and what Flutter itself relies on. |
| P3-6 (orig) | CHANGELOG missing v1.2.0 entry | The CHANGELOG already contains a comprehensive `## 1.2.0 (Unreleased)` section. Only needs the `(Unreleased)` tag removed at publish. |

---

## TODO

### P1 — Performance

- [x] **P1-1** · Add static LRU cache to `TextfSpanBuilder` for tokenize/pair results
- **P1-2** · rejected ❌ Invalid or Disputed Tasks
- [x] **P1-3** · Profile link-heavy texts after P1-1; cache inner link tokenization if needed

### P2 — Robustness

- **P2-1** · rejected ❌ Invalid or Disputed Tasks
- [x] **P2-2** · Evaluate memory-aware cache eviction for `TextfParser._cache`
- [x] **P2-3** · Replace manual composing decoration merge with shared `mergeTextStyles` utility
- [x] **P2-4** · Align example project SDK constraint with main package

### P3 — API, Docs & Refactoring

- [x] **P3-1** · Remove duplicate import in `textf_limits.dart`
- [x] **P3-2** · Add `stripFormatting()` String extension + `plainText` getter on controller
- [x] **P3-3** · Extract shared `LinkValidator.isCompleteLink()` for `TextfSpanBuilder` and `LinkHandler`
- [ ] **P3-4** · Add `defaultMarkerVisibility` to `TextfOptions`
- [ ] **P3-5** · Update demo `initText` to remove preview disclaimer
- [x] **P3-6** · Extract `_SpanBuildState` from `TextfSpanBuilder.build()` closures
- [x] **P3-7** · Make `TextfStyleResolver` context-free (accept `ThemeData` + `TextfOptions?` directly)

TODO Analyse all caches and how they work and find all possible problems and weeknes.
