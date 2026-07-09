import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatting_utils.dart';
import '../core/textf_token_cache.dart';
import '../models/format_stack_entry.dart';
import '../models/textf_token.dart';
import '../parsing/components/link_validator.dart';
import '../parsing/heading_region.dart';
import '../styling/textf_style_resolver.dart';

/// Builds a list of [InlineSpan] objects from formatted text.
///
/// Produces [TextSpan] children for most format types, and per-character
/// [WidgetSpan] children for superscript / subscript when in preview mode
/// (cursor outside the formatted span with markers fully hidden). This makes
/// it suitable for use inside [TextEditingController.buildTextSpan].
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
  TextfSpanBuilder();

  /// Near-zero font size for fully hidden markers.
  static const double _hiddenFontSize = 0.01;

  /// Multiplier for negative letterSpacing to collapse hidden marker width.
  static const double _hiddenLetterSpacingFactor = 2;

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

  /// Clears the shared token cache used by the builder.
  static void clearCache() => TextfTokenCache.clearCache();

  /// Builds a list of [InlineSpan] from formatted text.
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
    // Use the static LRU cache instead of executing a new tokenization pass
    final cacheEntry = TextfTokenCache.getTokensAndPairs(text, allowNewlineCrossing: false);
    final tokens = cacheEntry.tokens;
    final validPairs = cacheEntry.validPairs;

    final resolver = styleResolver ?? TextfStyleResolver(context);

    final activeMarkerStyle = _resolveMarkerStyle(baseStyle, context);
    final inactiveMarkerStyle = cursorPosition != null //
        ? _resolveHiddenMarkerStyle()
        : activeMarkerStyle;

    final state = _SpanBuildState(
      text: text,
      tokens: tokens,
      validPairs: validPairs,
      baseStyle: baseStyle,
      activeMarkerStyle: activeMarkerStyle,
      inactiveMarkerStyle: inactiveMarkerStyle,
      cursorPosition: cursorPosition,
      resolver: resolver,
    );

    return state.build();
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

  /// Returns `true` for superscript or subscript marker types.
  static bool _isScriptType(FormatMarkerType type) =>
      type == FormatMarkerType.superscript || type == FormatMarkerType.subscript;
}

/// Mutable state object for [TextfSpanBuilder.build].
///
/// Extracted to avoid multiple interacting closures allocating contexts and closure objects on the heap.
class _SpanBuildState with HeadingRegion {
  _SpanBuildState({
    required this.text,
    required this.tokens,
    required this.validPairs,
    required this.baseStyle,
    required this.activeMarkerStyle,
    required this.inactiveMarkerStyle,
    required this.cursorPosition,
    required this.resolver,
  });
  final String text;
  final List<TextfToken> tokens;
  final Map<int, int> validPairs;
  @override
  final TextStyle baseStyle;
  final TextStyle activeMarkerStyle;
  final TextStyle inactiveMarkerStyle;
  final int? cursorPosition;
  final TextfStyleResolver resolver;

  final List<InlineSpan> spans = <InlineSpan>[];
  @override
  final StringBuffer textBuffer = StringBuffer();
  @override
  final List<FormatStackEntry> formatStack = <FormatStackEntry>[];
  final Set<int> scriptPairs = <int>{};
  final Set<int> scriptPreviewPairs = <int>{};

  @override
  TextfStyleResolver get headingResolver => resolver;

