import 'package:flutter/material.dart';

import '../../models/format_stack_entry.dart';
import '../../models/parser_state.dart';
import '../../models/textf_token.dart';

/// Handles the processing of formatting tokens (bold, italic, etc.) during parsing.
///
/// This class is responsible for managing the `formatStack` within the `ParserState`
/// based on opening and closing formatting markers identified by the `PairingResolver`.
/// It ensures that `state.flushText()` is called before format changes occur,
/// allowing the `ParserState` (using the `TextfStyleResolver`) to apply the correct
/// style to the text segments.
class FormatHandler {
  /// Processes a formatting token (bold, italic, strike, code) and updates the parser state.
  ///
  /// This method handles both opening and closing formatting markers:
  /// - For opening markers: It flushes any preceding text, adds the marker to the format stack,
  ///   and marks the token as processed.
  /// - For closing markers: It flushes the text *within* the format, removes the corresponding
  ///   marker from the stack, and marks the token as processed.
  /// - Unpaired markers are treated as plain text (handled by the caller loop in TextfParser).
  ///
  /// - [context]: The BuildContext, needed by `state.flushText`.
  /// - [state]: The current parser state holding the tokens, stack, buffer, etc.
  /// - [index]: The index of the token being processed in `state.tokens`.
  /// - [token]: The formatting token to process.
  static void processFormat(
    BuildContext context,
    ParserState state,
    int index,
    FormatMarkerToken token,
  ) {
    // Find the index of the matching counterpart.
    final int? matchingIndex = state.matchingPairs[index];

    if (matchingIndex != null) {
      // This is a valid formatting marker with a matching pair.
      if (matchingIndex > index) {
        // OPENING marker
        _handleOpeningMarker(context, state, index, token, matchingIndex);
      } else {
        // CLOSING marker
        _handleClosingMarker(context, state, matchingIndex);
      }
    }
    // Unpaired markers are handled by the main loop (falling through to plain text).
  }

  /// Handles an opening formatting marker.
  ///
  /// Flushes any preceding text, pushes the new format onto the stack,
  /// and marks the token as processed.
  static void _handleOpeningMarker(
    BuildContext context,
    ParserState state,
    int index,
    FormatMarkerToken token,
    int matchingIndex,
  ) {
    // Flush preceding text with previous style
    state.flushText(context);

    // Compute resolved style: apply this format on top of the current stack style.
    final TextStyle previousStyle = state.formatStack.isEmpty
        ? state.baseStyle
        : (state.formatStack.last.resolvedStyle ?? state.baseStyle);
    final TextStyle resolved = state.styleResolver.resolveStyle(token.markerType, previousStyle);

    // Push new format to stack with pre-computed style
    state.formatStack.add(
      FormatStackEntry(
        index: index,
        matchingIndex: matchingIndex,
        type: token.markerType,
        resolvedStyle: resolved,
      ),
    );
  }

  /// Handles a closing formatting marker.
  ///
  /// Flushes the text segment that was *inside* the format being closed,
  /// removes the corresponding format entry from the stack, and marks
  /// the token as processed.
  static void _handleClosingMarker(
    BuildContext context,
    ParserState state,
    int matchingIndex,
  ) {
    // Flush text inside the format
    state.flushText(context);

    // Remove the corresponding opening entry from stack.
    // NestingValidator guarantees proper nesting, so the closing marker must
    // always match the stack top (LIFO order is preserved).
    assert(
      state.formatStack.isNotEmpty && state.formatStack.last.index == matchingIndex,
      'Closing marker does not match stack top — nesting validation failed',
    );
    if (state.formatStack.isNotEmpty) {
      state.formatStack.removeLast();
    }
  }
}
