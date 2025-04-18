import 'package:flutter/material.dart';

import '../styling/style_resolver.dart';
import 'format_stack_entry.dart';
import 'token.dart';

/// Encapsulates the state of the parser during the text processing.
///
/// This class maintains all the necessary variables during the parsing process,
/// including the input tokens, the base text style, matching marker pairs,
/// the current formatting stack, and the style resolver. It also provides
/// methods for common state operations like flushing accumulated text
/// with the currently applied formatting.
class ParserState {
  /// The list of tokens generated by the tokenizer for the input text.
  final List<Token> tokens;

  /// The base text style provided, potentially merged with DefaultTextStyle.
  /// This style acts as the starting point before applying any formatting.
  final TextStyle baseStyle;

  /// A map where keys are indices of opening formatting markers and values
  /// are the indices of their corresponding closing markers (and vice-versa).
  /// This map only contains *valid* pairs after nesting validation.
  final Map<int, int> matchingPairs;

  /// The style resolver instance used to determine the final style for
  /// each text segment, considering options, theme, and defaults.
  final TextfStyleResolver styleResolver;

  /// The list where generated InlineSpans (TextSpan, WidgetSpan) are collected.
  final List<InlineSpan> spans = [];

  /// A buffer for accumulating plain text content between formatting markers.
  String textBuffer = '';

  /// A stack tracking the currently active (opened but not yet closed)
  /// formatting markers. Used to determine the style for the textBuffer.
  final List<FormatStackEntry> formatStack = [];

  /// A set containing the indices of tokens that have already been processed
  /// by a handler (e.g., as part of a link structure or a formatting pair).
  /// Used to prevent double processing.
  final Set<int> processedIndices = {};

  /// An optional `TextScaler` for scaling the text.
  final TextScaler? textScaler;

  /// Creates a new parser state.
  ///
  /// Requires the token list, the base text style, the map of valid
  /// matching marker pairs, and the style resolver.
  ParserState({
    required this.tokens,
    required this.baseStyle,
    required this.matchingPairs,
    required this.styleResolver,
    this.textScaler,
  });

  /// Flushes the accumulated `textBuffer` as a `TextSpan` with the current formatting applied.
  ///
  /// This method calculates the effective text style by starting with `baseStyle`
  /// and iteratively applying the styles corresponding to the markers currently
  /// on the `formatStack`, using the `styleResolver`. It then creates a `TextSpan`
  /// with the calculated style and the buffered text, adds it to the `spans` list,
  /// and clears the `textBuffer`.
  ///
  /// - [context]: The BuildContext, needed by the styleResolver. Although the resolver
  ///              already holds the context, passing it here ensures clarity or
  ///              allows for potential future flexibility if the resolver becomes context-dependent per call.
  ///              Alternatively, the resolver could just use its own stored context.
  ///              Let's keep it for now for clarity, assuming the resolver might need it per-call.
  void flushText(BuildContext context) {
    if (textBuffer.isEmpty) return; // Nothing to flush

    // Calculate the current style based on the format stack and the resolver
    TextStyle currentStyle = baseStyle;
    for (final FormatStackEntry entry in formatStack) {
      // Apply the style for the active format marker using the resolver
      currentStyle = styleResolver.resolveStyle(entry.type, currentStyle);
    }

    // Create and add the TextSpan
    spans.add(TextSpan(text: textBuffer, style: currentStyle));

    // Clear the buffer for the next segment
    textBuffer = '';
  }
}
