import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/formatting_utils.dart';
import '../models/parser_state.dart';
import '../models/token.dart';
import '../widgets/textf_options.dart';
import 'components/format_handler.dart';
import 'components/link_handler.dart';
import 'components/pairing_resolver.dart';
import 'tokenizer.dart';

/// Parser for formatted text that converts formatting markers into styled text spans.
///
/// The [TextfParser] processes tokenized text to identify matching formatting markers,
/// handles nesting of different formats, and generates properly styled [InlineSpan]
/// objects for rendering.
///
/// Key features:
/// - Result caching for performance optimization
/// - Fast paths for plain unformatted text
/// - Proper handling of nesting formatting (up to 2 levels deep)
/// - Robust error handling for malformed formatting
/// - Escaped character support
/// - Support for [link text](url) with nested formatting inside links
///
/// For proper nesting of formatting, use different marker types:
/// - `**Bold with _italic_**` (correct)
/// - `**Bold with *italic***` (may not parse correctly)
///
/// This parser works in tandem with the [TextfTokenizer] class, which handles the initial
/// tokenization of the input text.
class TextfParser {
  /// Maximum number of parsed results to cache for performance optimization.
  final int maxCacheSize;

  /// Cache for previously parsed text results to avoid redundant parsing.
  ///
  /// The key is a hash of the input text and base style, and the value is
  /// the list of generated spans.
  final LinkedHashMap<int, List<InlineSpan>> _cache =
      LinkedHashMap<int, List<InlineSpan>>();

  /// TextfTokenizer instance used to break down text into tokens.
  final TextfTokenizer _tokenizer;

  /// Creates a new [TextfParser] instance.
  ///
  /// The [maxCacheSize] parameter controls how many parsed results are cached.
  /// Higher values consume more memory but can improve performance when
  /// parsing the same text multiple times.
  ///
  /// A custom [tokenizer] can be provided if specific tokenization behavior
  /// is needed.
  TextfParser({
    this.maxCacheSize = 100,
    TextfTokenizer? tokenizer,
  }) : _tokenizer = tokenizer ?? TextfTokenizer();

  /// Parses formatted text into a list of styled [InlineSpan] objects.
  ///
  /// This method:
  /// 1. Checks for cached results to avoid redundant parsing
  /// 2. Identifies fast paths for empty or plain text
  /// 3. Tokenizes the text into formatting markers and content
  /// 4. Processes tokens to generate appropriately styled spans
  /// 5. Caches the result for future use
  ///
  /// @param text The input text with formatting markers
  /// @param context The current build context
  /// @param baseStyle The base text style to apply to the text
  /// @return A list of spans with appropriate styling applied
  List<InlineSpan> parse(
    String text,
    BuildContext context,
    TextStyle baseStyle,
  ) {
    // Fast path for empty text
    if (text.isEmpty) {
      return <InlineSpan>[];
    }

    // Fast path for plain text without formatting
    if (!FormattingUtils.hasFormatting(text)) {
      return [TextSpan(text: text)];
    }

    // Cache lookup
    final cacheKey = _cacheKey(text, baseStyle);
    final cachedSpans = _cache[cacheKey];
    if (cachedSpans != null) {
      return cachedSpans;
    }

    // Tokenize the text
    final tokens = _tokenizer.tokenize(text);

    // Create parser state
    final state = _parseTokens(tokens, context, baseStyle);

    // Update cache
    if (_cache.length >= maxCacheSize) {
      // Remove oldest entry for simple FIFO behavior
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = state.spans;

    return state.spans;
  }

  /// Parses tokens and returns the resulting parser state with generated spans.
  ///
  /// This is the main parsing logic that processes tokens and generates spans.
  ParserState _parseTokens(
    List<Token> tokens,
    BuildContext context,
    TextStyle baseStyle,
  ) {
    // Get TextfOptions from context
    final textfOptions = TextfOptions.maybeOf(context);

    // Identify matching pairs
    final pairs = PairingResolver.identifyPairs(tokens);

    // Create parser state
    final state = ParserState(
      tokens: tokens,
      baseStyle: baseStyle,
      options: textfOptions,
      tokenizer: _tokenizer,
      matchingPairs: pairs,
    );

    // Process tokens in sequence
    for (int i = 0; i < tokens.length; i++) {
      // Skip tokens we've already processed
      if (state.processedIndices.contains(i)) continue;

      final token = tokens[i];

      if (token.type == TokenType.text) {
        // Regular text - add to buffer
        state.textBuffer += token.value;
      } else if (token.type == TokenType.linkStart) {
        // Handle link tokens
        final newIndex = LinkHandler.processLink(state, i);
        if (newIndex != null) {
          i = newIndex;
        }
      } else {
        // Handle formatting markers
        final newIndex = FormatHandler.processFormat(state, i, token);
        if (newIndex != null) {
          i = newIndex;
        }
      }
    }

    // Flush any remaining text
    state.flushText();

    return state;
  }

  /// Generates a cache key for the given text and style.
  ///
  /// The key is used to look up previously parsed results in the cache.
  int _cacheKey(String text, TextStyle style) {
    return Object.hash(text, style);
  }

  /// Debugging utility to view the pairing process for formatted text.
  ///
  /// This method provides information about how formatting markers
  /// are paired in the text, which can be useful for diagnosing
  /// formatting issues.
  ///
  /// @param text The text to analyze
  /// @param context The current build context
  /// @param baseStyle The base text style
  void debugPairingProcess(
    String text,
    BuildContext context,
    TextStyle baseStyle,
  ) {
    final tokens = _tokenizer.tokenize(text);
    final pairs = PairingResolver.identifyPairs(tokens);

    debugPrint('Input: "$text"');
    debugPrint('Tokens: ${tokens.length}');
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      debugPrint('  $i: ${token.type} - "${token.value}" (${token.position})');
    }
    debugPrint('Matching Pairs: ${pairs.length ~/ 2}');

    // Print each pair only once (for the opening marker)
    final processedPairs = <int>{};
    pairs.forEach((openIndex, closeIndex) {
      if (!processedPairs.contains(openIndex) &&
          !processedPairs.contains(closeIndex)) {
        final openToken = tokens[openIndex];
        final closeToken = tokens[closeIndex];
        debugPrint(
            '- ${openToken.type} at ${openToken.position} (index: $openIndex) matches ${closeToken.type} at ${closeToken.position} (index: $closeIndex)');
        processedPairs.add(openIndex);
        processedPairs.add(closeIndex);
      }
    });
  }
}
