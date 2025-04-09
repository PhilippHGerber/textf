import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/token.dart';
import '../models/url_link_span.dart';
import '../widgets/textf_options.dart';
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

  /// Maximum formatting nesting depth allowed by the parser.
  ///
  /// This limits how many layers of formatting can be nested (e.g., bold text
  /// containing italic text would be 2 levels deep). Exceeding this will treat
  /// additional formatting markers as plain text.
  static const int maxDepth = 2;

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
    if (!_hasFormatting(text)) {
      return [TextSpan(text: text)];
    }

    // Cache lookup
    final cacheKey = _cacheKey(text, baseStyle);
    final cachedSpans = _cache[cacheKey];
    if (cachedSpans != null) {
      return cachedSpans;
    }

    // At this point, we know we have formatting and need to process it
    // Early TextfOptions retrieval is a sound optimization that reduces
    // computational overhead for formatted text
    final textfOptions = TextfOptions.maybeOf(context);

    // Tokenize the text
    final tokens = _tokenizer.tokenize(text);

    // Process tokens and generate spans using the span parser
    final spans = _createSpans(tokens, baseStyle, textfOptions);

    // Update cache
    // Uses a simple FIFO concept, as this is sufficient for this application.
    if (_cache.length >= maxCacheSize) {
      // Remove oldest entry for simple FIFO behavior
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = spans;

    return spans;
  }

  /// Creates spans from tokens using the span parser.
  ///
  /// This method creates a new SpanParser instance to process the tokens,
  /// providing proper isolation for parsing operations.
  ///
  /// @param tokens The tokens to process
  /// @param baseStyle The base text style to apply
  /// @param options The TextfOptions to use for styling, or null if not available
  /// @return A list of styled spans
  List<InlineSpan> _createSpans(
    List<Token> tokens,
    TextStyle baseStyle,
    TextfOptions? options,
  ) {
    // Create a span parser with these tokens and settings
    final parser = _SpanParser(
      tokens: tokens,
      baseStyle: baseStyle,
      options: options,
      tokenizer: _tokenizer,
    );

    // Generate the spans
    return parser.parse();
  }

  /// Quickly checks if text contains any potential formatting characters.
  ///
  /// This is an optimization to avoid the more expensive tokenization step
  /// for strings that definitely don't contain any formatting.
  bool _hasFormatting(String text) {
    for (int i = 0; i < text.length; i++) {
      final int char = text.codeUnitAt(i);
      if (char == kAsterisk || //
          char == kUnderscore ||
          char == kTilde ||
          char == kBacktick ||
          char == kEscape ||
          char == kOpenBracket ||
          char == kCloseBracket ||
          char == kOpenParen ||
          char == kCloseParen) {
        return true;
      }
    }
    return false;
  }

  /// Generates a cache key for the given text and style.
  ///
  /// The key is used to look up previously parsed results in the cache.
  int _cacheKey(String text, TextStyle style) {
    return Object.hash(text, style);
  }

  /// Normalizes a URL for consistent handling.
  ///
  /// Performs basic normalization like trimming whitespace and
  /// ensuring proper protocol prefixes for web URLs.
  String _normalizeUrl(String url) {
    // Trim whitespace
    url = url.trim();

    // Handle common URL patterns
    if (!url.contains(':') &&
        !url.startsWith('/') &&
        !url.startsWith('#') &&
        !url.startsWith('mailto:')) {
      // Look for domain-like patterns
      if (url.contains('.') || url.contains('localhost')) {
        return 'http://$url';
      }
    }

    return url;
  }

  /// Debugging utility to view the pairing process for formatted text.
  ///
  /// This method prints out information about how formatting markers
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
    final parser = _SpanParser(
      tokens: tokens,
      baseStyle: baseStyle,
      options: TextfOptions.maybeOf(context),
      tokenizer: _tokenizer,
    );
    final matchingPairs = parser.identifyMatchingPairs();

    print('Input: "$text"');
    print('Tokens: ${tokens.length}');
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      print('  $i: ${token.type} - "${token.value}" (${token.position})');
    }
    print('Matching Pairs: ${matchingPairs.length ~/ 2}');
    matchingPairs.forEach((openIndex, closeIndex) {
      if (openIndex < closeIndex) {
        // Only print once per pair
        final openToken = tokens[openIndex];
        final closeToken = tokens[closeIndex];
        print(
            '- ${openToken.type} at ${openToken.position} (index: $openIndex) matches ${closeToken.type} at ${closeToken.position} (index: $closeIndex)');
      }
    });
  }
}

