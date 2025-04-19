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
/// - Style resolution aware of TextfOptions and application Theme.
/// - Fast paths for empty or plain unformatted text.
/// - Handles nested formatting.
/// - Handles malformed formatting by treating unpaired markers as plain text.
/// - Escaped character support (handled by the tokenizer).
/// - Support for [link text](url) with nested formatting inside links.
class TextfParser {
  /// TextfTokenizer instance used to break down text into tokens.
  final TextfTokenizer _tokenizer;

  /// Creates a new [TextfParser] instance.
  ///
  /// - [tokenizer]: An optional custom tokenizer instance. If not provided,
  ///   a default [TextfTokenizer] is created.
  TextfParser({
    TextfTokenizer? tokenizer,
  }) : _tokenizer = tokenizer ?? TextfTokenizer();

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
  ///    - Appends plain text tokens (`TokenType.text`) to the `ParserState`'s text buffer.
  ///    - If a `TokenType.linkStart` (`[`) is encountered, delegates processing to `LinkHandler`
  ///      to attempt parsing a complete `[link text](url)` structure. The handler manages
  ///      nested formatting within the link text and marks processed tokens.
  ///    - If a formatting marker token (`*`, `_`, `**`, `__`, `***`, `___`, `~`, `` ` ``) is found:
  ///        - Checks if this specific token instance is part of a *valid pair* identified in step 4.
  ///        - If **paired**, delegates processing to `FormatHandler`. This handler manages the
  ///          style stack (pushing/popping styles), flushes the text buffer with the previous style,
  ///          and marks both the opening and closing marker tokens as processed.
  ///        - If **unpaired**, treats the marker's literal value (e.g., "*") as plain text and
  ///          appends it to the `ParserState`'s text buffer. Marks the unpaired marker token as processed.
  ///    - Treats any other unexpected token types encountered during the loop as plain text.
  /// 7. After iterating through all tokens, flushes any remaining text in the `ParserState`'s
  ///    buffer using the current style context via `state.flushText()`.
  /// 8. Returns the final list of generated [InlineSpan] objects from the `ParserState`.
  ///
  /// - [text]: The input string potentially containing formatting markers.
  /// - [context]: The current build context, required for theme and options lookup by the `TextfStyleResolver`.
  /// - [baseStyle]: The base text style to apply to unformatted text segments and as the foundation for styled segments.
  ///
  /// Returns a list of [InlineSpan] objects representing the styled text.
  List<InlineSpan> parse(
    String text,
    BuildContext context,
    TextStyle baseStyle, {
    TextScaler? textScaler,
  }) {
    // Fast path for empty text
    if (text.isEmpty) {
      return <InlineSpan>[];
    }

    // Fast path for plain text without formatting markers
    // Note: FormattingUtils.hasFormatting checks for *any* potential marker,
    // including unpaired ones or link syntax characters.
    if (!FormattingUtils.hasFormatting(text)) {
      // No potential formatting, return simple TextSpan list
      return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
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
      textScaler: textScaler,
    );

    // 5. Process tokens sequentially
    for (int i = 0; i < tokens.length; i++) {
      // Skip tokens already processed by handlers (e.g., inside a link or a valid format pair)
      if (state.processedIndices.contains(i)) continue;

      final token = tokens[i];

      // --- Token Processing Logic ---
      if (token.type == TokenType.text) {
        // It's plain text, just append to the buffer
        state.textBuffer += token.value;
        // No need to mark plain text as processed unless state management requires it
      } else if (token.type == TokenType.linkStart) {
        // Potential link start '['. Delegate to LinkHandler.
        final int? nextIndex = LinkHandler.processLink(context, state, i);
        if (nextIndex != null) {
          // LinkHandler processed a full link `[...](...)`.
          // It marked all involved tokens as processed.
          // Advance loop counter past the processed link.
          i = nextIndex - 1; // nextIndex is the index *after* ')', loop needs index of ')'
        } else {
          // LinkHandler determined it wasn't a valid link starting at 'i'.
          // It added '[' to the buffer and marked index 'i' as processed.
          // Loop continues normally.
        }
      }
      // Is it a formatting marker (bold, italic, code, strike, etc.)?
      else if (token.type.isFormattingMarker) {
        // Check if this specific marker instance is part of a *valid* pair.
        if (state.matchingPairs.containsKey(i)) {
          // Yes, it's part of a valid pair (either opening or closing).
          // Delegate to FormatHandler to manage the stack and buffer.
          // FormatHandler will mark both this token and its pair as processed.
          FormatHandler.processFormat(context, state, i, token);
        } else {
          // No, this marker instance is *not* part of a valid pair (e.g., "**abc" or "*abc").
          // Treat its literal value as plain text.
          state.textBuffer += token.value;
          // Mark this specific token as processed so it doesn't get reconsidered.
          state.processedIndices.add(i);
        }
      }
      // Handle other token types (like linkSeparator, linkUrl, linkEnd) that might
      // be encountered if not part of a structure successfully processed by LinkHandler.
      // Treat them as plain text.
      else {
        // Fallback: Treat any other unexpected token type as plain text.
        state.textBuffer += token.value;
        state.processedIndices.add(i); // Mark as processed
      }
      // --- End Token Processing Logic ---
    }

    // 6. Flush any remaining text in the buffer after the loop finishes
    state.flushText(context);

    return state.spans;
  }

  /// Debugging utility to view the tokenization and pairing process.
  ///
  /// Prints the input text, the list of tokens generated by the tokenizer,
  /// and the map of valid, matching pairs identified by the `PairingResolver`.
  /// This helps in understanding how the parser interprets the input string.
  void debugPairingProcess(String text, BuildContext context, TextStyle baseStyle) {
    final tokens = _tokenizer.tokenize(text);
    // Get the *validated* pairs, consistent with the main parse logic.
    final validPairs = PairingResolver.identifyPairs(tokens);

    debugPrint('--- TextfParser Debug ---');
    debugPrint('Input: "$text"');
    debugPrint('Tokens (${tokens.length}):');
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      // Indicate if the token is part of a valid pair
      final pairTarget = validPairs[i];
      final pairIndicator = pairTarget != null ? " (Paired -> $pairTarget)" : " (Unpaired)";
      debugPrint('  $i: ${token.type} (${token.position}, ${token.length}) $pairIndicator - "${token.value}"');
    }
    debugPrint('Valid Matching Pairs (${validPairs.length ~/ 2}):');
    final processedPairs = <int>{}; // Avoid printing pairs twice (once for open, once for close)
    validPairs.forEach((openIndex, closeIndex) {
      // Ensure we only print each pair once, starting from the opening marker
      if (!processedPairs.contains(openIndex) && !processedPairs.contains(closeIndex)) {
        if (openIndex < closeIndex) {
          // Basic check to assume lower index is opener
          final openToken = tokens[openIndex];
          final closeToken = tokens[closeIndex];
          debugPrint('  - ${openToken.type} ($openIndex:"${openToken.value}") <-> ($closeIndex:"${closeToken.value}")');
          processedPairs.add(openIndex);
          processedPairs.add(closeIndex);
        }
      }
    });
    debugPrint('------------------------');
  }
}