  /// Main processing loop
  List<InlineSpan> build() {
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      // Placeholder Handling (render as literal text with braces)
      if (token is PlaceholderToken) {
        textBuffer
          ..write('{')
          ..write(token.key)
          ..write('}');
        i++;
        continue;
      }

      // Link Handling (render as styled text spans)
      if (token is LinkStartToken) {
        final int? nextIndex = processLinkAsText(i);
        if (nextIndex != null) {
          i = nextIndex;
          continue;
        }
        // Not a valid link — fall through to plain text.
      }

      // Heading Handling (line-prefix ATX marker, scoped to end of line)
      if (token is HeadingToken) {
        flushText();
        endHeading();
        beginHeading(token.level);
        // Slice the real opening-region characters (rather than assuming a
        // space-filled marker) so alternate separators like a tab are
        // preserved verbatim in the dimmed marker span.
        // ignore: avoid-substring
        final marker = text.substring(token.position, token.contentStart);
        emitMarker(marker, headingMarkerStyle(token));
        i++;
        continue;
      }

      // Heading suffix (trailing whitespace + optional closing `#` run):
      // dimmed-but-present, exactly like the opening run. The still-active
      // heading style is used as the marker root so the run matches the opening
      // run's size, and its slots are preserved verbatim.
      if (token is HeadingSuffixToken) {
        emitMarker(
          // ignore: avoid-substring
          text.substring(token.position, token.position + token.length),
          _headingLineMarkerStyle(token.headingStart, token.lineEndPosition),
        );
        i++;
        continue;
      }

      // Thematic-break Handling (whole-line construct: dimmed marker text).
      // The rule's raw `-`/`*`/`_` (plus any leading/inner/trailing whitespace)
      // stay visible as a single dimmed marker span — brightening to the active
      // marker style when the cursor is on the line — so every source character
      // keeps exactly one cursor slot. The read-only rule `WidgetSpan` is never
      // produced here.
      if (token is ThematicBreakToken) {
        final lineStart = token.position;
        final lineEnd = token.position + token.length;
        emitMarker(
          // ignore: avoid-substring
          text.substring(lineStart, lineEnd),
          _cursorOnLine(lineStart, lineEnd) ? activeMarkerStyle : inactiveMarkerStyle,
        );
        i++;
        continue;
      }

      // Formatting Marker Handling
      if (token is FormatMarkerToken) {
        if (validPairs.containsKey(i)) {
          final int matchingIndex = validPairs[i]!;

          if (matchingIndex > i) {
            // Opening marker.
            if (TextfSpanBuilder._isScriptType(token.markerType)) {
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

            // Compute resolved style at this stack depth for O(1) lookup.
            final TextStyle resolved = resolver.resolveStyle(token.markerType, currentStyle());

            formatStack.add(
              FormatStackEntry(
                index: i,
                matchingIndex: matchingIndex,
                type: token.markerType,
                resolvedStyle: resolved,
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
            } else if (TextfSpanBuilder._isScriptType(token.markerType)) {
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

      // Plain Text
      switch (token) {
        case TextToken(:final value):
          appendText(value);
        case FormatMarkerToken(:final value):
          textBuffer.write(value);
        case LinkStartToken():
          textBuffer.write('[');
        case LinkSeparatorToken():
          textBuffer.write('](');
        case LinkEndToken():
          textBuffer.write(')');
        case PlaceholderToken(:final key):
          textBuffer.write('{$key}');
        case HeadingToken(:final position, :final contentStart):
          // ignore: avoid-substring
          textBuffer.write(text.substring(position, contentStart));
        case HeadingSuffixToken(:final position, :final length):
          // Handled above (emitted as a dimmed marker); this defensive branch
          // keeps the slot count correct if ever reached.
          // ignore: avoid-substring
          textBuffer.write(text.substring(position, position + length));
        case ThematicBreakToken(:final position, :final length):
          // Handled above (emitted as a dimmed marker span); this defensive
          // branch keeps the slot count correct if ever reached.
          // ignore: avoid-substring
          textBuffer.write(text.substring(position, position + length));
        case EscapeMarkerToken():
          flushText();
          final TextStyle style;
          final pos = cursorPosition;
          style = pos != null
              ? pos >= token.position && pos <= token.position + 1
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

  /// Resolve the current effective style from the format stack.
  ///
  /// O(1) via cached [FormatStackEntry.resolvedStyle], falls back to
  /// walking the stack if entries lack cached styles.
  TextStyle currentStyle() {
    if (formatStack.isNotEmpty) return formatStack.last.resolvedStyle;
    return headingStyle ?? baseStyle;
  }

  /// Check whether a script pair's MARKERS should be hidden
  /// (preview mode). Content always uses WidgetSpan regardless.
  ///
  /// Preview mode activates when:
  ///  1. cursorPosition != null (MarkerVisibility.whenActive)
  ///  2. Cursor is outside[openPos, closeEnd]
  bool isScriptPreviewMode(int openIndex, int closeIndex) {
    final pos = cursorPosition;
    if (pos == null) return false;
    final openPos = tokens[openIndex].position;
    final closeEnd = tokens[closeIndex].position + tokens[closeIndex].length;
    return !(pos >= openPos && pos <= closeEnd);
  }

  /// True when the format stack contains ANY active script entry.
  bool inScriptZone() {
    return scriptPairs.isNotEmpty &&
        formatStack.any(
          (e) => TextfSpanBuilder._isScriptType(e.type) && scriptPairs.contains(e.index),
        );
  }

  /// True when the format stack contains a script entry in preview.
  bool inScriptPreviewZone() {
    return scriptPreviewPairs.isNotEmpty &&
        formatStack.any(
          (e) => TextfSpanBuilder._isScriptType(e.type) && scriptPreviewPairs.contains(e.index),
        );
  }

  /// Returns the active script [FormatStackEntry] if inside a script zone,
  /// or `null` otherwise. Single-pass replacement for `inScriptZone()` +
  /// `firstWhere()` which previously scanned the stack twice.
  FormatStackEntry? _findActiveScriptEntry() {
    if (scriptPairs.isEmpty) return null;
    for (final FormatStackEntry e in formatStack) {
      if (TextfSpanBuilder._isScriptType(e.type) && scriptPairs.contains(e.index)) {
        return e;
      }
    }
    return null;
  }

  /// Flush accumulated text buffer.
  ///
  /// When inside any script zone, emits one WidgetSpan per character with
  /// vertical displacement (via Padding + PlaceholderAlignment.middle). This
  /// makes super/subscript content appear correctly raised/lowered in all
  /// modes — always-visible markers, animating, and fully-hidden alike.
  /// Outside script zones, emits a single TextSpan as before.
  @override
  void flushText() {
    if (textBuffer.isEmpty) return;

    // Find the active script entry in a single pass instead of
    // calling inScriptZone() (which scans the stack) and then
    // firstWhere() (which scans it again with the same predicate).
    final FormatStackEntry? scriptEntry = _findActiveScriptEntry();

    if (scriptEntry != null) {
      final bool isSuperscript = scriptEntry.type == FormatMarkerType.superscript;
      final TextStyle style = currentStyle();
      final EdgeInsetsGeometry padding = resolver.resolveScriptPadding(
        style: style,
        isSuperscript: isSuperscript,
      );

      final String content = textBuffer.toString();

      // FAST PATH: Check if text is entirely simple (no combining marks, emojis, or surrogates).
      // Code units < 0x0300 cover ASCII and basic Latin-1, guaranteeing 1 code unit = 1 grapheme.
      bool isSimpleText = true;
      for (int i = 0; i < content.length; i++) {
        // ignore: no-magic-number, reason: Checking for combining marks and emojis which start at U+0300.
        if (content.codeUnitAt(i) >= 0x0300) {
          isSimpleText = false;
          break;
        }
      }

      if (isSimpleText) {
        // Bypass the expensive `characters` grapheme cluster iterator
        for (int i = 0; i < content.length; i++) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: padding,
                child: Text(
                  content[i],
                  style: style,
                  textScaler: TextScaler.noScaling,
                ),
              ),
            ),
          );
        }
      } else {
        // Slow path: Iterate over safe, visible characters (Grapheme Clusters)
        // This prevents splitting emojis (like 🚀 or 👨‍👩‍👧‍👦) in half.
        for (final String char in content.characters) {
          // 1. Emit the visible WidgetSpan for this character.
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

          // 2. CRITICAL TEXTFIELD INVARIANT FIX:
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
      }
    } else {
      spans.add(TextSpan(text: textBuffer.toString(), style: currentStyle()));
    }

    textBuffer.clear();
  }

  /// Resolve marker style based on cursor position relative to pair.
  TextStyle markerStyleForPair(int openIndex, int closeIndex) {
    final pos = cursorPosition;
    if (pos == null) return activeMarkerStyle;
    final openPos = tokens[openIndex].position;
    final closeEnd = tokens[closeIndex].position + tokens[closeIndex].length;
    if (pos >= openPos && pos <= closeEnd) {
      return activeMarkerStyle;
    }
    return inactiveMarkerStyle;
  }

  /// Resolve the heading marker style based on cursor position relative to the
  /// heading line.
  ///
  /// O(1): the line end is read directly from the token's back-patched
  /// [HeadingToken.lineEndPosition] — no per-heading forward token scan. The
  /// marker is shown active (heading-sized, active marker color) when the cursor
  /// is on the heading line, and inactive/dimmed otherwise (including the
  /// hide-all-markers selection path, where `cursorPosition` is < 0).
  TextStyle headingMarkerStyle(HeadingToken token) =>
      _headingLineMarkerStyle(token.position, token.lineEndPosition);

  /// Shared marker styling for a heading line's consumed regions (opening run
  /// and trailing suffix), keyed on whether the cursor sits on the line
  /// `[lineStart, lineEnd]`. Both regions share the heading style as their root
  /// so they render at the same size.
  TextStyle _headingLineMarkerStyle(int lineStart, int lineEnd) {
    if (_cursorOnLine(lineStart, lineEnd)) {
      return (headingStyle ?? baseStyle).copyWith(color: activeMarkerStyle.color);
    }
    return inactiveMarkerStyle;
  }

  /// Whether the cursor sits on the line `[lineStart, lineEnd]` (inclusive of
  /// both ends), or is absent. A `null` cursor means "show every marker
  /// dimmed-but-present", so it counts as on-line. Shared by the ATX-heading and
  /// thematic-break marker-styling paths — both key their active/inactive choice
  /// on this same O(1) line-membership test.
  bool _cursorOnLine(int lineStart, int lineEnd) {
    final pos = cursorPosition;
    if (pos == null) return true;
    return pos >= lineStart && pos <= lineEnd;
  }

  /// Flush text buffer and emit a marker span.
  ///
  /// When inside a script preview zone, inner markers (e.g. ** inside ^..^)
  /// become hidden WidgetSpans — one per marker character.
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

  /// Processes a link structure as styled [TextSpan]s.
  ///
  /// Returns the index after the link structure if valid, or `null` if the
  /// tokens at [index] do not form a complete `[text](url)` link.
  ///
  /// **Limitation:** Only plain-text link text is supported. The link text
  /// token must be a single [TextToken]. A link like `[*italic* text](url)`
  /// or `[text {placeholder}](url)` fails the completeness check and falls
  /// through to individual token rendering, producing garbled output with
  /// stray `[](` characters. Extend [LinkValidator.isCompleteLink] to fix this.
  int? processLinkAsText(int index) {
    // Verify complete link structure: [text](url)
    if (!LinkValidator.isCompleteLink(tokens, index)) {
      return null;
    }

    // Flush any preceding text with current formatting.
    flushText();

    final linkTextToken = tokens[index + kLinkTextOffset] as TextToken;
    final linkUrlToken = tokens[index + kLinkUrlOffset] as TextToken;
    final linkText = linkTextToken.value;
    final linkUrl = linkUrlToken.value;

    // Resolve link styling based on the current inherited style.
    final linkStyle = resolver.resolveLinkStyle(currentStyle());

    // Determine marker style based on cursor position.
    final TextStyle markerStyle;
    final pos = cursorPosition;
    if (pos != null) {
      final linkStart = tokens[index].position;
      final linkEnd =
          tokens[index + kLinkEndTokenOffset].position + tokens[index + kLinkEndTokenOffset].length;
      final cursorInside = pos >= linkStart && pos <= linkEnd;
      markerStyle = cursorInside ? activeMarkerStyle : inactiveMarkerStyle;
    } else {
      markerStyle = activeMarkerStyle;
    }

    // Emit opening bracket.
    spans.add(TextSpan(text: '[', style: markerStyle));

    // Process link text: fetch cached tokens and pairs to detect nested formatting markers.
    final entry = TextfTokenCache.getTokensAndPairs(linkText);
    final innerTokens = entry.tokens;
    final validPairsLink = entry.validPairs;

    final bool hasNested = innerTokens.any((t) => t is! TextToken);
    if (hasNested) {
      _processNestedLinkText(
        innerTokens: innerTokens,
        validPairs: validPairsLink,
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

    return index + kLinkTokenCount;
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
    final nestedFormatStack = <FormatStackEntry>[];
    final nestedTextBuffer = StringBuffer();

    TextStyle currentNestedStyle() {
      if (nestedFormatStack.isEmpty) return linkStyle;
      return nestedFormatStack.last.resolvedStyle;
    }

    void flushNestedBuffer() {
      if (nestedTextBuffer.isEmpty) return;
      spans.add(TextSpan(text: nestedTextBuffer.toString(), style: currentNestedStyle()));
      nestedTextBuffer.clear();
    }

    for (int i = 0; i < innerTokens.length; i++) {
      final token = innerTokens[i];

      if (token is TextToken) {
        nestedTextBuffer.write(token.value);
        continue;
      }

      if (token is FormatMarkerToken) {
        if (validPairs.containsKey(i)) {
          final int matchingIndex = validPairs[i]!;
          if (matchingIndex > i) {
            // Opening marker.
            flushNestedBuffer();
            spans.add(TextSpan(text: token.value, style: markerStyle));
            final TextStyle prevStyle = nestedFormatStack.isEmpty //
                ? linkStyle
                : nestedFormatStack.last.resolvedStyle;
            nestedFormatStack.add(
              FormatStackEntry(
                index: i,
                matchingIndex: matchingIndex,
                type: token.markerType,
                resolvedStyle: resolver.resolveStyle(token.markerType, prevStyle),
              ),
            );
          } else {
            // Closing marker.
            flushNestedBuffer();
            spans.add(TextSpan(text: token.value, style: markerStyle));
            assert(
              nestedFormatStack.isNotEmpty && nestedFormatStack.last.index == matchingIndex,
              'Closing marker does not match stack top — nesting validation failed',
            );
            if (nestedFormatStack.isNotEmpty) {
              nestedFormatStack.removeLast();
            }
          }
        } else {
          // Unpaired marker → literal text preserving the character slots.
          nestedTextBuffer.write(token.value);
        }
        continue;
      }

      if (token is PlaceholderToken) {
        // Placeholders inside link text are not substituted in the editing
        // controller — render literally to preserve character slots.
        nestedTextBuffer
          ..write('{')
          ..write(token.key)
          ..write('}');
        continue;
      }

      if (token is EscapeMarkerToken) {
        flushNestedBuffer();
        spans.add(TextSpan(text: r'\', style: markerStyle));
        continue;
      }
    }

    flushNestedBuffer();
  }
}