/// Internal class that handles the span generation process.
///
/// This class encapsulates the state and logic for generating spans from tokens,
/// providing proper isolation for recursive parsing operations.
class _SpanParser {
  /// The tokens to parse
  final List<Token> tokens;

  /// The base text style to apply
  final TextStyle baseStyle;

  /// TextfOptions for styling, or null if not available
  final TextfOptions? options;

  /// Tokenizer for processing nested formatting
  final TextfTokenizer tokenizer;

  /// The spans generated by the parsing operation
  final List<InlineSpan> spans = [];

  /// Buffer for accumulating text between formatting markers
  String textBuffer = '';

  /// Stack of active formatting markers
  final List<_FormatStackEntry> formatStack = [];

  /// Set of token indices that have been processed
  final Set<int> processedIndices = {};

  /// Map of opening marker indices to their closing counterparts
  late final Map<int, int> matchingPairs;

  /// Creates a new span parser with the specified parameters.
  _SpanParser({
    required this.tokens,
    required this.baseStyle,
    required this.options,
    required this.tokenizer,
  }) {
    // Identify matching pairs of formatting markers
    matchingPairs = identifyMatchingPairs();
  }

  /// Parses the tokens and generates a list of spans.
  ///
  /// This method processes tokens sequentially, generating spans for
  /// text content, formatting markers, and links.
  List<InlineSpan> parse() {
    // Process tokens in sequence
    for (int i = 0; i < tokens.length; i++) {
      // Skip tokens we've already processed
      if (processedIndices.contains(i)) continue;

      final token = tokens[i];

      if (token.type == TokenType.text) {
        // Regular text - add to buffer
        handleTextToken(token);
      } else if (token.type == TokenType.linkStart) {
        // Handle link tokens
        final newIndex = handleLinkToken(i);
        if (newIndex != null) {
          i = newIndex;
        }
      } else {
        // Handle formatting markers
        final newIndex = handleFormattingToken(i, token);
        if (newIndex != null) {
          i = newIndex;
        }
      }
    }

    // Flush any remaining text
    flushText();

    return spans;
  }

  /// Handles a text token by adding it to the text buffer.
  void handleTextToken(Token token) {
    textBuffer += token.value;
  }

  /// Handles a link token by creating a UrlLinkSpan.
  ///
  /// @param index The current token index
  /// @return The new token index after processing, or null if no index change
  int? handleLinkToken(int index) {
    // Flush any existing text
    flushText();

    // Check if we have a complete link structure
    if (index + 4 < tokens.length &&
        tokens[index + 1].type == TokenType.text &&
        tokens[index + 2].type == TokenType.linkSeparator &&
        tokens[index + 3].type == TokenType.text &&
        tokens[index + 4].type == TokenType.linkEnd) {
      final String linkText = tokens[index + 1].value;
      final String linkUrl = tokens[index + 3].value;
      final String normalizedUrl = normalizeUrl(linkUrl);

      // Get link style from TextfOptions
      final TextStyle urlStyle = options?.getEffectiveUrlStyle(baseStyle) ??
          TextfOptions.defaultUrlStyle.merge(baseStyle);

      // Check if link text contains formatting markers
      if (hasFormatting(linkText)) {
        // Handle formatting within link text using a separate parser
        final List<Token> linkTextTokens = tokenizer.tokenize(linkText);

        // Create a separate parser for the link text
        final _SpanParser linkParser = _SpanParser(
          tokens: linkTextTokens,
          baseStyle: urlStyle, // Use link style as the base style
          options: options,
          tokenizer: tokenizer,
        );

        // Parse the link text
        final List<InlineSpan> formattedLinkSpans = linkParser.parse();

        // Add a UrlLinkSpan with children
        spans.add(
          UrlLinkSpan(
            url: normalizedUrl,
            text: '', // Empty because we're using children
            style: urlStyle,
            children: formattedLinkSpans,
          ),
        );
      } else {
        // No formatting in link text, use simple approach
        spans.add(
          UrlLinkSpan(
            url: normalizedUrl,
            text: linkText,
            style: urlStyle,
          ),
        );
      }

      // Mark all link tokens as processed
      processedIndices.add(index);
      processedIndices.add(index + 1);
      processedIndices.add(index + 2);
      processedIndices.add(index + 3);
      processedIndices.add(index + 4);

      return index + 4; // Skip to after the link
    } else {
      // Malformed link, treat as text
      textBuffer += tokens[index].value;
      return null;
    }
  }

