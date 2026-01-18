import 'package:flutter/material.dart';

import '../core/formatting_utils.dart';
import '../models/parser_state.dart';
import '../models/token_type.dart';
import '../styling/textf_style_resolver.dart';
import 'components/format_handler.dart';
import 'components/link_handler.dart';
import 'components/pairing_resolver.dart';
import 'textf_tokenizer.dart';

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
  /// Creates a new [TextfParser] instance.
  ///
  /// - [tokenizer]: An optional custom tokenizer instance. If not provided,
  ///   a default [TextfTokenizer] is created.
  TextfParser({
    TextfTokenizer? tokenizer,
  }) : _tokenizer = tokenizer ?? TextfTokenizer();

  /// TextfTokenizer instance used to break down text into tokens.
  final TextfTokenizer _tokenizer;

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
    List<InlineSpan>? inlineSpans,
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

    // 1. Tokenize
    final tokens = _tokenizer.tokenize(text);

    // 2. Style Resolver
    final resolver = TextfStyleResolver(context);

    // 3. Pairing
    final validPairs = PairingResolver.identifyPairs(tokens);

    // 4. State
    final state = ParserState(
      tokens: tokens,
      baseStyle: baseStyle,
      matchingPairs: validPairs,
      styleResolver: resolver,
      textScaler: textScaler,
    );

    // 5. Optimized Process Loop
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // --- Placeholder Handling ---
      if (token.type == TokenType.placeholder) {
        final String raw = token.value;
        // Expected format {N}
        if (raw.length > 2) {
          final String numberStr = raw.substring(1, raw.length - 1);
          final int? index = int.tryParse(numberStr);
          if (index != null && inlineSpans != null && index >= 0 && index < inlineSpans.length) {
            // Valid placeholder
            state.flushText(context);

            // Get current style to ensure inheritance
            final currentStyle = state.getCurrentStyle(context);

            // We wrap the injected span in a TextSpan with the current style.
            // This ensures that if the injected span is a TextSpan, it inherits
            // the markdown styles (e.g. bold/italic) unless it overrides them.
            // Even WidgetSpans are valid children of TextSpan.
            state.spans.add(
              TextSpan(
                style: currentStyle,
                children: [inlineSpans[index]],
              ),
            );
            continue;
          }
        }
        // Fallthrough to plain text if invalid
      }

      // --- Link Handling ---
      if (token.type == TokenType.linkStart) {
        // Attempt to process a link.
        final int? nextIndex = LinkHandler.processLink(context, state, i);
        if (nextIndex != null) {
          // Success: The LinkHandler consumed tokens up to `nextIndex`.
          // We must advance the loop counter `i`.
          // Since the loop performs `i++` at the end, we set i to `nextIndex - 1`.
          i = nextIndex - 1;
          continue;
        }
        // Failure: Not a valid link. Fall through to process as plain text.
      }

      // --- Formatting Handling ---
      if (token.type.isFormattingMarker) {
        if (state.matchingPairs.containsKey(i)) {
          // This token is part of a valid format pair.
          FormatHandler.processFormat(context, state, i, token);
          // Handled as a marker (either pushed to or popped from stack).
          // Do NOT add to text buffer.
          continue;
        }
        // Unpaired or invalidly nested marker. Fall through to process as plain text.
      }

      // --- Plain Text Handling ---
      // Accumulate content into the buffer. This applies to:
      // 1. TokenType.text
      // 2. Unpaired/Invalid Formatting Markers
      // 3. Broken/Partial Link tokens
      state.textBuffer += token.value;
    }

    // 6. Final Flush
    state.flushText(context);

    return state.spans;
  }
}
