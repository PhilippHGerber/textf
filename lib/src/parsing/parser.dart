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
    // Early TextfOptions retrieval is a sound optimization that Reduces
    // computational overhead for formatted text
    final textfOptions = TextfOptions.maybeOf(context);

    // Tokenize the text
    final tokens = _tokenizer.tokenize(text);

    // Process tokens and generate spans
    final spans = _generateSpans(tokens, baseStyle, textfOptions);

    // Update cache
    // Uses a simple FIFO concept, as this is sufficient for this application.
    if (_cache.length >= maxCacheSize) {
      // Remove oldest entry for simple FIFO behavior
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = spans;

    return spans;
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

  /// Generates styled spans from the tokenized text.
  ///
  /// This is the core of the parsing process, which:
  /// 1. Identifies matching pairs of formatting markers
  /// 2. Processes tokens sequentially, applying formatting based on nesting
  /// 3. Handles error cases like improperly matched or nested markers
  /// 4. Creates text spans with the appropriate styling
  ///
  /// @param tokens The tokens to process
  /// @param baseStyle The base text style to apply
  /// @param options The TextfOptions to use for styling, or null if not available
  /// @return A list of styled spans
  List<InlineSpan> _generateSpans(
    List<Token> tokens,
    TextStyle baseStyle,
    TextfOptions? options,
  ) {
    final spans = <InlineSpan>[];
    String textBuffer = '';

    // Formatting stack (token indices with their types)
    final List<_FormatStackEntry> formatStack = [];

    // Keep track of matched pairs to avoid processing the same tokens twice
    final Set<int> processedIndices = {};

    // Helper function to flush text with current formatting
    void flushText() {
      if (textBuffer.isEmpty) return;

      // Calculate current style based on format stack
      var style = baseStyle;
      for (final entry in formatStack) {
        style = _applyStyle(style, entry.type, options);
      }

      spans.add(TextSpan(text: textBuffer, style: style));
      textBuffer = '';
    }

    // First identify matching pairs of formatting markers
    final Map<int, int> matchingPairs = _identifyMatchingPairs(tokens);

    // Process tokens in sequence
    for (int i = 0; i < tokens.length; i++) {
      // Skip tokens we've already processed
      if (processedIndices.contains(i)) continue;

      final token = tokens[i];

      if (token.type == TokenType.text) {
        // Regular text - add to buffer
        textBuffer += token.value;
      } else if (token.type == TokenType.linkStart) {
        // Flush any existing text
        flushText();

        // Check if we have a complete link structure
        if (i + 4 <= tokens.length &&
            tokens[i + 1].type == TokenType.text &&
            tokens[i + 2].type == TokenType.linkSeparator &&
            tokens[i + 3].type == TokenType.text &&
            tokens[i + 4].type == TokenType.linkEnd) {
          final String linkText = tokens[i + 1].value;
          final String linkUrl = tokens[i + 3].value;

          // Get link style from TextfOptions
          final TextStyle urlStyle = options?.getEffectiveUrlStyle(baseStyle) ??
              TextfOptions.defaultUrlStyle.merge(baseStyle);

          // Check if link text contains formatting markers
          if (_hasFormatting(linkText)) {
            // Process formatting within link text
            final List<Token> linkTextTokens = _tokenizer.tokenize(linkText);

            // Create a temporary list to hold the formatted link spans
            final List<InlineSpan> formattedLinkSpans = _generateSpans(
              linkTextTokens,
              urlStyle, // Use link style as the base style
              options,
            );

            // Add a UrlLinkSpan with children instead of text
            spans.add(
              UrlLinkSpan(
                url: _normalizeUrl(linkUrl),
                text: '', // Empty because we're using children
                style: urlStyle,
                children: formattedLinkSpans,
              ),
            );
          } else {
            // No formatting in link text, use simple approach
            spans.add(
              UrlLinkSpan(
                url: _normalizeUrl(linkUrl),
                text: linkText,
                style: urlStyle,
              ),
            );
          }

          // Mark all link tokens as processed
          processedIndices.add(i);
          processedIndices.add(i + 1);
          processedIndices.add(i + 2);
          processedIndices.add(i + 3);
          processedIndices.add(i + 4);

          i = i + 4;
        } else {
          // Malformed link, treat as text
          textBuffer += token.value;
        }
      } else {
        // Regular formatting marker logic
        final matchingIndex = matchingPairs[i];
        if (matchingIndex != null) {
          // This is a formatting marker with a matching pair
          if (matchingIndex > i) {
            // This is an opening marker
            // Add any accumulated text before we start this formatting
            flushText();

            // Push onto the format stack
            formatStack.add(
              _FormatStackEntry(
                index: i,
                matchingIndex: matchingIndex,
                type: token.type,
              ),
            );

            // Mark as processed
            processedIndices.add(i);
          } else {
            // This is a closing marker - its opening marker should have been processed
            // and should be on the format stack

            // Mark as processed
            processedIndices.add(i);

            // Find and remove the matching entry from the format stack
            int stackIndex = -1;
            for (int j = formatStack.length - 1; j >= 0; j--) {
              if (formatStack[j].index == matchingIndex) {
                stackIndex = j;
                break;
              }
            }

            if (stackIndex != -1) {
              // Flush the text WITH the formatting still applied
              flushText();

              // THEN remove the entry from the stack
              formatStack.removeAt(stackIndex);
            } else {
              // No matching format found, just flush normally
              flushText();
            }
          }
        } else {
          // Unpaired marker, treat as text
          textBuffer += token.value;
        }
      }
    }

    // Flush any remaining text
    flushText();

    return spans;
  }

  /// Identifies matching pairs of formatting markers within the token list.
  ///
  /// This method:
  /// 1. Tracks opening markers of each type
  /// 2. Pairs them with corresponding closing markers
  /// 3. Validates proper nesting of formatting tags
  ///
  /// @param tokens The tokens to process
  /// @return A map associating opening marker indices with their closing counterparts
  Map<int, int> _identifyMatchingPairs(List<Token> tokens) {
    final Map<int, int> matchingPairs = {};

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

      // Skip link-related tokens as they're handled separately in _generateSpans
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
        matchingPairs[openingIndex] = i;
        matchingPairs[i] = openingIndex;
      }
    }

    // Validate nesting
    _validateNesting(tokens, matchingPairs);

    return matchingPairs;
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

  /// Validates proper nesting of formatting markers and removes invalid pairs.
  ///
  /// Proper nesting means that markers should be closed in the reverse order they
  /// were opened (e.g., *__text__* is valid, but *__text*__ is not).
  ///
  /// This method:
  /// 1. Tracks opening markers in sequence
  /// 2. Ensures closing markers match the expected order
  /// 3. Identifies and removes invalid pairs
  ///
  /// @param tokens The tokens to validate
  /// @param matchingPairs The identified marker pairs
  void _validateNesting(List<Token> tokens, Map<int, int> matchingPairs) {
    // Stack of opening markers in order of appearance
    final List<int> openingStack = [];
    final Set<int> invalidPairs = {};

    // Check each token
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == TokenType.text) continue;

      final matchingIndex = matchingPairs[i];
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
          // TODO - add a warning: Improperly nested formatting tags at position token.position

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
              final closeIndex = matchingPairs[openIndex]!;

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
      matchingPairs.remove(index);
    }
  }

  void debugPairingProcess(
      String text, BuildContext context, TextStyle baseStyle) {
    final tokens = _tokenizer.tokenize(text);
    final matchingPairs = _identifyMatchingPairs(tokens);

    print('Input: "$text"');
    print('Matching Pairs:');
    matchingPairs.forEach((openIndex, closeIndex) {
      final openToken = tokens[openIndex];
      final closeToken = tokens[closeIndex];
      print(
          '- ${openToken.type} at ${openToken.position} matches ${closeToken.type} at ${closeToken.position}');
    });
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

/// Applies the appropriate style modifications for a formatting marker.
///
/// This function takes a base style, a marker type, and TextfOptions,
/// and returns a new style with the appropriate modifications applied.
///
/// @param baseStyle The base text style to modify
/// @param markerType The type of formatting to apply
/// @param options The TextfOptions to use, or null if not available
/// @return A new TextStyle with the formatting applied
TextStyle _applyStyle(
  TextStyle baseStyle,
  TokenType markerType,
  TextfOptions? options,
) {
  switch (markerType) {
    case TokenType.boldMarker:
      return options?.getEffectiveBoldStyle(baseStyle) ??
          TextfOptions.defaultBoldStyle(baseStyle);
    case TokenType.italicMarker:
      return options?.getEffectiveItalicStyle(baseStyle) ??
          TextfOptions.defaultItalicStyle(baseStyle);
    case TokenType.boldItalicMarker:
      return options?.getEffectiveBoldItalicStyle(baseStyle) ??
          TextfOptions.defaultBoldItalicStyle(baseStyle);
    case TokenType.strikeMarker:
      return options?.getEffectiveStrikethroughStyle(baseStyle) ??
          TextfOptions.defaultStrikethroughStyle(baseStyle);
    case TokenType.codeMarker:
      return options?.getEffectiveCodeStyle(baseStyle) ??
          TextfOptions.defaultCodeStyle(baseStyle);
    case TokenType.linkStart: // Should not reach here directly
      return options?.getEffectiveUrlStyle(baseStyle) ??
          TextfOptions.defaultUrlStyle.merge(baseStyle);
    case TokenType.text:
      return baseStyle;
    default:
      return baseStyle;
  }
}