  /// Handles a formatting token.
  ///
  /// @param index The current token index
  /// @param token The token to process
  /// @return The new token index after processing, or null if no index change
  int? handleFormattingToken(int index, Token token) {
    final matchingIndex = matchingPairs[index];
    if (matchingIndex != null) {
      // This is a formatting marker with a matching pair
      if (matchingIndex > index) {
        // This is an opening marker
        // Add any accumulated text before we start this formatting
        flushText();

        // Push onto the format stack
        formatStack.add(
          _FormatStackEntry(
            index: index,
            matchingIndex: matchingIndex,
            type: token.type,
          ),
        );

        // Mark as processed
        processedIndices.add(index);
      } else {
        // This is a closing marker - its opening marker should have been processed

        // Mark as processed
        processedIndices.add(index);

        // Find and remove the matching entry from the format stack
        int stackIndex = -1;
        for (int j = formatStack.length - 1; j >= 0; j--) {
          if (formatStack[j].index == matchingIndex) {
            stackIndex = j;
            break;
          }
        }

        if (stackIndex != -1) {
          // First flush the text with formatting still applied
          flushText();

          // Then remove the entry from the stack
          formatStack.removeAt(stackIndex);
        } else {
          // No matching format found, just flush text
          flushText();
        }
      }
    } else {
      // Unpaired marker, treat as text
      textBuffer += token.value;
    }

    return null;
  }

  /// Flushes the accumulated text with the current formatting applied.
  void flushText() {
    if (textBuffer.isEmpty) return;

    // Calculate current style based on format stack
    var style = baseStyle;
    for (final entry in formatStack) {
      style = applyStyle(style, entry.type);
    }

    spans.add(TextSpan(text: textBuffer, style: style));
    textBuffer = '';
  }

  /// Applies the appropriate style for a formatting marker.
  TextStyle applyStyle(TextStyle style, TokenType markerType) {
    switch (markerType) {
      case TokenType.boldMarker:
        return options?.getEffectiveBoldStyle(style) ??
            TextfOptions.defaultBoldStyle(style);
      case TokenType.italicMarker:
        return options?.getEffectiveItalicStyle(style) ??
            TextfOptions.defaultItalicStyle(style);
      case TokenType.boldItalicMarker:
        return options?.getEffectiveBoldItalicStyle(style) ??
            TextfOptions.defaultBoldItalicStyle(style);
      case TokenType.strikeMarker:
        return options?.getEffectiveStrikethroughStyle(style) ??
            TextfOptions.defaultStrikethroughStyle(style);
      case TokenType.codeMarker:
        return options?.getEffectiveCodeStyle(style) ??
            TextfOptions.defaultCodeStyle(style);
      case TokenType.linkStart: // Should not reach here directly
        return options?.getEffectiveUrlStyle(style) ??
            TextfOptions.defaultUrlStyle.merge(style);
      case TokenType.text:
        return style;
      default:
        return style;
    }
  }

