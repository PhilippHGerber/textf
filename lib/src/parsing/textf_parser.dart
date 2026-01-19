import 'package:flutter/material.dart';

import '../core/formatting_utils.dart';
import '../models/parser_state.dart';
import '../models/token_type.dart';
import '../styling/textf_style_resolver.dart';
import 'components/format_handler.dart';
import 'components/link_handler.dart';
import 'components/pairing_resolver.dart';
import 'components/placeholder_handler.dart';
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
/// - Support for widget placeholders via {0} syntax.
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
  ///    - If a `TokenType.linkStart` (`[`) is encountered, delegates processing to `LinkHandler`.
  ///    - If a `TokenType.placeholder` (`{n}`) is encountered, delegates to `PlaceholderHandler`.
  ///    - If a formatting marker token is found, handles stack operations via `FormatHandler`.
  ///    - Treats any other unexpected token types encountered during the loop as plain text.
  /// 7. After iterating through all tokens, flushes any remaining text in the `ParserState`'s
  ///    buffer using the current style context via `state.flushText()`.
  /// 8. Returns the final list of generated [InlineSpan] objects from the `ParserState`.
  ///
  /// - [text]: The input string potentially containing formatting markers.
  /// - [context]: The current build context, required for theme and options lookup by the `TextfStyleResolver`.
  /// - [baseStyle]: The base text style to apply to unformatted text segments and as the foundation for styled segments.
  /// - [inlineSpans]: Optional list of spans to insert into placeholders like `{0}`.
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
    // including unpaired ones, link syntax characters, or braces.
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
      inlineSpans: inlineSpans,
    );

    // 5. Optimized Process Loop
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      // --- Placeholder Handling ---
      if (token.type == TokenType.placeholder) {
        PlaceholderHandler.processPlaceholder(context, state, token);
        i++;
        continue;
      }

      // --- Link Handling ---
      if (token.type == TokenType.linkStart) {
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
      if (token.type.isFormattingMarker) {
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
      // 1. TokenType.text
      // 2. Unpaired/Invalid Formatting Markers
      // 3. Broken/Partial Link tokens
      state.textBuffer += token.value;
      i++;
    }

    // 6. Final Flush
    state.flushText(context);

    return state.spans;
  }
}
