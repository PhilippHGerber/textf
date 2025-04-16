import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/formatting_utils.dart';
import '../models/parser_state.dart';
import '../models/token.dart';
import '../styling/style_resolver.dart';
import 'components/format_handler.dart';
import 'components/link_handler.dart';
import 'components/pairing_resolver.dart';
import 'tokenizer.dart';

/// Parser for formatted text that converts formatting markers into styled text spans.
///
/// The [TextfParser] processes tokenized text, identifies matching formatting markers,
/// handles nesting, resolves styling using `TextfStyleResolver` (considering options,
/// theme, and defaults), and generates properly styled [InlineSpan] objects for rendering.
///
/// Key features:
/// - Result caching for performance optimization.
/// - Style resolution aware of TextfOptions and application Theme.
/// - Fast paths for plain unformatted text.
/// - Proper handling of nesting formatting (up to 2 levels deep).
/// - Robust error handling for malformed formatting.
/// - Escaped character support.
/// - Support for [link text](url) with nested formatting inside links.
class TextfParser {
  /// Maximum number of parsed results to cache for performance optimization.
  final int maxCacheSize;

  /// Cache for previously parsed text results to avoid redundant parsing.
  /// The key is a hash of the input text, base style, and generation counter (debug).
  final LinkedHashMap<int, List<InlineSpan>> _cache = LinkedHashMap<int, List<InlineSpan>>();

  /// TextfTokenizer instance used to break down text into tokens.
  final TextfTokenizer _tokenizer;

  /// A static generation counter that increases on every hot reload in debug mode.
  /// Used to invalidate the cache correctly when styles (especially theme) might change.
  static int _generation = 0;

  /// Increments the generation counter on hot reload.
  /// Called by `TextfRenderer.reassemble`.
  static void onHotReload() {
    if (kDebugMode) _generation++;
  }

  /// Creates a new [TextfParser] instance.
  ///
  /// - [maxCacheSize]: Controls how many parsed results are cached.
  /// - [tokenizer]: An optional custom tokenizer instance.
  TextfParser({
    this.maxCacheSize = 100,
    TextfTokenizer? tokenizer,
  }) : _tokenizer = tokenizer ?? TextfTokenizer();

