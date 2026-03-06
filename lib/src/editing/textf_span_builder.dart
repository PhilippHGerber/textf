import 'package:flutter/material.dart';

import '../core/formatting_utils.dart';
import '../core/textf_cache.dart';
import '../core/textf_limits.dart';
import '../models/format_stack_entry.dart';
import '../models/textf_token.dart';
import '../parsing/components/pairing_resolver.dart';
import '../parsing/textf_tokenizer.dart';
import '../styling/textf_style_resolver.dart';

/// Container for cached parsing results in the builder.
class _ParsedCacheEntry {
  const _ParsedCacheEntry(this.tokens, this.validPairs);
  final List<TextfToken> tokens;
  final Map<int, int> validPairs;
}

/// Cache key combining the text and newline crossing rule.
typedef _CacheKey = ({String text, bool allowNewlineCrossing});

/// Builds a list of [InlineSpan] objects from formatted text.
///
/// Produces [TextSpan] children for most format types, and per-character
/// [WidgetSpan] children for superscript / subscript when in preview mode
/// (cursor outside the formatted span with markers fully hidden). This makes
/// it suitable for use inside[TextEditingController.buildTextSpan].
///
/// **Critical invariant:** The total character-slot count of all returned
/// spans always equals the length of the input text. Each [TextSpan]
/// contributes its `text.length` slots; each [WidgetSpan] contributes
/// exactly 1 slot. This ensures 1:1 cursor-to-character mapping in text
/// fields.
///
/// All characters — including formatting markers — are present in the output.
/// Markers are rendered with a dimmed style, while the content between them
/// gets the resolved formatting style.
///
/// Features that normally produce [WidgetSpan] in the read-only widget are
/// handled as follows:
///
/// - **Links** `[text](url)`: All characters visible. Link text gets link
///   styling; brackets, parens, and URL get a dimmed style.
/// - **Placeholders** `{key}`: Rendered as literal text (no substitution).
/// - **Super/subscript** `^text^` / `~text~`: In preview mode (cursor
///   outside the span), each character gets its own [WidgetSpan] with
///   vertical displacement matching the read-only `Textf` widget. When
///   the cursor is inside the span, falls back to [TextSpan] with reduced
///   font size on the baseline.
///
class TextfSpanBuilder {
  /// Creates a new [TextfSpanBuilder] instance.
  ///
  /// - [tokenizer]: An optional custom tokenizer instance. If not provided,
  ///   a default[TextfTokenizer] is created.
  TextfSpanBuilder({
    TextfTokenizer? tokenizer,
  }) : _tokenizer = tokenizer ?? TextfTokenizer();

  /// Near-zero font size for fully hidden markers.
  static const double _hiddenFontSize = 0.01;

  /// Multiplier for negative letterSpacing to collapse hidden marker width.
  static const double _hiddenLetterSpacingFactor = 2;

  static const int _linkEndOffset = 4;
  static const int _linkSeparatorOffset = 2;
  // Link token structure offsets (mirrors LinkHandler constants).
  static const int _linkTextOffset = 1;

  static const int _linkTokenCount = 5;
  static const int _linkUrlOffset = 3;

  /// Opacity factor for dimmed marker characters.
  static const double _markerOpacity = 0.4;

  /// Sentinel value for [build]'s `cursorPosition` parameter that hides ALL
  /// formatting markers.
  ///
  /// When passed as `cursorPosition`, no marker will match (since token
  /// positions are always ≥ 0), causing every marker to receive the hidden
  /// style. Used by 'TextfEditingController' during text selection to prevent
  /// layout jumps on mobile.
  static const int hideAllMarkers = -1;

  final TextfTokenizer _tokenizer;

  /// Cache for tokens and pairing results.
  /// Uses a memory-aware LRU cache to prevent re-parsing identical text segments
  /// without causing memory bloat.
  static final TextfCache<_CacheKey, _ParsedCacheEntry> _cache =
      TextfCache<_CacheKey, _ParsedCacheEntry>(
    maxEntries: TextfLimits.maxCacheEntries,
    maxTotalChars: TextfLimits.maxCacheTotalCharacters,
    getCharCount: (key) => key.text.length,
  );

  /// Clears the internal builder cache.
  ///
  /// Call this method to free memory in low-memory situations.
  /// (Note: You should wire this into `Textf.clearCache()` as well).
  static void clearCache() {
    _cache.clear();
  }

