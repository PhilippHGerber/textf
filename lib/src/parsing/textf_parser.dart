import 'package:flutter/material.dart';

import '../core/formatting_utils.dart';
import '../core/textf_limits.dart';
import '../models/parser_state.dart';
import '../models/textf_token.dart';
import '../styling/textf_style_resolver.dart';
import 'components/format_handler.dart';
import 'components/link_handler.dart';
import 'components/pairing_resolver.dart';
import 'components/placeholder_handler.dart';
import 'textf_tokenizer.dart';

/// Container for cached parsing results.
class _ParsedCacheEntry {
  _ParsedCacheEntry(this.tokens, this.matchingPairs);
  final List<TextfToken> tokens;
  final Map<int, int> matchingPairs;
}

/// Parser for formatted text that converts formatting markers into styled text spans.
///
/// The [TextfParser] processes tokenized text, identifies matching formatting markers,
/// handles nesting, resolves styling using `TextfStyleResolver` (considering options,
/// theme, and defaults), and generates properly styled [InlineSpan] objects for rendering.
///
/// Key features:
/// - Style resolution aware of TextfOptions and application Theme.
/// - Fast paths for empty or plain unformatted text.
/// - Handles nested formatting.
/// - Handles malformed formatting by treating unpaired markers as plain text.
/// - Escaped character support (handled by the tokenizer).
/// - Support for [link text](url) with nested formatting inside links.
/// - Support for widget placeholders via {key} syntax.
/// - Performance: Caches tokens and formatting pairs for frequently used text.
class TextfParser {
  /// Creates a new [TextfParser] instance.
  ///
  /// - [tokenizer]: An optional custom tokenizer instance. If not provided,
  ///   a default [TextfTokenizer] is created.
  TextfParser({
    TextfTokenizer? tokenizer,
  }) : _tokenizer = tokenizer ?? TextfTokenizer();

  /// TextfTokenizer instance used to break down text into tokens.
  final TextfTokenizer _tokenizer;

  /// Cache for tokens and pairing results.
  /// Uses a LinkedHashMap to implement a simple LRU cache.
  static final Map<String, _ParsedCacheEntry> _cache = <String, _ParsedCacheEntry>{};

  /// Clears the internal parser cache.
  ///
  /// Call this method to free memory in low-memory situations,
  /// or when navigating away from text-heavy screens.
  ///
  /// The cache will automatically rebuild as text is parsed.
  static void clearCache() {
    _cache.clear();
  }

