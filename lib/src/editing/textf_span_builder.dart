import 'package:flutter/material.dart';

import '../core/formatting_utils.dart';
import '../core/textf_limits.dart';
import '../models/format_stack_entry.dart';
import '../models/textf_token.dart';
import '../parsing/components/pairing_resolver.dart';
import '../parsing/textf_tokenizer.dart';
import '../styling/textf_style_resolver.dart';

/// Container for cached tokenization and pairing results.
class _CacheEntry {
  _CacheEntry(this.tokens, this.matchingPairs);
  final List<TextfToken> tokens;
  final Map<int, int> matchingPairs;
}

/// Builds a list of [TextSpan] objects from formatted text.
///
/// Unlike `TextfParser`, which produces [InlineSpan] (including [WidgetSpan])
/// for use in read-only [Text.rich] widgets, this builder produces only
/// [TextSpan] children. This makes it suitable for use inside
/// [TextEditingController.buildTextSpan] where [WidgetSpan] is not supported.
///
/// **Critical invariant:** The total character count of all returned spans
/// always equals the length of the input text. This ensures 1:1
/// cursor-to-character mapping in text fields.
///
/// All characters — including formatting markers — are present in the output.
/// Markers are rendered with a dimmed style, while the content between them
/// gets the resolved formatting style.
///
/// Features that normally produce [WidgetSpan] are handled as follows:
///
/// - **Links** `[text](url)`: All characters visible. Link text gets link
///   styling; brackets, parens, and URL get a dimmed style.
/// - **Placeholders** `{key}`: Rendered as literal text (no substitution).
/// - **Super/subscript** `^text^` / `~text~`: Font size is reduced but no
///   vertical offset is applied (stays on baseline).
class TextfSpanBuilder {
  /// Creates a new [TextfSpanBuilder] instance.
  ///
  /// - [tokenizer]: An optional custom tokenizer instance. If not provided,
  ///   a default [TextfTokenizer] is created.
  TextfSpanBuilder({
    TextfTokenizer? tokenizer,
  }) : _tokenizer = tokenizer ?? TextfTokenizer();

  final TextfTokenizer _tokenizer;