  /// Tokenizes text and resolves pairs, using an LRU cache to prevent
  /// re-parsing identical text segments (Fixes P1-1, P1-3).
  _ParsedCacheEntry _getTokensAndPairs(String text, {required bool allowNewlineCrossing}) {
    // Too long to cache, just process directly
    if (text.length > TextfLimits.maxCacheKeyLength) {
      final tokens = _tokenizer.tokenize(text, allowNewlineCrossing: allowNewlineCrossing);
      final validPairs =
          PairingResolver.identifyPairs(tokens, allowNewlineCrossing: allowNewlineCrossing);
      return _ParsedCacheEntry(tokens, validPairs);
    }

    final key = (text: text, allowNewlineCrossing: allowNewlineCrossing);

    // The cache handles LRU promotion internally on get()
    final cached = _cache.get(key);

    if (cached != null) {
      return cached;
    }

    final tokens = _tokenizer.tokenize(text, allowNewlineCrossing: allowNewlineCrossing);
    final validPairs =
        PairingResolver.identifyPairs(tokens, allowNewlineCrossing: allowNewlineCrossing);
    final entry = _ParsedCacheEntry(tokens, validPairs);

    // Update Cache (LRU and memory eviction handled internally)
    _cache.set(key, entry);

    return entry;
  }