  /// Parses formatted text into a list of styled [InlineSpan] objects.
  ///
  /// This method orchestrates the parsing process:
  /// 1. Handles fast paths for empty or plain text (text without any potential markers).
  /// 2. Tokenizes the input text using the configured [TextfTokenizer].
  /// 3. Creates a `TextfStyleResolver` using the provided `context` to handle style lookups.
  /// 4. Identifies matching, valid pairs of formatting markers (e.g., `*...*`) using `PairingResolver`.
  ///    This step ensures only correctly paired markers are considered for formatting.
  /// 5. Creates a `ParserState` to manage the parsing progress, including tokens, valid pairs,
  ///    the style resolver, the current text buffer, active style stack, and processed token indices.
  /// 6. Iterates through the tokens:
  ///    - Skips tokens that have already been processed (e.g., as part of a link or format pair).
  ///    - Appends plain text tokens ([TextToken]) to the `ParserState`'s text buffer.
  ///    - If a [LinkStartToken] is encountered, delegates processing to `LinkHandler`.
  ///    - If a [PlaceholderToken] is encountered, delegates to `PlaceholderHandler`.
  ///    - If a [FormatMarkerToken] is found, handles stack operations via `FormatHandler`.
  ///    - Treats any other unexpected token types encountered during the loop as plain text.
  /// 7. After iterating through all tokens, flushes any remaining text in the `ParserState`'s
  ///    buffer using the current style context via `state.flushText()`.
  /// 8. Returns the final list of generated [InlineSpan] objects from the `ParserState`.
  ///
  /// - [text]: The input string potentially containing formatting markers.
  /// - [context]: The current build context, required for theme and options lookup by the `TextfStyleResolver`.
  /// - [baseStyle]: The base text style to apply to unformatted text segments and as the foundation for styled segments.
  /// - [placeholders]: Optional map of spans to substitute into placeholders like `{icon}`.
  ///
  /// Returns a list of [InlineSpan] objects representing the styled text.
  List<InlineSpan> parse(
    String text,
    BuildContext context,
    TextStyle baseStyle, {
    TextScaler? textScaler,
    Map<String, InlineSpan>? placeholders,
  }) {
    // Fast path for empty text
    if (text.isEmpty) {
      return <InlineSpan>[];
    }

    // Fast path for plain text without formatting markers
    // Note: FormattingUtils.hasFormatting checks for *any* potential marker,
    // including unpaired ones, link syntax characters, or braces.
    if (!FormattingUtils.hasFormatting(text)) {
      // No potential formatting, return simple TextSpan list
      return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
    }

    // --- Cache Lookup & Update ---
    final List<TextfToken> tokens;
    final Map<int, int> validPairs;

    // Only attempt caching if the text length is within reasonable limits.
    // Extremely long strings are parsed on-demand to avoid memory issues.
    if (text.length <= TextfLimits.maxCacheKeyLength) {
      // Move to ends (most recent) if exists, or tokenize if miss.
      final cached = _cache.remove(text);

      if (cached != null) {
        tokens = cached.tokens;
        validPairs = cached.matchingPairs;
        // Re-insert to mark as recently used
        _cache[text] = cached;
      } else {
        // 1. Tokenize
        tokens = _tokenizer.tokenize(text);
        // 2. Pairing
        validPairs = PairingResolver.identifyPairs(tokens);

        // Update Cache (LRU: add to end)
        _cache[text] = _ParsedCacheEntry(tokens, validPairs);
        if (_cache.length > TextfLimits.maxCacheEntries) {
          // Remove the oldest entry (first key)
          _cache.remove(_cache.keys.first);
        }
      }
    } else {
      // Too long to cache, just process directly
      tokens = _tokenizer.tokenize(text);
      validPairs = PairingResolver.identifyPairs(tokens);
    }

    // 3. Style Resolver
    final resolver = TextfStyleResolver(context);

    // 4. State
    final state = ParserState(
      tokens: tokens,
      baseStyle: baseStyle,
      matchingPairs: validPairs,
      styleResolver: resolver,
      textScaler: textScaler,
      placeholders: placeholders,
    );

    // 5. Optimized Process Loop
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      // --- Placeholder Handling ---
      if (token is PlaceholderToken) {
        PlaceholderHandler.processPlaceholder(context, state, token);
        i++;
        continue;
      }

      // --- Link Handling ---
      if (token is LinkStartToken) {
        // Attempt to process a link.
        final int? nextIndex = LinkHandler.processLink(context, state, i);
        if (nextIndex != null) {
          // Success: The LinkHandler consumed tokens up to `nextIndex`.
          // We set i to `nextIndex` to continue from there.
          i = nextIndex;
          continue;
        }
        // Failure: Not a valid link. Fall through to process as plain text.
      }

      // --- Formatting Handling ---
      if (token is FormatMarkerToken) {
        if (state.matchingPairs.containsKey(i)) {
          // This token is part of a valid format pair.
          FormatHandler.processFormat(context, state, i, token);
          // Handled as a marker (either pushed to or popped from stack).
          // Do NOT add to text buffer.
          i++;
          continue;
        }
        // Unpaired or invalidly nested marker. Fall through to process as plain text.
      }

      // --- Plain Text Handling ---
      // Accumulate content into the buffer. This applies to:
      // 1. TextToken
      // 2. Unpaired/Invalid FormatMarkerTokens
      // 3. Broken/Partial Link tokens
      switch (token) {
        case TextToken(:final value):
          state.textBuffer.write(value);
        case FormatMarkerToken(:final value):
          state.textBuffer.write(value);
        case LinkStartToken():
          state.textBuffer.write('[');
        case LinkSeparatorToken():
          state.textBuffer.write('](');
        case LinkEndToken():
          state.textBuffer.write(')');
        case PlaceholderToken(:final key):
          state.textBuffer.write('{$key}');
      }
      i++;
    }

    // 6. Final Flush
    state.flushText(context);

    return state.spans;
  }
}