  /// LRU cache for tokenization and pairing results.
  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};


  // Link token structure offsets (mirrors LinkHandler constants).
  static const int _linkTextOffset = 1;
  static const int _linkSeparatorOffset = 2;
  static const int _linkUrlOffset = 3;
  static const int _linkEndOffset = 4;
  static const int _linkTokenCount = 5;

  /// Opacity factor for dimmed marker characters.
  static const double _markerOpacity = 0.4;

  /// Near-zero font size for fully hidden markers.
  static const double _hiddenFontSize = 0.01;

  /// Multiplier for negative letterSpacing to collapse hidden marker width.
  static const double _hiddenLetterSpacingFactor = 2;

  /// Clears the internal span builder cache.
  ///
  /// Call this method to free memory in low-memory situations.
  /// The cache will automatically rebuild as text is parsed.
  static void clearCache() {
    _cache.clear();
  }

  /// Builds a list of [TextSpan] from formatted text.
  ///
  /// Every character in the input [text] appears in the output spans,
  /// ensuring 1:1 cursor-to-character mapping. Formatting markers are
  /// rendered with a dimmed style; content between markers is styled
  /// according to the formatting type.
  ///
  /// - [text]: Input string with formatting markers.
  /// - [context]: BuildContext for style resolution via [TextfStyleResolver].
  /// - [baseStyle]: Base style for unformatted text segments.
  /// - [cursorPosition]: When provided, enables smart-hide mode where markers
  ///   outside the cursor's formatted span are hidden. Pass `null` to show
  ///   all markers (default behavior).
  /// - [markerOpacity]: Controls the opacity of inactive markers during
  ///   animation. `1.0` means use the default dimmed style, `0.0` means
  ///   fully hidden (collapsed to near-zero font size).
  ///
  /// Returns a list of [TextSpan] objects.
  List<TextSpan> build(
    String text,
    BuildContext context,
    TextStyle baseStyle, {
    int? cursorPosition,
    double markerOpacity = 1.0,
  }) {
    // Fast path for empty text
    if (text.isEmpty) {
      return <TextSpan>[];
    }

    // Fast path for plain text without any potential formatting markers
    if (!FormattingUtils.hasFormatting(text)) {
      return <TextSpan>[TextSpan(text: text, style: baseStyle)];
    }

    // --- Cache Lookup & Update ---
    final List<TextfToken> tokens;
    final Map<int, int> validPairs;

    if (text.length <= TextfLimits.maxCacheKeyLength) {
      final cached = _cache.remove(text);

      if (cached != null) {
        tokens = cached.tokens;
        validPairs = cached.matchingPairs;
        _cache[text] = cached;
      } else {
        tokens = _tokenizer.tokenize(text);
        validPairs = PairingResolver.identifyPairs(tokens);

        _cache[text] = _CacheEntry(tokens, validPairs);
        if (_cache.length > TextfLimits.maxCacheEntries) {
          _cache.remove(_cache.keys.first);
        }
      }
    } else {
      tokens = _tokenizer.tokenize(text);
      validPairs = PairingResolver.identifyPairs(tokens);
    }

    // --- Style Resolution ---
    final resolver = TextfStyleResolver(context);

    // --- Marker styles ---
    final activeMarkerStyle = _resolveMarkerStyle(baseStyle);
    final inactiveMarkerStyle = cursorPosition != null
        ? _resolveInactiveMarkerStyle(baseStyle, markerOpacity)
        : activeMarkerStyle;

    // --- Processing State ---
    final List<TextSpan> spans = <TextSpan>[];
    final StringBuffer textBuffer = StringBuffer();
    final List<FormatStackEntry> formatStack = <FormatStackEntry>[];

    // Helper: resolve the current effective style from the format stack.
    TextStyle currentStyle() {
      if (formatStack.isEmpty) return baseStyle;
      TextStyle style = baseStyle;
      for (final FormatStackEntry entry in formatStack) {
        style = resolver.resolveStyle(entry.type, style);
      }
      return style;
    }

    // Helper: flush accumulated text buffer as a TextSpan.
    void flushText() {
      if (textBuffer.isEmpty) return;
      spans.add(TextSpan(text: textBuffer.toString(), style: currentStyle()));
      textBuffer.clear();
    }

    // Helper: resolve marker style based on cursor position relative to pair.
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
    void emitMarker(String markerText, TextStyle style) {
      flushText();
      spans.add(TextSpan(text: markerText, style: style));
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
            // Opening marker: emit marker, push format.
            final style = markerStyleForPair(i, matchingIndex);
            emitMarker(token.value, style);
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
            final style = markerStyleForPair(matchingIndex, i);
            int stackIndexToRemove = -1;
            for (int j = formatStack.length - 1; j >= 0; j--) {
              if (formatStack[j].index == matchingIndex) {
                stackIndexToRemove = j;
                break;
              }
            }
            if (stackIndexToRemove != -1) {
              formatStack.removeAt(stackIndexToRemove);
            }
            // Emit closing marker (after popping the format).
            spans.add(TextSpan(text: token.value, style: style));
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
        case PlaceholderToken(:final key):
          textBuffer.write('{$key}');
      }
      i++;
    }

    // Final flush
    flushText();

    return spans;
  }

  /// Creates a dimmed style for formatting markers.
  static TextStyle _resolveMarkerStyle(TextStyle baseStyle) {
    final effectiveColor = baseStyle.color;
    if (effectiveColor != null) {
      return baseStyle.copyWith(
        color: effectiveColor.withValues(alpha: _markerOpacity),
      );
    }
    return baseStyle.copyWith(
      color: const Color(0xFF000000).withValues(alpha: _markerOpacity),
    );
  }

  /// Creates a style for inactive markers based on [opacity].
  ///
  /// When [opacity] is `0.0`, markers are fully hidden with near-zero font
  /// size. When between `0.0` and `1.0`, markers fade with interpolated alpha
  /// at normal font size (paint-only change, no relayout).
  static TextStyle _resolveInactiveMarkerStyle(
    TextStyle baseStyle,
    double opacity,
  ) {
    if (opacity == 0.0) {
      // Fully hidden: collapse to near-zero size + transparent.
      // Negative letterSpacing collapses residual glyph advance widths,
      // preventing visible gaps when many characters are hidden (e.g. URLs).
      return baseStyle.copyWith(
        color: const Color(0x00000000),
        fontSize: _hiddenFontSize,
        letterSpacing: -_hiddenFontSize * _hiddenLetterSpacingFactor,
      );
    }
    // Animating: normal font size, interpolated alpha.
    final effectiveColor = baseStyle.color ?? const Color(0xFF000000);
    return baseStyle.copyWith(
      color: effectiveColor.withValues(alpha: opacity * _markerOpacity),
    );
  }

  /// Processes a link structure as styled [TextSpan]s.
  ///
  /// Returns the index after the link structure if valid, or `null` if the
  /// tokens at [index] do not form a complete `[text](url)` link.
  static int? _processLinkAsText({
    required List<TextfToken> tokens,
    required int index,
    required List<TextSpan> spans,
    required StringBuffer textBuffer,
    required TextStyle baseStyle,
    required TextStyle activeMarkerStyle,
    required TextStyle inactiveMarkerStyle,
    required int? cursorPosition,
    required TextfStyleResolver resolver,
    required TextStyle Function() currentStyle,
    required void Function() flushText,
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

    // Emit: [ + link text + ]( + url + )
    spans
      ..add(TextSpan(text: '[', style: markerStyle))
      ..add(TextSpan(text: linkText, style: linkStyle))
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
        tokens[index + _linkSeparatorOffset] is LinkSeparatorToken &&
        tokens[index + _linkUrlOffset] is TextToken &&
        tokens[index + _linkEndOffset] is LinkEndToken;
  }
}