  /// Builds a list of[InlineSpan] from formatted text.
  ///
  /// Every character in the input[text] appears in the output spans,
  /// ensuring 1:1 cursor-to-character mapping. Formatting markers are
  /// rendered with a dimmed style; content between markers is styled
  /// according to the formatting type.
  ///
  /// - [text]: Input string with formatting markers.
  /// - [context]: BuildContext for style resolution via[TextfStyleResolver].
  /// - [baseStyle]: Base style for unformatted text segments.
  /// - [cursorPosition]: Controls marker visibility in smart-hide mode.
  ///   Pass `null` to show all markers with dimmed styling (default).
  ///   Pass a valid offset (≥ 0) to show markers only at that cursor
  ///   position. Pass [hideAllMarkers] (-1) to hide ALL markers — used
  ///   during text selection to prevent layout jumps on mobile.
  /// - [styleResolver]: Optional cached [TextfStyleResolver] to prevent
  ///   expensive re-creation on every frame.
  ///
  /// Returns a list of [InlineSpan] objects ([TextSpan] and[WidgetSpan]).
  List<InlineSpan> build(
    String text,
    BuildContext context,
    TextStyle baseStyle, {
    int? cursorPosition,
    TextfStyleResolver? styleResolver,
  }) {
    // Fast path for empty text
    if (text.isEmpty) {
      return <InlineSpan>[];
    }

    // Fast path for plain text without any potential formatting markers
    if (!FormattingUtils.hasFormatting(text)) {
      return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
    }

    final List<TextfToken> tokens;
    final Map<int, int> validPairs;

    // Use the static LRU cache instead of executing a new tokenization pass
    final cacheEntry = _getTokensAndPairs(text, allowNewlineCrossing: false);
    tokens = cacheEntry.tokens;
    validPairs = cacheEntry.validPairs;

    // --- Style Resolution ---
    final resolver = styleResolver ?? TextfStyleResolver(context);

    // --- Marker styles ---
    final activeMarkerStyle = _resolveMarkerStyle(baseStyle, context);
    final inactiveMarkerStyle = cursorPosition != null //
        ? _resolveHiddenMarkerStyle()
        : activeMarkerStyle;

    // --- Processing State ---
    final List<InlineSpan> spans = <InlineSpan>[];
    final StringBuffer textBuffer = StringBuffer();
    final List<FormatStackEntry> formatStack = <FormatStackEntry>[];

    // Tracks opening-marker indices of ALL active script pairs (super/sub).
    // Used by flushText to always emit per-character WidgetSpans with vertical
    // displacement, regardless of cursor position or markerOpacity.
    final Set<int> scriptPairs = <int>{};

    // Subset of scriptPairs whose markers are currently in preview mode
    // (cursor outside the span, markerOpacity <= 0). In preview mode the
    // markers themselves become hidden SizedBox.shrink WidgetSpans.
    final Set<int> scriptPreviewPairs = <int>{};

    // Helper: resolve the current effective style from the format stack.
    TextStyle currentStyle() {
      if (formatStack.isEmpty) return baseStyle;
      TextStyle style = baseStyle;
      for (final FormatStackEntry entry in formatStack) {
        style = resolver.resolveStyle(entry.type, style);
      }
      return style;
    }

    // Helper: check whether a script pair's MARKERS should be hidden
    // (preview mode). Content always uses WidgetSpan regardless.
    //
    // Preview mode activates when:
    //  1. cursorPosition != null (MarkerVisibility.whenActive)
    //  2. Cursor is outside[openPos, closeEnd]
    bool isScriptPreviewMode(int openIndex, int closeIndex) {
      if (cursorPosition == null) return false;
      final openPos = tokens[openIndex].position;
      final closeEnd = tokens[closeIndex].position + tokens[closeIndex].length;
      return !(cursorPosition >= openPos && cursorPosition <= closeEnd);
    }

    // Helper: true when the format stack contains ANY active script entry.
    // Used by flushText to always emit WidgetSpans for script content.
    bool inScriptZone() {
      return scriptPairs.isNotEmpty &&
          formatStack.any(
            (e) => _isScriptType(e.type) && scriptPairs.contains(e.index),
          );
    }

    // Helper: true when the format stack contains a script entry in preview.
    // Used by emitMarker to decide whether inner markers should be hidden.
    bool inScriptPreviewZone() {
      return scriptPreviewPairs.isNotEmpty &&
          formatStack.any(
            (e) => _isScriptType(e.type) && scriptPreviewPairs.contains(e.index),
          );
    }

    // Helper: flush accumulated text buffer.
    //
    // When inside any script zone, emits one WidgetSpan per character with
    // vertical displacement (via Padding + PlaceholderAlignment.middle). This
    // makes super/subscript content appear correctly raised/lowered in all
    // modes — always-visible markers, animating, and fully-hidden alike.
    // Outside script zones, emits a single TextSpan as before.
    void flushText() {
      if (textBuffer.isEmpty) return;

      if (inScriptZone()) {
        final scriptEntry = formatStack.firstWhere(
          (e) => _isScriptType(e.type) && scriptPairs.contains(e.index),
        );
        final bool isSuperscript = scriptEntry.type == FormatMarkerType.superscript;
        final TextStyle style = currentStyle();
        final EdgeInsetsGeometry padding = resolver.resolveScriptPadding(
          style: style,
          isSuperscript: isSuperscript,
        );

        final String content = textBuffer.toString();

        // 1. Iterate over safe, visible characters (Grapheme Clusters)
        // This prevents splitting emojis (like 🚀 or 👨‍👩‍👧‍👦) in half.
        for (final String char in content.characters) {
          // 2. Emit the visible WidgetSpan for this character.
          // In a TextField, every WidgetSpan counts as exactly ONE code unit.
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: padding,
                child: Text(
                  char,
                  style: style,
                  textScaler: TextScaler.noScaling,
                ),
              ),
            ),
          );

          // 3. CRITICAL TEXTFIELD INVARIANT FIX:
          // In Dart, `char.length` is the number of UTF-16 code units.
          // Standard characters have length 1. Emojis usually have length 2 or more.
          // If this character takes up 2 code units in the raw string, but we only
          // emitted 1 WidgetSpan, the TextField's cursor will misalign and crash.
          // We fix this by padding the span tree with completely hidden
          // WidgetSpans to make up the missing code unit length.
          for (int i = 1; i < char.length; i++) {
            spans.add(const WidgetSpan(child: SizedBox.shrink()));
          }
        }
      } else {
        spans.add(TextSpan(text: textBuffer.toString(), style: currentStyle()));
      }

      textBuffer.clear();
    } // Helper: resolve marker style based on cursor position relative to pair.

    TextStyle markerStyleForPair(int openIndex, int closeIndex) {
      if (cursorPosition == null) return activeMarkerStyle;
      final openPos = tokens[openIndex].position;
      final closeEnd = tokens[closeIndex].position + tokens[closeIndex].length;
      if (cursorPosition >= openPos && cursorPosition <= closeEnd) {
        return activeMarkerStyle;
      }
      return inactiveMarkerStyle;
    }

    // Helper: flush text buffer and emit a marker span.
    //
    // When inside a script preview zone, inner markers (e.g. ** inside ^..^)
    // become hidden WidgetSpans — one per marker character.
    void emitMarker(String markerText, TextStyle style) {
      flushText();
      if (inScriptPreviewZone()) {
        for (var c = 0; c < markerText.length; c++) {
          spans.add(const WidgetSpan(child: SizedBox.shrink()));
        }
      } else {
        spans.add(TextSpan(text: markerText, style: style));
      }
    }

    // --- Process Loop ---
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      // --- Placeholder Handling (render as literal text with braces) ---
      if (token is PlaceholderToken) {
        // The tokenizer stores only the key (e.g., "icon"), so we
        // reconstruct the original "{icon}" syntax for display.
        textBuffer
          ..write('{')
          ..write(token.key)
          ..write('}');
        i++;
        continue;
      }

      // --- Link Handling (render as styled text spans) ---
      if (token is LinkStartToken) {
        final int? nextIndex = _processLinkAsText(
          tokens: tokens,
          index: i,
          spans: spans,
          textBuffer: textBuffer,
          baseStyle: baseStyle,
          activeMarkerStyle: activeMarkerStyle,
          inactiveMarkerStyle: inactiveMarkerStyle,
          cursorPosition: cursorPosition,
          resolver: resolver,
          currentStyle: currentStyle,
          flushText: flushText,
          builder: this,
        );
        if (nextIndex != null) {
          i = nextIndex;
          continue;
        }
        // Not a valid link — fall through to plain text.
      }

      // --- Formatting Marker Handling ---
      if (token is FormatMarkerToken) {
        if (validPairs.containsKey(i)) {
          final int matchingIndex = validPairs[i]!;

          if (matchingIndex > i) {
            // Opening marker.
            if (_isScriptType(token.markerType)) {
              // Track this script pair so flushText emits WidgetSpans.
              scriptPairs.add(i);
              if (isScriptPreviewMode(i, matchingIndex)) {
                // Preview mode: hide the marker itself too.
                flushText();
                for (var c = 0; c < token.value.length; c++) {
                  spans.add(const WidgetSpan(child: SizedBox.shrink()));
                }
                scriptPreviewPairs.add(i);
              } else {
                // Visible marker TextSpan (edit mode or always-visible).
                final style = markerStyleForPair(i, matchingIndex);
                emitMarker(token.value, style);
              }
            } else {
              // Non-script opening marker: normal TextSpan.
              final style = markerStyleForPair(i, matchingIndex);
              emitMarker(token.value, style);
            }

            formatStack.add(
              FormatStackEntry(
                index: i,
                matchingIndex: matchingIndex,
                type: token.markerType,
              ),
            );
          } else {
            // Closing marker: flush formatted text, pop, emit marker.
            flushText();
            final bool isPreview = scriptPreviewPairs.contains(matchingIndex);

            assert(
              formatStack.isNotEmpty && formatStack.last.index == matchingIndex,
              'Closing marker does not match stack top — nesting validation failed',
            );
            if (formatStack.isNotEmpty) {
              formatStack.removeLast();
            }

            if (isPreview) {
              // Script preview: hidden WidgetSpan per marker char.
              for (var c = 0; c < token.value.length; c++) {
                spans.add(const WidgetSpan(child: SizedBox.shrink()));
              }
              scriptPreviewPairs.remove(matchingIndex);
              scriptPairs.remove(matchingIndex);
            } else if (_isScriptType(token.markerType)) {
              // Script closing marker (non-preview): visible TextSpan.
              final style = markerStyleForPair(matchingIndex, i);
              spans.add(TextSpan(text: token.value, style: style));
              scriptPairs.remove(matchingIndex);
            } else if (inScriptPreviewZone()) {
              // Non-script closing marker inside a script preview zone
              // (e.g. ** closing inside ^..^): emit hidden WidgetSpans.
              for (var c = 0; c < token.value.length; c++) {
                spans.add(const WidgetSpan(child: SizedBox.shrink()));
              }
            } else {
              // Normal: emit closing marker TextSpan.
              final style = markerStyleForPair(matchingIndex, i);
              spans.add(TextSpan(text: token.value, style: style));
            }
          }
          i++;
          continue;
        }
        // Unpaired marker — fall through to plain text.
      }

      // --- Plain Text ---
      switch (token) {
        case TextToken(:final value):
          textBuffer.write(value);
        case FormatMarkerToken(:final value):
          textBuffer.write(value);
        case LinkStartToken():
          textBuffer.write('[');
        case LinkSeparatorToken():
          textBuffer.write('](');
        case LinkEndToken():
          textBuffer.write(')');
        // Dead code: PlaceholderToken is handled before the switch
        // via the early `if` guard at the top of the loop. This case
        // exists only to satisfy Dart's exhaustive sealed-class switch.
        case PlaceholderToken(:final key):
          textBuffer.write('{$key}');
        case EscapeMarkerToken():
          flushText();
          final TextStyle style;
          // Smart-hide logic for the escape marker
          style = cursorPosition != null
              ? cursorPosition >= token.position && cursorPosition <= token.position + 1
                  ? activeMarkerStyle
                  : inactiveMarkerStyle
              : activeMarkerStyle;
          spans.add(TextSpan(text: r'\', style: style));
      }
      i++;
    }

    // Final flush
    flushText();

    return spans;
  }

  /// Creates a dimmed style for formatting markers.
  ///
  /// Falls back to `Theme.of(context).colorScheme.onSurface` when
  /// [baseStyle] carries no explicit color, ensuring correct appearance
  /// on both light and dark themes.
  TextStyle _resolveMarkerStyle(TextStyle baseStyle, BuildContext context) {
    final effectiveColor = baseStyle.color ?? Theme.of(context).colorScheme.onSurface;
    // Only carry color and fontSize from baseStyle. fontWeight, fontStyle,
    // and other typographic properties are intentionally reset so that markers
    // always appear as lightweight dim metadata, regardless of ambient style.
    return TextStyle(
      color: effectiveColor.withValues(alpha: _markerOpacity),
      fontSize: baseStyle.fontSize,
    );
  }

  /// Creates a fully-hidden style for inactive markers.
  ///
  /// Collapses markers to near-zero font size and transparent color.
  /// Negative letterSpacing collapses residual glyph advance widths,
  /// preventing visible gaps when many characters are hidden (e.g. URLs).
  TextStyle _resolveHiddenMarkerStyle() {
    return const TextStyle(
      color: Color(0x00000000),
      fontSize: _hiddenFontSize,
      letterSpacing: -_hiddenFontSize * _hiddenLetterSpacingFactor,
    );
  }

  /// Processes a link structure as styled [TextSpan]s.
  ///
  /// Returns the index after the link structure if valid, or `null` if the
  /// tokens at [index] do not form a complete `[text](url)` link.
  ///
  /// **Limitation:** Only plain-text link text is supported. The link text
  /// token must be a single [TextToken]. A link like `[*italic* text](url)`
  /// or `[text {placeholder}](url)` fails the completeness check and falls
  /// through to individual token rendering, producing garbled output with
  /// stray `[](` characters. Extend [_isCompleteLink] to fix this.
  static int? _processLinkAsText({
    required List<TextfToken> tokens,
    required int index,
    required List<InlineSpan> spans,
    required StringBuffer textBuffer,
    required TextStyle baseStyle,
    required TextStyle activeMarkerStyle,
    required TextStyle inactiveMarkerStyle,
    required int? cursorPosition,
    required TextfStyleResolver resolver,
    required TextStyle Function() currentStyle,
    required void Function() flushText,
    required TextfSpanBuilder builder,
  }) {
    // Verify complete link structure: [text](url)
    if (!_isCompleteLink(tokens, index)) {
      return null;
    }

    // Flush any preceding text with current formatting.
    flushText();

    final linkTextToken = tokens[index + _linkTextOffset] as TextToken;
    final linkUrlToken = tokens[index + _linkUrlOffset] as TextToken;
    final linkText = linkTextToken.value;
    final linkUrl = linkUrlToken.value;

    // Resolve link styling based on the current inherited style.
    final linkStyle = resolver.resolveLinkStyle(currentStyle());

    // Determine marker style based on cursor position.
    final TextStyle markerStyle;
    if (cursorPosition != null) {
      final linkStart = tokens[index].position;
      final linkEnd =
          tokens[index + _linkEndOffset].position + tokens[index + _linkEndOffset].length;
      final cursorInside = cursorPosition >= linkStart && cursorPosition <= linkEnd;
      markerStyle = cursorInside ? activeMarkerStyle : inactiveMarkerStyle;
    } else {
      markerStyle = activeMarkerStyle;
    }

    // Emit opening bracket.
    spans.add(TextSpan(text: '[', style: markerStyle));

    // Process link text: fetch cached tokens and pairs to detect nested formatting markers.
    final entry = builder._getTokensAndPairs(linkText, allowNewlineCrossing: true);
    final innerTokens = entry.tokens;
    final validPairs = entry.validPairs;

    final bool hasNested = innerTokens.any((t) => t is! TextToken);
    if (hasNested) {
      _processNestedLinkText(
        innerTokens: innerTokens,
        validPairs: validPairs,
        spans: spans,
        linkStyle: linkStyle,
        markerStyle: markerStyle,
        resolver: resolver,
      );
    } else {
      spans.add(TextSpan(text: linkText, style: linkStyle));
    }

    // Emit: ]( + url + )
    spans
      ..add(TextSpan(text: '](', style: markerStyle))
      ..add(TextSpan(text: linkUrl, style: markerStyle))
      ..add(TextSpan(text: ')', style: markerStyle));

    return index + _linkTokenCount;
  }

  /// Checks if tokens starting at [index] form a complete `[text](url)`.
  static bool _isCompleteLink(List<TextfToken> tokens, int index) {
    if (index + _linkEndOffset >= tokens.length) {
      return false;
    }

    return tokens[index] is LinkStartToken &&
        tokens[index + _linkTextOffset] is TextToken &&
        (tokens[index + _linkTextOffset] as TextToken).value.isNotEmpty &&
        tokens[index + _linkSeparatorOffset] is LinkSeparatorToken &&
        tokens[index + _linkUrlOffset] is TextToken &&
        tokens[index + _linkEndOffset] is LinkEndToken;
  }

  /// Emits styled [TextSpan]s for link text that contains nested format markers.
  ///
  /// Uses [linkStyle] as the base style, merging inner formatting on top.
  /// All format marker characters are emitted with [markerStyle] (the same
  /// dimmed/hidden style used for the outer link brackets).
  ///
  /// Maintains the character-slot invariant: every character in [innerTokens]
  /// appears exactly once in [spans].
  ///
  /// Super/subscript inside link text is intentionally unsupported — inner
  /// markers use [TextSpan] only (no[WidgetSpan] vertical displacement).
  static void _processNestedLinkText({
    required List<TextfToken> innerTokens,
    required Map<int, int> validPairs,
    required List<InlineSpan> spans,
    required TextStyle linkStyle,
    required TextStyle markerStyle,
    required TextfStyleResolver resolver,
  }) {
    final formatStack = <FormatStackEntry>[];
    final textBuffer = StringBuffer();

    TextStyle currentStyle() {
      if (formatStack.isEmpty) return linkStyle;
      var style = linkStyle;
      for (final FormatStackEntry entry in formatStack) {
        style = resolver.resolveStyle(entry.type, style);
      }
      return style;
    }

    void flushBuffer() {
      if (textBuffer.isEmpty) return;
      spans.add(TextSpan(text: textBuffer.toString(), style: currentStyle()));
      textBuffer.clear();
    }

    for (int i = 0; i < innerTokens.length; i++) {
      final token = innerTokens[i];

      if (token is TextToken) {
        textBuffer.write(token.value);
        continue;
      }

      if (token is FormatMarkerToken) {
        if (validPairs.containsKey(i)) {
          final int matchingIndex = validPairs[i]!;
          if (matchingIndex > i) {
            // Opening marker.
            flushBuffer();
            spans.add(TextSpan(text: token.value, style: markerStyle));
            formatStack.add(
              FormatStackEntry(
                index: i,
                matchingIndex: matchingIndex,
                type: token.markerType,
              ),
            );
          } else {
            // Closing marker.
            flushBuffer();
            spans.add(TextSpan(text: token.value, style: markerStyle));
            assert(
              formatStack.isNotEmpty && formatStack.last.index == matchingIndex,
              'Closing marker does not match stack top — nesting validation failed',
            );
            if (formatStack.isNotEmpty) {
              formatStack.removeLast();
            }
          }
        } else {
          // Unpaired marker → literal text preserving the character slots.
          textBuffer.write(token.value);
        }
        continue;
      }

      if (token is PlaceholderToken) {
        // Placeholders inside link text are not substituted in the editing
        // controller — render literally to preserve character slots.
        textBuffer
          ..write('{')
          ..write(token.key)
          ..write('}');
        continue;
      }

      if (token is EscapeMarkerToken) {
        flushBuffer();
        spans.add(TextSpan(text: r'\', style: markerStyle));
        continue;
      }
    }

    flushBuffer();
  }

  /// Returns `true` for superscript or subscript marker types.
  static bool _isScriptType(FormatMarkerType type) =>
      type == FormatMarkerType.superscript || type == FormatMarkerType.subscript;
}