  /// Parses formatted text into a list of styled [InlineSpan] objects.
  ///
  /// This method orchestrates the parsing process:
  /// 1. Checks for cached results.
  /// 2. Handles fast paths for empty or plain text.
  /// 3. Tokenizes the input text.
  /// 4. Creates a `TextfStyleResolver` using the provided `context`.
  /// 5. Identifies matching marker pairs using `PairingResolver`.
  /// 6. Creates a `ParserState` containing tokens, valid pairs, and the resolver.
  /// 7. Iterates through tokens:
  ///    - Appends plain text to buffer.
  ///    - Delegates valid link structures to `LinkHandler`.
  ///    - Delegates valid, paired formatting markers to `FormatHandler`.
  ///    - **Treats unpaired formatting markers as plain text.**
  /// 8. Flushes any remaining text using the resolver via `ParserState`.
  /// 9. Caches the resulting spans.
  ///
  /// - [text]: The input text with formatting markers.
  /// - [context]: The current build context, required for theme and options lookup by the resolver.
  /// - [baseStyle]: The base text style to apply to the text segments.
  ///
  /// Returns a list of [InlineSpan] objects with appropriate styling applied.
  List<InlineSpan> parse(
    String text,
    BuildContext context,
    TextStyle baseStyle,
  ) {
    // Fast path for empty text
    if (text.isEmpty) {
      return <InlineSpan>[];
    }

    // Fast path for plain text without formatting markers
    // Note: FormattingUtils.hasFormatting checks for *any* potential marker,
    // including unpaired ones or link syntax.
    if (!FormattingUtils.hasFormatting(text)) {
      // No potential formatting, return simple TextSpan list
      return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
    }

    // Cache lookup
    final cacheKey = _cacheKey(text, baseStyle);
    final cachedSpans = _cache[cacheKey];
    if (cachedSpans != null) {
      return cachedSpans;
    }

    // --- Main Parsing Logic ---

    // 1. Tokenize the input text
    final tokens = _tokenizer.tokenize(text);

    // 2. Create the Style Resolver using the current context
    final resolver = TextfStyleResolver(context);

    // 3. Identify matching *valid* pairs of formatting markers
    final validPairs = PairingResolver.identifyPairs(tokens);

    // 4. Create the ParserState, passing the resolver and only valid pairs
    final state = ParserState(
      tokens: tokens,
      baseStyle: baseStyle,
      matchingPairs: validPairs, // Use the validated pairs
      styleResolver: resolver,
    );

    // 5. Process tokens sequentially
    for (int i = 0; i < tokens.length; i++) {
      // Skip tokens already processed by handlers (e.g., inside a link or a valid pair)
      if (state.processedIndices.contains(i)) continue;

      final token = tokens[i];

      // --- Token Processing Logic ---
      if (token.type == TokenType.text) {
        // It's plain text, just append to the buffer
        state.textBuffer += token.value;
        // Mark as processed? Technically not needed as it doesn't affect stack,
        // but good practice if logic changes later.
        // state.processedIndices.add(i); // Optional for plain text
      } else if (token.type == TokenType.linkStart) {
        // It's a potential link start '['
        // Delegate link processing to LinkHandler
        final int? nextIndex = LinkHandler.processLink(context, state, i);
        if (nextIndex != null) {
          // LinkHandler successfully processed a full link `[...](...)`
          // It already marked all 5 tokens as processed.
          // Advance loop counter past the processed link.
          i = nextIndex - 1; // nextIndex is after ')', loop needs index of ')'
        } else {
          // LinkHandler determined it wasn't a valid link starting at 'i'.
          // It added '[' to the buffer and marked index 'i' as processed.
          // Loop continues normally to the next token.
        }
      }
      // Is it a formatting marker (bold, italic, code, strike)?
      else if (_isFormattingMarker(token.type)) {
        // Check if this specific marker instance is part of a *valid* pair
        if (state.matchingPairs.containsKey(i)) {
          // Yes, it's part of a valid pair (either opening or closing).
          // Delegate to FormatHandler to manage the stack and flush buffer.
          // FormatHandler will mark both this token and its pair as processed.
          FormatHandler.processFormat(context, state, i, token);
        } else {
          // No, this marker instance is *not* part of a valid pair (e.g., "**abc").
          // Treat its literal value as plain text.
          state.textBuffer += token.value;
          // Mark this specific token as processed so it doesn't get reconsidered.
          state.processedIndices.add(i);
        }
      }
      // Handle other potential token types (e.g., link components outside LinkHandler's scope,
      // although the current LinkHandler should handle all parts of a valid link).
      // If a token is not text, not linkStart, and not a formatting marker, what is it?
      // Potentially linkSeparator, linkUrl, linkEnd if LinkHandler logic failed,
      // or future token types. For now, treat unexpected types as text.
      else {
        // Fallback: Treat any other unexpected token type as plain text.
        state.textBuffer += token.value;
        state.processedIndices.add(i); // Mark as processed
      }
      // --- End Token Processing Logic ---
    }

    // 6. Flush any remaining text in the buffer after the loop finishes
    state.flushText(context);

    // 7. Cache the result
    final resultSpans = state.spans;
    if (maxCacheSize > 0) {
      if (_cache.length >= maxCacheSize) {
        // Maintain cache size limit
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = resultSpans;
    }

    return resultSpans;
  }

  /// Helper to check if a token type is a standard formatting marker.
  bool _isFormattingMarker(TokenType type) {
    return type == TokenType.boldMarker ||
        type == TokenType.italicMarker ||
        type == TokenType.boldItalicMarker ||
        type == TokenType.strikeMarker ||
        type == TokenType.codeMarker;
  }

  /// Generates a cache key based on text, style, and debug generation counter.
  int _cacheKey(String text, TextStyle style) {
    // Include generation counter in debug mode to handle hot reload style changes
    return kDebugMode ? Object.hash(text, style, _generation) : Object.hash(text, style);
  }

  /// Debugging utility to view the tokenization and pairing process.
  void debugPairingProcess(String text, BuildContext context, TextStyle baseStyle) {
    final tokens = _tokenizer.tokenize(text);
    // Get the *validated* pairs for debugging consistency
    final validPairs = PairingResolver.identifyPairs(tokens);

    debugPrint('--- TextfParser Debug ---');
    debugPrint('Input: "$text"');
    debugPrint('Tokens (${tokens.length}):');
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      // Indicate if the token is part of a valid pair
      final isPaired = validPairs.containsKey(i);
      final pairIndicator = isPaired ? " (Paired -> ${validPairs[i]})" : " (Unpaired)";
      debugPrint('  $i: ${token.type} (${token.position}, ${token.length}) $pairIndicator - "${token.value}"');
    }
    debugPrint('Valid Matching Pairs (${validPairs.length ~/ 2}):');
    final processedPairs = <int>{};
    validPairs.forEach((openIndex, closeIndex) {
      if (!processedPairs.contains(openIndex) && !processedPairs.contains(closeIndex)) {
        if (openIndex < closeIndex) {
          // Print only from the opening side
          final openToken = tokens[openIndex];
          final closeToken = tokens[closeIndex];
          debugPrint('  - ${openToken.type} ($openIndex:"${openToken.value}") -> ($closeIndex:"${closeToken.value}")');
          processedPairs.add(openIndex);
          processedPairs.add(closeIndex);
        }
      }
    });
    debugPrint('------------------------');
  }
}