  /// Identifies matching pairs of formatting markers.
  Map<int, int> identifyMatchingPairs() {
    final Map<int, int> pairs = {};

    // Stack of opening markers for each type
    final Map<TokenType, List<int>> openingStacks = {
      TokenType.boldMarker: [],
      TokenType.italicMarker: [],
      TokenType.boldItalicMarker: [],
      TokenType.strikeMarker: [],
      TokenType.codeMarker: [],
      // Add link-related tokens
      TokenType.linkStart: [],
      TokenType.linkSeparator: [],
      TokenType.linkEnd: [],
    };

    // First pass - pair markers based on type
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == TokenType.text) continue;

      // Skip link-related tokens as they're handled separately
      if (token.type == TokenType.linkStart ||
          token.type == TokenType.linkSeparator ||
          token.type == TokenType.linkEnd) {
        continue;
      }

      // Check if we already have an opening marker of this type
      final stack = openingStacks[token.type]!;

      if (stack.isEmpty) {
        // No opening marker yet - treat this as opening
        stack.add(i);
      } else {
        // We have an opening marker - pair it
        final openingIndex = stack.removeLast();

        // Record the pair
        pairs[openingIndex] = i;
        pairs[i] = openingIndex;
      }
    }

    // Validate nesting
    validateNesting(pairs);

    return pairs;
  }

  /// Validates proper nesting of formatting markers and removes invalid pairs.
  void validateNesting(Map<int, int> pairs) {
    // Stack of opening markers in order of appearance
    final List<int> openingStack = [];
    final Set<int> invalidPairs = {};

    // Check each token
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == TokenType.text) continue;

      final matchingIndex = pairs[i];
      if (matchingIndex == null) continue; // Skip unpaired markers

      if (matchingIndex > i) {
        // This is an opening marker
        openingStack.add(i);
      } else {
        // This is a closing marker
        if (openingStack.isNotEmpty && openingStack.last == matchingIndex) {
          // Proper nesting - remove from stack
          openingStack.removeLast();
        } else {
          // Improper nesting
          // Find and mark all intervening pairs as invalid
          int openingPos = -1;
          for (int j = 0; j < openingStack.length; j++) {
            if (openingStack[j] == matchingIndex) {
              openingPos = j;
              break;
            }
          }

          if (openingPos != -1) {
            // Mark all pairs from openingPos to end as invalid
            for (int j = openingPos; j < openingStack.length; j++) {
              final openIndex = openingStack[j];
              final closeIndex = pairs[openIndex]!;

              invalidPairs.add(openIndex);
              invalidPairs.add(closeIndex);
            }

            // Remove processed markers
            openingStack.removeRange(openingPos, openingStack.length);
          }
        }
      }
    }

    // Remove invalid pairs
    for (final index in invalidPairs) {
      pairs.remove(index);
    }
  }

  /// Normalizes a URL for consistent handling.
  String normalizeUrl(String url) {
    // Trim whitespace
    url = url.trim();

    // Handle common URL patterns
    if (!url.contains(':') &&
        !url.startsWith('/') &&
        !url.startsWith('#') &&
        !url.startsWith('mailto:')) {
      // Look for domain-like patterns
      if (url.contains('.') || url.contains('localhost')) {
        return 'http://$url';
      }
    }

    return url;
  }

  /// Checks if text contains any potential formatting characters.
  bool hasFormatting(String text) {
    for (int i = 0; i < text.length; i++) {
      final int char = text.codeUnitAt(i);
      if (char == kAsterisk ||
          char == kUnderscore ||
          char == kTilde ||
          char == kBacktick ||
          char == kEscape) {
        return true;
      }
    }
    return false;
  }
}

/// Helper class for tracking format stack entries during parsing.
///
/// Each entry represents a formatting marker that has been opened
/// but not yet closed during the parsing process.
class _FormatStackEntry {
  /// Index of the opening formatting marker in the token list.
  final int index;

  /// Index of the matching closing marker in the token list.
  final int matchingIndex;

  /// Type of the formatting marker.
  final TokenType type;

  /// Creates a new format stack entry.
  _FormatStackEntry({
    required this.index,
    required this.matchingIndex,
    required this.type,
  });
}
